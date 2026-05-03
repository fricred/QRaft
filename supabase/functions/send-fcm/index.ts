// supabase/functions/send-fcm/index.ts
//
// Triggered by a Supabase DB Webhook on INSERT into public.notifications.
// Reads the notification row, fetches all FCM tokens for the user,
// and sends a push notification via FCM HTTP v1 API.
//
// Required secret (Supabase Dashboard → Settings → Secrets):
//   FCM_SERVICE_ACCOUNT_JSON
//     Value: JSON content of the Firebase service account private key file.
//     Obtain: Firebase Console → Project settings → Service accounts
//             → Generate new private key → download the JSON → paste the full content.
//
// Required manual setup (one-time, per deployment):
//   1. Set FCM_SERVICE_ACCOUNT_JSON secret (above).
//   2. Enable Cloud Messaging API (V1):
//      Firebase Console → Project settings → Cloud Messaging → Cloud Messaging API (V1) → Enable.
//   3. Deploy: supabase functions deploy send-fcm
//   4. Configure DB Webhook in Supabase Dashboard → Database → Webhooks:
//      Name:   notify_send_fcm
//      Table:  public.notifications
//      Events: INSERT
//      Type:   HTTP Request
//      URL:    https://<project-ref>.supabase.co/functions/v1/send-fcm
//      Headers: { "Authorization": "Bearer <service_role_key>" }
//      (service_role_key: Supabase Dashboard → Settings → API → service_role)
//
// Security notes:
//   - FCM_SERVICE_ACCOUNT_JSON is a Supabase secret — NEVER committed to git.
//   - The function returns 200 on partial failure to avoid DB webhook retries
//     creating duplicate notifications (fcm_state per row tracks actual outcome).
//   - Unregistered FCM tokens are automatically deleted (T-10-16 cleanup).
//   - title/body text is built server-side in transition_order / apply_payment_event
//     using parameterized CASE; no user-supplied text in notification payload (T-10-13).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FCM_ENDPOINT =
  'https://fcm.googleapis.com/v1/projects/qraft-e8a1d/messages:send';
const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

// ---------------------------------------------------------------------------
// JWT / OAuth2 helpers for FCM HTTP v1 service account authentication
// ---------------------------------------------------------------------------

