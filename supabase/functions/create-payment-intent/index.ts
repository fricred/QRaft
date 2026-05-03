// Supabase Edge Function: create-payment-intent
//
// Receives an authenticated request from the Flutter app, creates an order
// via the create_order Postgres RPC, computes the Wompi integrity signature
// server-side (T-09-06), and returns a ready-to-open Wompi Web Checkout URL.
//
// Required Supabase secrets (Dashboard → Settings → Edge Functions → Secrets):
//   WOMPI_PRIVATE_KEY         — prv_prod_...
//   WOMPI_INTEGRITY_SECRET    — prod_integrity_...
//   WOMPI_PUBLIC_KEY          — pub_prod_... (read here so we can switch envs
//                               without rebuilding the Flutter binary)
//
// JWT verification: ENABLED (default). Flutter must pass the Supabase JWT in
// the Authorization header via functions.invoke (automatic with supabase_flutter).
//
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ---------------------------------------------------------------------------
// CORS headers — required for Flutter web calls
// ---------------------------------------------------------------------------

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function corsJson(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ShippingInput {
  recipient_name: string;
  phone: string;
  department: string;
  city: string;
  address: string;
  notes?: string | null;
}

interface RequestBody {
  cart_item_ids: string[];
  shipping: ShippingInput;
  idempotency_key: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Decode a JWT payload without verifying the signature (verification is
 *  already performed by the Supabase gateway before this function runs). */
function decodeJwtSub(authHeader: string): string | null {
  const token = authHeader.replace(/^Bearer\s+/i, "");
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const payload = JSON.parse(atob(parts[1]));
    return payload.sub as string ?? null;
  } catch {
    return null;
  }
}

/** Compute HMAC-free integrity signature per Wompi Web Checkout spec:
 *  SHA-256( reference + amountInCents + currency + WOMPI_INTEGRITY_SECRET )
 */
async function computeIntegritySignature(
  reference: string,
  amountInCents: number,
  currency: string,
  integritySecret: string,
): Promise<string> {
  const raw = `${reference}${amountInCents}${currency}${integritySecret}`;
  const encoded = new TextEncoder().encode(raw);
  const hashBuffer = await crypto.subtle.digest("SHA-256", encoded);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** Build Wompi Web Checkout URL from components. */
function buildWompiCheckoutUrl(params: {
  publicKey: string;
  amountInCents: number;
  reference: string;
  integritySignature: string;
  redirectUrl: string;
}): string {
  const base = "https://checkout.wompi.co/p/";
  const qs = new URLSearchParams({
    "public-key": params.publicKey,
    currency: "COP",
    "amount-in-cents": String(params.amountInCents),
    reference: params.reference,
    integrity: params.integritySignature,
    "redirect-url": params.redirectUrl,
  });
  return `${base}?${qs.toString()}`;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return corsJson({ error: "Method not allowed" }, 405);
  }

  // ---- 1. Extract user_id from verified JWT --------------------------------
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return corsJson({ error: "Missing Authorization header" }, 401);
  }

  const userId = decodeJwtSub(authHeader);
  if (!userId) {
    return corsJson({ error: "Invalid JWT: cannot extract sub" }, 401);
  }

  // ---- 2. Parse request body -----------------------------------------------
  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return corsJson({ error: "Invalid JSON body" }, 400);
  }

  const { cart_item_ids, shipping, idempotency_key } = body;

  if (
    !Array.isArray(cart_item_ids) || cart_item_ids.length === 0 ||
    !shipping || typeof shipping !== "object" ||
    !idempotency_key || typeof idempotency_key !== "string"
  ) {
    return corsJson(
      { error: "Missing or invalid fields: cart_item_ids, shipping, idempotency_key" },
      400,
    );
  }

  // ---- 3. Build service-role Supabase client (bypasses RLS for RPC) --------
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  // ---- 4. Call create_order RPC -------------------------------------------
  let orderId: string;

  const { data: rpcData, error: rpcError } = await supabaseAdmin.rpc(
    "create_order",
    {
      p_user_id: userId,
      p_cart_item_ids: cart_item_ids,
      p_shipping: shipping,
      p_idempotency_key: idempotency_key,
    },
  );

  if (rpcError) {
    // 23505 = unique_violation: idempotency key already used → fetch existing order
    if (rpcError.code === "23505" || rpcError.message?.includes("unique") || rpcError.message?.includes("idempotency")) {
      // Retrieve the existing order by idempotency key (stored as transaction_ref in payments)
      const { data: existingPayment, error: fetchError } = await supabaseAdmin
        .from("payments")
        .select("order_id")
        .eq("transaction_ref", idempotency_key)
        .maybeSingle();

      if (fetchError || !existingPayment) {
        return corsJson({ error: "Idempotency retry failed: cannot locate existing order" }, 500);
      }
      orderId = existingPayment.order_id as string;
    } else {
      return corsJson({ error: `create_order RPC failed: ${rpcError.message}` }, 500);
    }
  } else {
    orderId = rpcData as string;
  }

  if (!orderId) {
    return corsJson({ error: "create_order returned null order_id" }, 500);
  }

  // ---- 5. Fetch order total from orders table (server-authoritative) ------
  const { data: orderRow, error: orderFetchError } = await supabaseAdmin
    .from("orders")
    .select("total_cop")
    .eq("id", orderId)
    .single();

  if (orderFetchError || !orderRow) {
    return corsJson({ error: `Cannot fetch order total: ${orderFetchError?.message}` }, 500);
  }

  const totalCop = orderRow.total_cop as number;
  const amountInCents = totalCop * 100; // COP pesos → centavos

  // ---- 6. Read Wompi secrets -----------------------------------------------
  const integritySecret = Deno.env.get("WOMPI_INTEGRITY_SECRET");
  const publicKey = Deno.env.get("WOMPI_PUBLIC_KEY");

  if (!integritySecret || !publicKey) {
    return corsJson({ error: "Wompi secrets not configured in Edge Function environment" }, 500);
  }

  // ---- 7. Compute integrity signature (T-09-06: never in Flutter binary) --
  const reference = idempotency_key; // our canonical transaction_ref
  const integritySignature = await computeIntegritySignature(
    reference,
    amountInCents,
    "COP",
    integritySecret,
  );

  // ---- 8. Build Wompi Web Checkout URL ------------------------------------
  const redirectUrl = "qraft://payment-result";
  const wompiCheckoutUrl = buildWompiCheckoutUrl({
    publicKey,
    amountInCents,
    reference,
    integritySignature,
    redirectUrl,
  });

  // ---- 9. Return checkout session (NO secrets in response) ----------------
  return corsJson(
    {
      order_id: orderId,
      transaction_ref: reference,
      integrity_signature: integritySignature, // safe: digest output, not secret
      wompi_checkout_url: wompiCheckoutUrl,
      amount_cop: totalCop,
    },
    200,
  );
});
