// RevenueCat Webhook Handler for Supabase Edge Functions
// Handles subscription lifecycle events from RevenueCat

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { timingSafeEqual } from "https://deno.land/std@0.168.0/crypto/timing_safe_equal.ts";
import { isDynamicQrStoreId, revenueCatConfigured, syncUserFromRevenueCat } from "../_shared/revenuecat_sync.ts";
import { reconcileDynamicQr } from "../_shared/dynamic_qr.ts";

// CORS headers - restricted for webhook security
// RevenueCat webhooks are server-to-server, but we keep minimal CORS for health checks
const corsHeaders = {
  "Access-Control-Allow-Origin": "https://api.revenuecat.com",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

// Timing-safe string comparison to prevent timing attacks
function secureCompare(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);

  // If lengths differ, we still need constant-time comparison
  // Pad shorter string to match length (still returns false)
  if (aBytes.length !== bBytes.length) {
    return false;
  }

  return timingSafeEqual(aBytes, bBytes);
}

interface RevenueCatEvent {
  api_version: string;
  event: {
    type: string;
    id: string;
    app_user_id: string;
    original_app_user_id: string;
    product_id: string;
    period_type: string;
    purchased_at_ms: number;
    expiration_at_ms: number;
    environment: string;
    entitlement_ids: string[];
    store: string;
    is_trial_conversion?: boolean;
    cancel_reason?: string;
    transferred_from?: string[];
    transferred_to?: string[];
  };
}

// Map RevenueCat event types to subscription status
// Returns null for events that must not change the plan (unknown / informational ones):
// writing "free" for them would downgrade a paying user.
function mapEventToStatus(eventType: string): { plan: string; status: string } | null {
  switch (eventType) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
    case "NON_RENEWING_PURCHASE":
      return { plan: "pro", status: "active" };

    case "CANCELLATION":
      // User cancelled but still has access until expiration
      return { plan: "pro", status: "cancelled" };

    case "EXPIRATION":
      return { plan: "free", status: "expired" };

    case "BILLING_ISSUE":
      return { plan: "pro", status: "billing_issue" };

    case "PRODUCT_CHANGE":
      return { plan: "pro", status: "active" };

    default:
      console.log(`Event type not mapped, plan left unchanged: ${eventType}`);
      return null;
  }
}

