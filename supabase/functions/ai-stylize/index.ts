// Supabase Edge Function: ai-stylize
// Secure proxy between the Flutter app and the Replicate QR ControlNet API.
// Never exposes REPLICATE_API_KEY to the client.
//
// ---------------------------------------------------------------------------
// Required Supabase secret (set in Supabase Dashboard → Settings → Secrets):
//   REPLICATE_API_KEY = <your Replicate token>
//
// Required SQL (apply manually in Supabase Dashboard → SQL Editor):
// ---------------------------------------------------------------------------
// CREATE TABLE IF NOT EXISTS ai_style_usage (
//   user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
//   month   text    NOT NULL,  -- "YYYY-MM"
//   count   integer NOT NULL DEFAULT 0,
//   PRIMARY KEY (user_id, month)
// );
// ALTER TABLE ai_style_usage ENABLE ROW LEVEL SECURITY;
// CREATE POLICY "users see own usage" ON ai_style_usage
//   FOR SELECT USING (auth.uid() = user_id);
// ---------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const FREE_MONTHLY_LIMIT = 5;
const PROMPT_MAX_CHARS = 200;
const PROMPT_ALLOWED = /[^\w\s.,!?-]/g; // strip injection characters (T-06-02)
const REPLICATE_MODEL_URL =
  "https://api.replicate.com/v1/models/zylim0702/qr_code_controlnet/predictions";
const REPLICATE_PREDICTION_BASE =
  "https://api.replicate.com/v1/predictions";

// ---------------------------------------------------------------------------
// CORS headers — required for Flutter web calls
// ---------------------------------------------------------------------------

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function corsResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return corsResponse({ error: "Method not allowed" }, 405);
  }

  // ---------------------------------------------------------------------------
  // Validate Supabase JWT — the Authorization header must carry "Bearer <jwt>".
  // Supabase Edge Runtime auto-validates the JWT when the anon/service key is
  // used by the Flutter supabase_flutter client. We extract the user_id from
  // the JWT claims for the usage counter (T-06-04).
  // ---------------------------------------------------------------------------
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return corsResponse({ error: "Unauthorized" }, 401);
  }
  const jwt = authHeader.slice(7);

  // Decode JWT payload (base64url) to extract sub (user_id).
  // We trust the Supabase runtime has already verified the signature.
  let userId: string;
  try {
    const payloadB64 = jwt.split(".")[1];
    const padded = payloadB64 + "=".repeat((4 - (payloadB64.length % 4)) % 4);
    const payloadJson = atob(padded.replace(/-/g, "+").replace(/_/g, "/"));
    const payload = JSON.parse(payloadJson);
    userId = payload.sub as string;
    if (!userId) throw new Error("missing sub");
  } catch {
    return corsResponse({ error: "Invalid token" }, 401);
  }

  // ---------------------------------------------------------------------------
  // Parse and validate request body
  // ---------------------------------------------------------------------------
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return corsResponse({ error: "Invalid JSON body" }, 400);
  }

  // ---------------------------------------------------------------------------
  // Replicate client — read API key from env (T-06-01: never from request)
  // ---------------------------------------------------------------------------
  const replicateApiKey = Deno.env.get("REPLICATE_API_KEY");
  if (!replicateApiKey) {
    console.error("REPLICATE_API_KEY not configured");
    return corsResponse({ error: "Service configuration error" }, 500);
  }

  // ---------------------------------------------------------------------------
  // Supabase client (service role) for usage counter
  // ---------------------------------------------------------------------------
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseServiceKey) {
    console.error("Missing Supabase env vars");
    return corsResponse({ error: "Service configuration error" }, 500);
  }
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // ---------------------------------------------------------------------------
  // Route: status poll — { "prediction_id": string }
  // ---------------------------------------------------------------------------
  if (typeof body.prediction_id === "string") {
    const predictionId = body.prediction_id as string;
    if (!/^[a-z0-9]{8,32}$/.test(predictionId)) {
      return corsResponse({ error: "Invalid prediction_id format" }, 400);
    }

    const pollResp = await fetch(
      `${REPLICATE_PREDICTION_BASE}/${predictionId}`,
      {
        headers: { Authorization: `Token ${replicateApiKey}` },
      },
    );

    const prediction = await pollResp.json();
    const status: string = prediction.status ?? "unknown";
    const httpStatus = status === "succeeded"
      ? 200
      : status === "failed"
      ? 500
      : 202;

    return corsResponse(prediction, httpStatus);
  }

  // ---------------------------------------------------------------------------
  // Route: new stylize request — { "qr_url": string, "prompt": string }
  // ---------------------------------------------------------------------------
  const qrUrl = typeof body.qr_url === "string" ? body.qr_url.trim() : "";
  const rawPrompt = typeof body.prompt === "string" ? body.prompt : "";

  if (!qrUrl) {
    return corsResponse({ error: "qr_url is required" }, 400);
  }

  // Validate qr_url is a URL
  try {
    new URL(qrUrl);
  } catch {
    return corsResponse({ error: "qr_url must be a valid URL" }, 400);
  }

  // Sanitize prompt — strip injection characters, cap length (T-06-02)
  const sanitizedPrompt = rawPrompt
    .replace(PROMPT_ALLOWED, "")
    .slice(0, PROMPT_MAX_CHARS)
    .trim();

  if (!sanitizedPrompt) {
    return corsResponse({ error: "prompt is required and must contain valid characters" }, 400);
  }

  // ---------------------------------------------------------------------------
  // Monthly usage gate — 5 free calls per user per month (T-06-03)
  // ---------------------------------------------------------------------------
  const month = new Date().toISOString().slice(0, 7); // "YYYY-MM"

  const { data: usageRow } = await supabase
    .from("ai_style_usage")
    .select("count")
    .eq("user_id", userId)
    .eq("month", month)
    .maybeSingle();

  const currentCount: number = (usageRow as { count: number } | null)?.count ?? 0;

  if (currentCount >= FREE_MONTHLY_LIMIT) {
    return corsResponse({ error: "monthly_limit_reached" }, 429);
  }

  // ---------------------------------------------------------------------------
  // Forward request to Replicate (T-06-01: API key stays server-side)
  // ---------------------------------------------------------------------------
  const replicateResp = await fetch(REPLICATE_MODEL_URL, {
    method: "POST",
    headers: {
      Authorization: `Token ${replicateApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      input: {
        qr_code_content: qrUrl,
        prompt: sanitizedPrompt,
        controlnet_conditioning_scale: 1.3,
      },
    }),
  });

  const prediction = await replicateResp.json();

  if (!replicateResp.ok) {
    console.error("Replicate API error:", prediction);
    return corsResponse({ error: "Upstream API error", detail: prediction }, 502);
  }

  // ---------------------------------------------------------------------------
  // Increment usage counter (upsert)
  // ---------------------------------------------------------------------------
  await supabase
    .from("ai_style_usage")
    .upsert(
      { user_id: userId, month, count: currentCount + 1 },
      { onConflict: "user_id,month" },
    );

  // Return prediction object (status: "starting" | "processing" | "succeeded")
  // Flutter polls by sending { "prediction_id": prediction.id }
  const status: string = prediction.status ?? "unknown";
  const httpStatus = status === "succeeded" ? 200 : 202;
  return corsResponse(prediction, httpStatus);
});
