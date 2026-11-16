// Server-side source of truth for a user's plan: asks RevenueCat's REST API v2 for the
// customer's active entitlements / subscriptions and writes the plan columns with the
// service role. Clients can't write these columns (protect_subscription_columns trigger).
//
// Needs secrets:
//   REVENUECAT_SECRET_API_KEY  — v2 secret key ("sk_..."), read-only on customer information
//                                 and project configuration is enough.
//   REVENUECAT_PROJECT_ID      — e.g. "proj62637ad5" (RevenueCat → Project settings).
// Without them, callers must fall back / report "not configured".

// deno-lint-ignore-file no-explicit-any
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const ENTITLEMENT_LOOKUP_KEY = "pro";
const API = "https://api.revenuecat.com/v2";

/** Store id of the one-time "dynamic QR" consumable. It never grants Pro. */
export const DYNAMIC_QR_STORE_ID = "qraft_dynamic_qr";

/** True for any store identifier of the dynamic QR consumable (Play may suffix base plans). */
export function isDynamicQrStoreId(storeId: string | null | undefined): boolean {
  return !!storeId && (storeId === DYNAMIC_QR_STORE_ID || storeId.startsWith(`${DYNAMIC_QR_STORE_ID}:`));
}

export function revenueCatKey(): string | null {
  const key = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  return key && key.trim().length > 0 ? key.trim() : null;
}

export function revenueCatProject(): string | null {
  const id = Deno.env.get("REVENUECAT_PROJECT_ID");
  return id && id.trim().length > 0 ? id.trim() : null;
}

/** True when server-side sync can run (key + project id present). */
export function revenueCatConfigured(): boolean {
  return revenueCatKey() !== null && revenueCatProject() !== null;
}

function periodFromProduct(storeId: string | null): string | null {
  if (!storeId) return null;
  if (storeId.includes("monthly")) return "monthly";
  if (storeId.includes("annual") || storeId.includes("yearly")) return "annual";
  if (storeId.includes("lifetime")) return "lifetime";
  return null;
}

export type SyncResult =
  | { ok: true; plan: string; status: string; rows: number }
  | { ok: false; reason: string };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export class RcError extends Error {}

export async function rc(key: string, path: string): Promise<any | null> {
  const res = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new RcError(`revenuecat_${res.status}`);
  return await res.json();
}

/** All items of a v2 list endpoint (follows next_page). */
export async function rcList(key: string, path: string): Promise<any[]> {
  const items: any[] = [];
  let next: string | null = path.includes("?") ? `${path}&limit=100` : `${path}?limit=100`;
  for (let page = 0; next && page < 20; page++) {
    const body = await rc(key, next);
    if (!body) break;
    items.push(...(body.items ?? []));
    // next_page is an absolute URL (https://api.revenuecat.com/v2/...); keep only the path.
    next = body.next_page ? String(body.next_page).replace(/^(https:\/\/api\.revenuecat\.com)?\/v2/, "") : null;
  }
  return items;
}

// The entitlement id ("entl...") for the lookup key; stable, so cached per isolate.
let entitlementIdCache: string | null = null;
async function proEntitlementId(key: string, project: string): Promise<string> {
  if (entitlementIdCache) return entitlementIdCache;
  const items = await rcList(key, `/projects/${project}/entitlements`);
  const ent = items.find((e) => e.lookup_key === ENTITLEMENT_LOOKUP_KEY);
  if (!ent) throw new RcError("entitlement_not_found");
  entitlementIdCache = ent.id;
  return ent.id;
}

// RevenueCat product id ("prod...") → store identifier, cached per isolate.
const storeIdCache = new Map<string, string | null>();
export async function storeIdentifier(key: string, project: string, productId: string | null) {
  if (!productId) return null;
  if (storeIdCache.has(productId)) return storeIdCache.get(productId) ?? null;
  const p = await rc(key, `/projects/${project}/products/${encodeURIComponent(productId)}`);
  const id = (p?.store_identifier as string | undefined) ?? null;
  storeIdCache.set(productId, id);
  return id;
}

/** Keeps only items whose product is not the dynamic QR consumable. */
async function withoutDynamicQr(key: string, project: string, items: any[]): Promise<any[]> {
  const kept: any[] = [];
  for (const it of items) {
    if (!isDynamicQrStoreId(await storeIdentifier(key, project, it.product_id ?? null))) kept.push(it);
  }
  return kept;
}

