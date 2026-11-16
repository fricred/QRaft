// Dynamic QR codes: content validation and purchase reconciliation against RevenueCat.
// Used by the `dynamic-qr` function (app calls) and `revenuecat-webhook` (store events).

// deno-lint-ignore-file no-explicit-any
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  geoToMapsUrl,
  parseEmail,
  parseEvent,
  parseVCard,
  parseWifi,
  safeHttpUrl,
} from "../redirect/render.ts";
import {
  isDynamicQrStoreId,
  rcList,
  revenueCatKey,
  revenueCatProject,
  storeIdentifier,
} from "./revenuecat_sync.ts";

export const CONTENT_TYPES = ["url", "text", "vcard", "vevent", "geo", "wifi", "email"] as const;
export type ContentType = typeof CONTENT_TYPES[number];

const MAX_PAYLOAD = 4000;

// Link shorteners hide the real destination of a printed code; our own domain would loop.
const BLOCKED_HOSTS = new Set([
  "bit.ly", "bitly.com", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "is.gd", "buff.ly", "cutt.ly",
  "rebrand.ly", "shorturl.at", "tiny.cc", "rb.gy", "s.id", "t.ly", "v.gd", "shorte.st", "adf.ly",
  "scanqraft.app",
]);

export type Validation = { ok: true } | { ok: false; error: string };

/** Structural checks per type (no network). */
export function validateContent(type: string, payload: unknown): Validation {
  if (!(CONTENT_TYPES as readonly string[]).includes(type)) return { ok: false, error: "invalid_type" };
  if (typeof payload !== "string" || !payload.trim()) return { ok: false, error: "empty_content" };
  if (payload.length > MAX_PAYLOAD) return { ok: false, error: "content_too_long" };
  switch (type as ContentType) {
    case "url": {
      const url = safeHttpUrl(payload);
      if (!url) return { ok: false, error: "invalid_url" };
      const host = new URL(url).hostname.toLowerCase().replace(/^www\./, "");
      if (BLOCKED_HOSTS.has(host)) return { ok: false, error: "shortener_not_allowed" };
      return { ok: true };
    }
    case "text": return { ok: true };
    case "vcard": {
      const c = parseVCard(payload);
      return /BEGIN:VCARD/i.test(payload) && (c.name || c.phones.length || c.emails.length)
        ? { ok: true } : { ok: false, error: "invalid_vcard" };
    }
    case "vevent": {
      const e = parseEvent(payload);
      return /BEGIN:VEVENT/i.test(payload) && e.title && e.start ? { ok: true } : { ok: false, error: "invalid_event" };
    }
    case "geo": return geoToMapsUrl(payload) ? { ok: true } : { ok: false, error: "invalid_location" };
    case "wifi": return parseWifi(payload).ssid ? { ok: true } : { ok: false, error: "invalid_wifi" };
    case "email": return parseEmail(payload) ? { ok: true } : { ok: false, error: "invalid_email" };
  }
}

/**
 * Google Web Risk lookup for a URL. Without WEB_RISK_API_KEY (or on an API error) the URL is
 * allowed and logged: a lookup outage must not stop owners from editing their codes.
 */
