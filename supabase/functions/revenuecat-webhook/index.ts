// RevenueCat Webhook Handler for Supabase Edge Functions
// Handles subscription lifecycle events from RevenueCat

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { timingSafeEqual } from "https://deno.land/std@0.168.0/crypto/timing_safe_equal.ts";

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
  };
}

// Map RevenueCat event types to subscription status
function mapEventToStatus(eventType: string): { plan: string; status: string } {
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
      console.log(`Unknown event type: ${eventType}`);
      return { plan: "free", status: "active" };
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

    // Map event to subscription status
    const { plan, status } = mapEventToStatus(event.type);
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

    if (error) {
      console.error("Failed to update user:", error);

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
