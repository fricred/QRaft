// Called by the app after a purchase / restore: re-reads the CALLER's plan from RevenueCat
// and stores it (service role). The user id comes from the verified JWT, never the body,
// so nobody can sync (or upgrade) another account.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { syncUserFromRevenueCat } from "../_shared/revenuecat_sync.ts";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

// RevenueCat's API rate limit is per project and shared with the webhook: a client calling
// this in a loop must not be able to exhaust it. Re-reading more often than this is useless.
const MIN_INTERVAL_MS = 20_000;

serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const service = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: userData, error: userError } = await service.auth.getUser(jwt);
    if (userError || !userData?.user) return json({ error: "unauthorized" }, 401);
    const userId = userData.user.id;

    // Atomic claim: only one call per user per interval gets through to RevenueCat.
    const cutoff = new Date(Date.now() - MIN_INTERVAL_MS).toISOString();
    // (Two single-filter updates: PostgREST rejects an or= filter on PATCH with 42703.)
    const claim = (q: (b: any) => any) =>
      q(service.from("users").update({ last_verified_at: new Date().toISOString() }).eq("id", userId))
        .select("id");
    let { data: claimed, error: claimError } = await claim((b) => b.is("last_verified_at", null));
    if (!claimError && (!claimed || claimed.length === 0)) {
      ({ data: claimed, error: claimError } = await claim((b) => b.lt("last_verified_at", cutoff)));
    }
    if (claimError) {
      console.error("sync-subscription claim failed:", claimError);
      return json({ error: "internal" }, 500);
    }
    if (!claimed || claimed.length === 0) return json({ ok: true, throttled: true });

    const result = await syncUserFromRevenueCat(service, userId);
    if (!result.ok) {
      console.error("sync-subscription failed:", result.reason);
      return json({ error: result.reason }, result.reason === "not_configured" ? 503 : 502);
    }
    return json(result);
  } catch (err) {
    console.error("sync-subscription error:", err);
    return json({ error: "internal" }, 500);
  }
});