/** Re-reads [appUserId] from RevenueCat and writes its plan to public.users (id = appUserId). */
export async function syncUserFromRevenueCat(
  supabase: SupabaseClient,
  appUserId: string,
): Promise<SyncResult> {
  const key = revenueCatKey();
  const project = revenueCatProject();
  if (!key || !project) return { ok: false, reason: "not_configured" };
  // Not one of our users (e.g. a dashboard test event): nothing to update, not a failure.
  if (!UUID.test(appUserId)) return { ok: true, plan: "skipped", status: "not_a_user", rows: 0 };

  let update: Record<string, unknown>;
  let plan = "free";
  let status = "active";
  try {
    const entId = await proEntitlementId(key, project);
    const base = `/projects/${project}/customers/${encodeURIComponent(appUserId)}`;
    const customer = await rc(key, base);
    // 404: RevenueCat doesn't know this id (never opened the paywall, or the purchase lives
    // under another / legacy id). That is not proof the user isn't paying, so never
    // downgrade on it: leave the row untouched.
    if (!customer) return { ok: true, plan: "unchanged", status: "no_customer", rows: 0 };

    const activeEnt = (customer.active_entitlements?.items ?? [])
      .find((e: any) => e?.entitlement_id === entId);
    const subs = await rcList(key, `${base}/subscriptions`);
    const purchases = await rcList(key, `${base}/purchases`);

    // Every product except the dynamic QR consumable unlocks "pro", and v2 only lists a
    // subscription's entitlements while it is active, so all of them count as Pro history.
    // Access itself is decided by active_entitlements (RevenueCat already applies grace).
    // Dynamic QR purchases are one-time credits for a single code: never Pro history.
    const proSubs = await withoutDynamicQr(key, project, subs);
    const proPurchases = await withoutDynamicQr(key, project, purchases);
    // The subscription currently giving access (latest period end wins).
    const liveSub = proSubs
      .filter((s) => s.gives_access)
      .sort((a, b) => (b.current_period_ends_at ?? 0) - (a.current_period_ends_at ?? 0))[0];
    const livePurchase = proPurchases.find((p) => p.status === "owned");

    const now = Date.now();
    const expiresMs: number | null = activeEnt?.expires_at ?? null;
    const entitled = !!activeEnt && (expiresMs === null || expiresMs > now);

    let productId: string | null = null;
    if (entitled) {
      plan = "pro";
      if (liveSub) {
        productId = liveSub.product_id ?? null;
        if (
          liveSub.status === "in_grace_period" ||
          liveSub.status === "in_billing_retry" ||
          liveSub.pending_payment === true
        ) status = "billing_issue";
        else if (liveSub.auto_renewal_status === "will_not_renew") status = "cancelled";
      } else if (livePurchase) {
        productId = livePurchase.product_id ?? null;
      }
    } else if (proSubs.length > 0 || proPurchases.length > 0) {
      status = "expired";
    }

    const storeId = entitled ? await storeIdentifier(key, project, productId) : null;
    const startTimes = [
      ...proSubs.map((s) => s.starts_at),
      ...proPurchases.map((p) => p.purchased_at),
    ].filter((t) => typeof t === "number") as number[];

    update = {
      subscription_plan: plan,
      subscription_status: status,
      subscription_expires_at: entitled && expiresMs !== null ? new Date(expiresMs).toISOString() : null,
      subscription_product_id: storeId,
      subscription_period_type: entitled
        ? (livePurchase && !liveSub ? "lifetime" : periodFromProduct(storeId))
        : null,
      original_purchase_date: startTimes.length ? new Date(Math.min(...startTimes)).toISOString() : null,
      revenuecat_customer_id: liveSub?.original_customer_id ?? appUserId,
      last_verified_at: new Date().toISOString(),
    };
  } catch (err) {
    // Never touch the row when RevenueCat couldn't be read: a transient error must not downgrade.
    return { ok: false, reason: err instanceof RcError ? err.message : "revenuecat_error" };
  }

  const { data, error } = await supabase
    .from("users")
    .update(update)
    .eq("id", appUserId)
    .select("id");
  if (error) return { ok: false, reason: `db_${error.code ?? "error"}` };
  return { ok: true, plan, status, rows: data?.length ?? 0 };
}
