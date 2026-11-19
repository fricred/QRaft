// Supabase Edge Function: dynamic-qr — every write on a user's dynamic QR codes.
// The app calls it with its session JWT (verify_jwt on); the user is always taken from the
// JWT, never from the body. Writes run with the service role through the dynamic_qr_* SQL
// functions (clients have no write access to redirects).
//
// POST { action, ... }:
//   reserve   { name, customization, content_type, payload, display } → { redirect_id, qr_code_id, slug }
//   begin     { redirect_id }                    right before opening the store sheet
//   claim     { redirect_id, transaction_id? }   after a store purchase → { status }
//   reconcile {}                                 "Restaurar compras"     → { activated, refunded, credits }
//   use_credit{ redirect_id }                    pay a pending code with an unused purchase
//   content   { redirect_id, content_type, payload, display }
//   undo      { redirect_id, history_id }
//   pause     { redirect_id, paused }
//   revoke    { redirect_id }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { isUnsafeUrl, reconcileDynamicQr, validateContent } from "../_shared/dynamic_qr.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
}

const admin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { persistSession: false } },
);

// SQL errors raised on purpose by the dynamic_qr_* functions → stable client error codes.
function dbError(e: { message?: string; code?: string }): Response {
  const m = e.message ?? "";
  for (const known of ["redirect_not_editable", "redirect_not_pausable", "purchase_belongs_to_other_user", "slug_exhausted", "too_many_pending"]) {
    if (m.includes(known)) return json(409, { error: known });
  }
  console.error("db error", e.code, m);
  return json(500, { error: "server_error" });
}

async function checkContent(type: string, payload: unknown): Promise<Response | null> {
  const v = validateContent(type, payload);
  if (!v.ok) return json(422, { error: v.error });
  if (type === "url" && await isUnsafeUrl(String(payload).trim())) return json(422, { error: "unsafe_url" });
  return null;
}

function display(v: unknown): string | null {
  return typeof v === "string" ? v.slice(0, 200) : null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "unauthorized" });
  const { data: auth, error: authError } = await admin.auth.getUser(token);
  if (authError || !auth?.user) return json(401, { error: "unauthorized" });
  const user = auth.user.id;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }
  const action = String(body.action ?? "");
  const redirectId = typeof body.redirect_id === "string" && UUID.test(body.redirect_id) ? body.redirect_id : null;
  const needsRedirect = ["begin", "claim", "use_credit", "content", "undo", "pause", "revoke"].includes(action);
  if (needsRedirect && !redirectId) return json(400, { error: "invalid_redirect_id" });

  switch (action) {
    case "reserve": {
      const type = String(body.content_type ?? "");
      const bad = await checkContent(type, body.payload);
      if (bad) return bad;
      const name = typeof body.name === "string" && body.name.trim() ? body.name.trim().slice(0, 120) : null;
      const customization = body.customization && typeof body.customization === "object" ? body.customization : {};
      const { data, error } = await admin.rpc("dynamic_qr_reserve", {
        p_user: user, p_name: name, p_customization: customization, p_content_type: type,
        p_content: { payload: String(body.payload).trim() }, p_display: display(body.display),
      });
      if (error) return dbError(error);
      return json(200, data);
    }

    case "begin": {
      // Right before the store sheet opens: this is the code the next purchase pays for.
      const { error } = await admin.rpc("dynamic_qr_begin_checkout", { p_user: user, p_redirect: redirectId });
      if (error) return dbError(error);
      return json(200, { ok: true });
    }

    case "claim":
    case "reconcile": {
      const txn = typeof body.transaction_id === "string" && body.transaction_id ? body.transaction_id : null;
      const r = await reconcileDynamicQr(admin, user, { redirectId, transactionId: txn });
      if (!r.ok) return json(r.reason === "not_configured" ? 503 : 502, { error: r.reason });
      if (action === "reconcile") return json(200, r);
      const { data } = await admin.from("redirects").select("status").eq("id", redirectId!).eq("owner_id", user).maybeSingle();
      // Not active yet = the store hasn't reported the purchase (pending payment): the webhook
      // activates it when the money arrives.
      return json(200, { status: data?.status ?? "not_found", credits: r.credits });
    }

    case "use_credit": {
      const { data, error } = await admin.rpc("dynamic_qr_use_credit", { p_user: user, p_redirect: redirectId });
      if (error) return dbError(error);
      return json(200, data);
    }

    case "content": {
      const type = String(body.content_type ?? "");
      const bad = await checkContent(type, body.payload);
      if (bad) return bad;
      const { data, error } = await admin.rpc("dynamic_qr_set_content", {
        p_user: user, p_redirect: redirectId, p_content_type: type,
        p_content: { payload: String(body.payload).trim() }, p_display: display(body.display),
      });
      if (error) return dbError(error);
      return json(200, data);
    }

    case "undo": {
      const historyId = typeof body.history_id === "string" && UUID.test(body.history_id) ? body.history_id : null;
      if (!historyId) return json(400, { error: "invalid_history_id" });
      const { data: h } = await admin
        .from("redirect_history")
        .select("content_type, content, redirects!inner(owner_id)")
        .eq("id", historyId)
        .eq("redirect_id", redirectId!)
        .eq("redirects.owner_id", user)
        .maybeSingle();
      if (!h) return json(404, { error: "history_not_found" });
      const payload = (h.content as { payload?: string } | null)?.payload;
      const bad = await checkContent(h.content_type, payload);
      if (bad) return bad;
      const { data, error } = await admin.rpc("dynamic_qr_set_content", {
        p_user: user, p_redirect: redirectId, p_content_type: h.content_type,
        p_content: { payload }, p_display: display(body.display),
      });
      if (error) return dbError(error);
      return json(200, data);
    }

    case "pause": {
      const { data, error } = await admin.rpc("dynamic_qr_set_paused", {
        p_user: user, p_redirect: redirectId, p_paused: body.paused === true,
      });
      if (error) return dbError(error);
      return json(200, { status: data });
    }

    case "revoke": {
      const { error } = await admin.rpc("dynamic_qr_revoke", { p_user: user, p_redirect: redirectId });
      if (error) return dbError(error);
      return json(200, { status: "revoked" });
    }

    default:
      return json(400, { error: "unknown_action" });
  }
});