// Map product ID to period type
function mapPeriodType(productId: string): string | null {
  if (productId.includes("monthly")) return "monthly";
  if (productId.includes("annual") || productId.includes("yearly")) return "annual";
  if (productId.includes("lifetime")) return "lifetime";
  return null;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Verify webhook authorization (REQUIRED for security)
    // RevenueCat sends the auth value in the Authorization header
    const authToken = req.headers.get("authorization");
    const expectedToken = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

    // Security: Require webhook secret to be configured
    if (!expectedToken) {
      console.error("REVENUECAT_WEBHOOK_SECRET not configured - rejecting request");
      return new Response(
        JSON.stringify({ error: "Webhook not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Security: Verify the auth token matches (timing-safe comparison)
    if (!authToken || !secureCompare(authToken, expectedToken)) {
      console.error("Invalid webhook authorization token");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Security: Limit request body size to prevent DoS
    const contentLength = req.headers.get("content-length");
    if (contentLength && parseInt(contentLength) > 10000) { // 10KB limit
      console.error("Request body too large:", contentLength);
      return new Response(
        JSON.stringify({ error: "Payload too large" }),
        { status: 413, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse webhook payload
    const payload: RevenueCatEvent = await req.json();
    const event = payload.event;

    console.log(`Processing RevenueCat event: ${event.type} for user: ${event.app_user_id}`);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Dynamic QR consumable: a one-time credit for one code, never a Pro plan change.
    // Any event for it (purchase confirmed late, refund, transfer) = re-read the user's
    // purchases from RevenueCat and apply them; idempotent with the app's own claim.
    if (isDynamicQrStoreId(event.product_id)) {
      const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      const users = [event.app_user_id, ...(event.transferred_to ?? [])].filter((id) => !!id && UUID_RE.test(id));
      const results: Record<string, unknown> = {};
      let failed = false;
      for (const id of new Set(users)) {
        const r = await reconcileDynamicQr(supabase, id);
        results[id] = r;
        if (!r.ok) failed = true;
      }
      console.log("Dynamic QR reconcile:", JSON.stringify(results));
      return new Response(
        JSON.stringify({ success: !failed, event_type: event.type, dynamic_qr: true }),
        { status: failed ? 500 : 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Preferred path: ask RevenueCat for the real current state of every affected user
    // (handles TRANSFER, refunds, extensions… without mapping each event type).
    if (revenueCatConfigured()) {
      const ids = new Set<string>([
        event.app_user_id,
        ...(event.transferred_to ?? []),
        ...(event.transferred_from ?? []),
        // An event filed under an anonymous id still lists the user's uuid among its aliases.
        ...(((event as unknown as { aliases?: string[] }).aliases) ?? []),
      ].filter((id) => !!id && !id.startsWith("$RCAnonymousID")));
      const results: Record<string, unknown> = {};
      let transient = false;
      let unusable = false;
      for (const id of ids) {
        const r = await syncUserFromRevenueCat(supabase, id);
        results[id] = r;
        if (!r.ok) {
          // Bad key / missing permission / wrong project: retrying won't help and RevenueCat
          // drops events after a few retries, so use the event itself instead. A 429 is
          // transient (per-minute windows): keep it on the retry path, because event mapping
          // can apply a stale event over a newer state.
          if (/^revenuecat_(401|403)$|^entitlement_not_found$/.test(r.reason)) unusable = true;
          else transient = true;
        }
      }
      console.log("Synced from RevenueCat:", JSON.stringify(results));
      if (unusable) {
        console.error("RevenueCat API unusable for webhook sync, falling back to event mapping:", JSON.stringify(results));
      } else {
        // 500 makes RevenueCat retry the webhook later (network / 5xx / db errors).
        return new Response(
          JSON.stringify({ success: !transient, event_type: event.type }),
          { status: transient ? 500 : 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Fallback without the secret API key: map the event type.
    const mapped = mapEventToStatus(event.type);
    if (!mapped) {
      return new Response(
        JSON.stringify({ success: true, event_type: event.type, ignored: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const { plan, status } = mapped;
    const periodType = mapPeriodType(event.product_id);

    // Prepare update data
    const updateData: Record<string, unknown> = {
      subscription_plan: plan,
      subscription_status: status,
      subscription_product_id: event.product_id,
      subscription_period_type: periodType,
      revenuecat_customer_id: event.original_app_user_id,
      last_verified_at: new Date().toISOString(),
    };

    // Set expiration date if available
    if (event.expiration_at_ms) {
      updateData.subscription_expires_at = new Date(event.expiration_at_ms).toISOString();
    }

    // Set purchase date for initial purchases
    if (event.type === "INITIAL_PURCHASE" || event.type === "NON_RENEWING_PURCHASE") {
      updateData.original_purchase_date = new Date(event.purchased_at_ms).toISOString();
    }

    // Clear trial fields if converting from trial
    if (event.is_trial_conversion) {
      updateData.trial_started_at = null;
      updateData.trial_ends_at = null;
    }

    // Update user in database
    // First try by app_user_id (which should be Supabase user ID)
    const { data, error } = await supabase
      .from("users")
      .update(updateData)
      .eq("id", event.app_user_id)
      .select();

    // No matching row is not an error for PostgREST: use the fallback in that case too.
    if (error || !data || data.length === 0) {
      if (error) console.error("Failed to update user:", error);

      // Try by revenuecat_customer_id as fallback
      const { data: fallbackData, error: fallbackError } = await supabase
        .from("users")
        .update(updateData)
        .eq("revenuecat_customer_id", event.original_app_user_id)
        .select();

      if (fallbackError) {
        console.error("Fallback update also failed:", fallbackError);
        return new Response(
          JSON.stringify({ error: "Failed to update user" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      console.log("User updated via fallback:", fallbackData);
    } else {
      console.log("User updated successfully:", data);
    }

    return new Response(
      JSON.stringify({ success: true, event_type: event.type }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    // Log full error for debugging but return generic message to client
    console.error("Webhook error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
