// Supabase Edge Function: wompi-webhook
//
// Receives payment events from Wompi, verifies the HMAC-SHA256 signature,
// persists to payment_events (idempotent via PRIMARY KEY), and transitions
// the order FSM via the apply_payment_event RPC.
//
// Deployed with --no-verify-jwt because Wompi does NOT send a Supabase JWT.
// This function performs its own authentication via SHA256 checksum.
//
// ---------------------------------------------------------------------------
// Required Supabase secret (set in Supabase Dashboard → Settings → Secrets):
//   WOMPI_EVENTS_SECRET = ***REMOVED_SECRET***
//
// Deploy:
//   supabase functions deploy wompi-webhook --no-verify-jwt
// ---------------------------------------------------------------------------

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Resolves a dot-separated path like "data.transaction.id" against a JSON
 * object, returning the value as a string (or empty string if not found).
 */
function resolvePath(obj: unknown, path: string): string {
  const value = path.split('.').reduce((acc: unknown, key: string) => {
    if (acc !== null && acc !== undefined && typeof acc === 'object') {
      return (acc as Record<string, unknown>)[key];
    }
    return undefined;
  }, obj);

  if (value === null || value === undefined) return '';
  return String(value);
}

/**
 * Computes SHA-256 hex digest of a UTF-8 string using the Deno built-in
 * crypto.subtle (no external import needed).
 */
async function sha256hex(input: string): Promise<string> {
  const encoded = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoded);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request) => {
  // Only accept POST.
  if (req.method !== 'POST') {
    return new Response('method not allowed', { status: 405 });
  }

  // Parse JSON body.
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response('invalid json', { status: 400 });
  }

  // ── Step 1: Verify checksum ──────────────────────────────────────────────
  // NEVER process an event without verifying the signature first.
  // T-09-15: Prevents forged APPROVED events from triggering order fulfillment.

  // WOMPI_ENV=test|prod selects the correct events secret automatically.
  const wompiEnv = (Deno.env.get('WOMPI_ENV') ?? 'test').toLowerCase();
  const eventsSecret = Deno.env.get(
    wompiEnv === 'prod' ? 'WOMPI_EVENTS_SECRET_PROD' : 'WOMPI_EVENTS_SECRET_TEST'
  );
  if (!eventsSecret) {
    console.error(`WOMPI_EVENTS_SECRET_${wompiEnv.toUpperCase()} not set`);
    return new Response('server misconfigured', { status: 500 });
  }

  const signature = body.signature as
    | { properties: string[]; checksum: string }
    | undefined;
  const timestamp = body.timestamp as number | undefined;

  // Wompi may put the checksum in the X-Event-Checksum header OR in
  // signature.checksum — check both (header takes priority per Wompi spec).
  const receivedChecksum =
    req.headers.get('X-Event-Checksum') ?? signature?.checksum ?? '';

  if (!signature?.properties || !timestamp || !receivedChecksum) {
    console.warn('Missing signature fields; rejecting event');
    return new Response('missing signature', { status: 401 });
  }

  // Wompi checksum algorithm (docs.wompi.co/en/docs/colombia/eventos/):
  //   1. For each path in signature.properties (in order), resolve from body
  //   2. Concatenate all resolved values (no separator)
  //   3. Append timestamp as string
  //   4. Append WOMPI_EVENTS_SECRET
  //   5. SHA256 hex of the resulting string
  const propertyValues = signature.properties
    .map((p) => resolvePath(body, p))
    .join('');
  const toHash = `${propertyValues}${timestamp}${eventsSecret}`;
  const expectedChecksum = await sha256hex(toHash);

  if (expectedChecksum !== receivedChecksum) {
    // Possible forged event — log (without secret) and reject.
    console.warn(
      `Checksum mismatch for event id=${body.id ?? 'unknown'}; ` +
        'possible forged event; returning 401'
    );
    return new Response('invalid checksum', { status: 401 });
  }

  // ── Step 2: Idempotency via payment_events.event_id PK ──────────────────
  // T-09-16 / T-09-18: Duplicate or replayed events are silently accepted (200)
  // without re-running the FSM.

  const eventId = body.id as string | undefined;
  if (!eventId) {
    return new Response('missing event id', { status: 400 });
  }

  // Use service_role key so the function can write to payment_events and call
  // SECURITY DEFINER RPCs.  The key is NEVER included in any response body.
  // T-09-17: T-09-19 compliance.
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const transaction = (body.data as Record<string, unknown>)
    ?.transaction as Record<string, unknown> | undefined;

  const transactionRef = transaction?.reference as string | undefined;
  const wompiStatus = transaction?.status as string | undefined;
  const wompiTxId = transaction?.id as string | undefined;
  const paymentMethod = transaction?.payment_method_type as string | undefined;

  // Look up the payments row to resolve the FK for payment_events.payment_id.
  // If no row is found (e.g., unknown reference), payment_id will be null;
  // the event is still recorded for reconciliation.
  const { data: paymentRow } = await supabase
    .from('payments')
    .select('id')
    .eq('transaction_ref', transactionRef ?? '')
    .maybeSingle();

  // Attempt idempotent insert.  On PRIMARY KEY collision (code 23505) the
  // event was already processed — return 200 without any FSM call.
  const { error: insertError } = await supabase
    .from('payment_events')
    .insert({
      event_id: eventId,
      payment_id: paymentRow?.id ?? null,
      kind: body.event as string,
      payload: body,
    });

  if (insertError) {
    if (insertError.code === '23505') {
      // Duplicate delivery — idempotent success.
      console.log(
        `Event ${eventId} already processed (PK collision); returning 200`
      );
      return new Response('already_processed', { status: 200 });
    }
    // Unexpected DB error — log and return 500.
    // NEVER include raw error details (could expose schema) in the response.
    console.error('payment_events insert error:', insertError.code);
    return new Response('db error', { status: 500 });
  }

  // ── Step 3: Apply FSM transition via RPC ─────────────────────────────────
  // Only transaction.updated events with a known status drive order transitions.
  // All other events (e.g., nip.updated) are recorded but cause no FSM change.

  const eventKind = body.event as string | undefined;
  const isTransactionEvent = eventKind === 'transaction.updated';

  if (isTransactionEvent && transactionRef && wompiStatus) {
    const { error: rpcError } = await supabase.rpc('apply_payment_event', {
      p_transaction_ref: transactionRef,
      p_wompi_status: wompiStatus,           // APPROVED | DECLINED | VOIDED | ERROR
      p_wompi_transaction_id: wompiTxId ?? null,
      p_payment_method: paymentMethod ?? null,
      p_raw_payload: body,
    });

    if (rpcError) {
      // Log the error but return 200 to prevent Wompi retry storms.
      // The event is already idempotently recorded in payment_events for
      // manual reconciliation.  A second Wompi retry would hit the PK check
      // and immediately return 200 without re-running RPC.
      console.error(
        'apply_payment_event RPC error:',
        rpcError.code,
        rpcError.message
      );
    } else {
      console.log(
        `Order FSM transitioned for ref=${transactionRef} ` +
          `wompiStatus=${wompiStatus}`
      );
    }
  } else if (!isTransactionEvent) {
    // Non-transaction event (e.g., nip.updated) — recorded, no FSM change.
    console.log(`Non-transaction event ${eventKind} recorded; no FSM change`);
  }

  return new Response('ok', { status: 200 });
});