export async function isUnsafeUrl(url: string): Promise<boolean> {
  const key = Deno.env.get("WEB_RISK_API_KEY")?.trim();
  if (!key) {
    console.warn("WEB_RISK_API_KEY not set: URL not checked", new URL(url).hostname);
    return false;
  }
  const q = new URLSearchParams({ uri: url, key });
  for (const t of ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE"]) q.append("threatTypes", t);
  try {
    const res = await fetch(`https://webrisk.googleapis.com/v1/uris:search?${q}`);
    if (!res.ok) {
      console.error("web risk lookup failed", res.status);
      return false;
    }
    const body = await res.json();
    return !!body?.threat;
  } catch (e) {
    console.error("web risk lookup error", e);
    return false;
  }
}

export type ReconcileResult =
  | { ok: true; activated: string[]; refunded: string[]; credits: number }
  | { ok: false; reason: string };

/**
 * Re-reads the user's dynamic QR purchases from RevenueCat and applies them:
 * owned → linked to a pending code (preferRedirect first), refunded → code revoked.
 * Idempotent (store_transaction_id is unique), so app claims and webhooks can race safely.
 */
export async function reconcileDynamicQr(
  supabase: SupabaseClient,
  userId: string,
  prefer?: { redirectId?: string | null; transactionId?: string | null },
): Promise<ReconcileResult> {
  const key = revenueCatKey();
  const project = revenueCatProject();
  if (!key || !project) return { ok: false, reason: "not_configured" };

  let purchases: any[];
  try {
    purchases = await rcList(key, `/projects/${project}/customers/${encodeURIComponent(userId)}/purchases`);
  } catch (e) {
    return { ok: false, reason: e instanceof Error ? e.message : "revenuecat_error" };
  }

  const dynamic: { txn: string; storeId: string; purchasedAt: string | null; refunded: boolean }[] = [];
  const skipped: string[] = [];
  for (const p of purchases) {
    const storeId = await storeIdentifier(key, project, p.product_id ?? null);
    if (!isDynamicQrStoreId(storeId)) continue;
    const txn = String(p.store_purchase_identifier ?? p.id ?? "");
    if (!txn) continue;
    // Only "owned" pays for a code; "refunded" revokes it; anything else (unknown or new
    // states) is left alone instead of being treated as paid.
    if (p.status !== "owned" && p.status !== "refunded") {
      skipped.push(`${txn}:${p.status}`);
      continue;
    }
    dynamic.push({
      txn,
      storeId: storeId!,
      purchasedAt: typeof p.purchased_at === "number" ? new Date(p.purchased_at).toISOString() : null,
      refunded: p.status === "refunded",
    });
  }

  // The purchase the app just made goes to the code it was bought for; when the app
  // didn't get a transaction id (pending purchase), the oldest unlinked one does.
  if (skipped.length) console.warn("dynamic QR purchases skipped (status):", skipped.join(", "));
  // An app transaction id RevenueCat doesn't list (yet / other format) must not stop the
  // code it was bought for from being preferred.
  const preferTxn = prefer?.transactionId && dynamic.some((d) => d.txn === prefer.transactionId)
    ? prefer.transactionId
    : null;
  dynamic.sort((a, b) => {
    if (preferTxn) return (b.txn === preferTxn ? 1 : 0) - (a.txn === preferTxn ? 1 : 0);
    return (a.purchasedAt ?? "").localeCompare(b.purchasedAt ?? "");
  });

  const activated: string[] = [];
  const refunded: string[] = [];
  let credits = 0;
  let preferUsed = false;
  for (const d of dynamic) {
    if (d.refunded) {
      const { data, error } = await supabase.rpc("dynamic_qr_refund", { p_txn: d.txn });
      if (error) return { ok: false, reason: `db_${error.code ?? "error"}` };
      if (data?.redirect_id) refunded.push(data.redirect_id);
      continue;
    }
    const target = !preferUsed && prefer?.redirectId && (!preferTxn || d.txn === preferTxn) ? prefer.redirectId : null;
    const { data, error } = await supabase.rpc("dynamic_qr_apply_purchase", {
      p_user: userId, p_txn: d.txn, p_product: d.storeId, p_purchased_at: d.purchasedAt, p_redirect: target,
    });
    if (error) {
      if (error.message?.includes("purchase_belongs_to_other_user")) continue;
      return { ok: false, reason: `db_${error.code ?? "error"}` };
    }
    // Only once the preferred code really got linked (an already-linked purchase returns
    // its own code and must not consume the preference).
    if (target && data?.redirect_id === target) preferUsed = true;
    if (data?.state === "active" && data.redirect_id) activated.push(data.redirect_id);
    if (data?.state === "credit") credits++;
  }
  return { ok: true, activated, refunded, credits };
}