function base64UrlEncode(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/**
 * Exchanges a Google service account JSON for an OAuth2 access token
 * scoped to firebase.messaging. Uses crypto.subtle (available in Deno) — no
 * external package required.
 *
 * T-10-14: Private key and access token are never logged. Error logs use
 * generic messages only.
 */
async function getAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: TOKEN_ENDPOINT,
    iat: now,
    exp: now + 3600,
  };

  const enc = new TextEncoder();
  const headerB64 = base64UrlEncode(enc.encode(JSON.stringify(header)));
  const claimB64 = base64UrlEncode(enc.encode(JSON.stringify(claim)));
  const signingInput = `${headerB64}.${claimB64}`;

  // Parse the PEM private key.
  const pemContents = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    enc.encode(signingInput),
  );
  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  // Exchange the signed JWT for a Google OAuth2 access token.
  const tokenRes = await fetch(TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    // T-10-14: do not log tokenData (may contain error details with key hints).
    throw new Error('OAuth2 token exchange failed');
  }
  return tokenData.access_token as string;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('method not allowed', { status: 405 });
  }

  // T-10-12: Validate Authorization header contains the service_role Bearer token.
  // Supabase DB Webhook is configured with this header — unauth callers are rejected.
  const auth = req.headers.get('Authorization') ?? '';
  const expectedKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!auth.startsWith('Bearer ') || !expectedKey || auth !== `Bearer ${expectedKey}`) {
    console.error('send-fcm: unauthorized request (missing or invalid Authorization header)');
    return new Response('unauthorized', { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response('invalid json', { status: 400 });
  }

  // Supabase DB Webhook payload: { type: 'INSERT', table: 'notifications', record: <row>, ... }
  const record = body.record as Record<string, unknown> | undefined;
  if (!record) {
    console.error('send-fcm: webhook body missing record field');
    return new Response('missing record', { status: 400 });
  }

  const notificationId = record.id as string;
  const userId = record.user_id as string;
  const titleEs = record.title_es as string;
  const bodyEs = record.body_es as string;
  const data = (record.data as Record<string, string>) ?? {};
  const currentRetries = (record.fcm_retries as number) ?? 0;

  if (!notificationId || !userId || !titleEs || !bodyEs) {
    console.error('send-fcm: incomplete notification record fields');
    return new Response('incomplete record', { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // Fetch all FCM tokens for this user.
  const { data: tokens, error: tokenErr } = await supabase
    .from('user_fcm_tokens')
    .select('token')
    .eq('user_id', userId);

  if (tokenErr) {
    console.error('send-fcm: error fetching FCM tokens:', tokenErr.message);
    await supabase
      .from('notifications')
      .update({ fcm_state: 'failed', fcm_retries: currentRetries + 1 })
      .eq('id', notificationId);
    return new Response('token_fetch_error', { status: 500 });
  }

  if (!tokens || tokens.length === 0) {
    console.log(`send-fcm: no FCM tokens for user ${userId}; marking sent (no-op)`);
    // No tokens = user has no registered devices; not an error.
    await supabase
      .from('notifications')
      .update({ fcm_state: 'sent', sent_at: new Date().toISOString() })
      .eq('id', notificationId);
    return new Response('no_tokens', { status: 200 });
  }

  // Get OAuth2 access token from service account.
  const saJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  if (!saJson) {
    console.error('send-fcm: FCM_SERVICE_ACCOUNT_JSON secret not configured');
    return new Response('server misconfigured', { status: 500 });
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(saJson);
  } catch (e) {
    // T-10-14: log generic error message only; never log the service account JSON or access token.
    console.error('send-fcm: failed to obtain FCM access token:', (e as Error).message);
    await supabase
      .from('notifications')
      .update({ fcm_state: 'failed', fcm_retries: currentRetries + 1 })
      .eq('id', notificationId);
    return new Response('fcm_auth_failed', { status: 500 });
  }

  // Send to each registered token.
  let sentCount = 0;
  let failCount = 0;

  for (const { token } of tokens) {
    const payload = {
      message: {
        token,
        notification: { title: titleEs, body: bodyEs },
        data, // contains order_id, order_number for deep-link in app
        android: {
          notification: {
            channel_id: 'qraft_orders',
            priority: 'HIGH',
          },
        },
        apns: {
          payload: {
            aps: { alert: { title: titleEs, body: bodyEs }, sound: 'default' },
          },
        },
      },
    };

    const fcmRes = await fetch(FCM_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(payload),
    });

    if (fcmRes.ok) {
      sentCount++;
    } else {
      const errBody = await fcmRes.text();
      // Log last 8 chars of token for debugging without exposing full token.
      console.error(`send-fcm: FCM send failed for token ...${token.slice(-8)}: ${fcmRes.status}`);

      // Auto-delete unregistered tokens to prevent accumulation (T-10-16 cleanup).
      if (fcmRes.status === 404 || errBody.includes('UNREGISTERED')) {
        await supabase.from('user_fcm_tokens').delete().eq('token', token);
        console.log('send-fcm: deleted unregistered token');
      }
      failCount++;
    }
  }

  // Update notification state.
  // If any tokens were sent successfully, mark as 'sent'.
  // Only mark 'failed' if ALL sends failed.
  const finalState = sentCount > 0 ? 'sent' : 'failed';
  await supabase
    .from('notifications')
    .update({
      fcm_state: finalState,
      fcm_retries: failCount,
      sent_at: new Date().toISOString(),
    })
    .eq('id', notificationId);

  console.log(
    `send-fcm: notification ${notificationId} → sent=${sentCount} failed=${failCount} state=${finalState}`,
  );

  // Always return 200 to prevent DB webhook from retrying and creating duplicate sends.
  // Per-notification state is tracked in notifications.fcm_state.
  return new Response('ok', { status: 200 });
});
