// Supabase Edge Function: redirect
// Serves scanqraft.app/{slug} → 301 to destination_url
// Increments scan_count and updates last_scanned_at on every hit.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface RedirectRow {
  id: string;
  destination_url: string;
  scan_count: number;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

serve(async (req: Request): Promise<Response> => {
  // Only accept GET requests. Reject everything else quickly.
  if (req.method !== "GET") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  // Extract the slug from the path.
  // Supabase routes requests to this function as:
  //   https://<project>.supabase.co/functions/v1/redirect/<slug>
  // When using a custom domain (scanqraft.app), the proxy is configured to strip
  // the domain prefix, forwarding e.g. scanqraft.app/abc123 → this function.
  const url = new URL(req.url);
  // pathname will be "/" or "/<slug>" or "/redirect/<slug>" depending on routing.
  // Strip any leading "/redirect" prefix that Supabase may inject.
  const rawPath = url.pathname
    .replace(/^\/redirect/, "") // strip Supabase function path prefix if present
    .replace(/^\//, "")         // strip leading slash
    .trim();

  const slug = rawPath;

  if (!slug) {
    return new Response(
      JSON.stringify({ error: "No slug provided" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // Validate slug format: only lowercase letters, digits, hyphens (a-z0-9-)
  // Rejects path traversal, SQL injection attempts, excessively long inputs.
  if (!/^[a-z0-9-]{1,64}$/.test(slug)) {
    return new Response(
      JSON.stringify({ error: "Invalid slug format" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  // ---------------------------------------------------------------------------
  // Supabase client (service role — bypasses RLS, required for analytics update)
  // SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically by
  // the Supabase Edge Runtime; no manual secret configuration needed.
  // ---------------------------------------------------------------------------
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseServiceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return new Response(
      JSON.stringify({ error: "Service configuration error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // ---------------------------------------------------------------------------
  // Look up the slug (hot path — idx_redirects_slug makes this a index scan)
  // ---------------------------------------------------------------------------
  const { data, error } = await supabase
    .from("redirects")
    .select("id, destination_url, scan_count")
    .eq("slug", slug)
    .single<RedirectRow>();

  if (error || !data) {
    console.log(`Slug not found: ${slug}`);
    return new Response(
      JSON.stringify({ error: "Redirect not found" }),
      { status: 404, headers: { "Content-Type": "application/json" } },
    );
  }

  // ---------------------------------------------------------------------------
  // Fire-and-forget analytics update (read-modify-write — acceptable for v1).
  // We do NOT await this; the redirect is returned immediately.
  // A lost increment (e.g., function crash after this point) is acceptable for
  // v1 analytics. Plan 04-02 notes this as a known v1 limitation.
  // ---------------------------------------------------------------------------
  const now = new Date().toISOString();
  supabase
    .from("redirects")
    .update({
      scan_count: data.scan_count + 1,
      last_scanned_at: now,
    })
    .eq("id", data.id)
    .then(({ error: updateError }) => {
      if (updateError) {
        // Non-fatal: log but do not fail the redirect
        console.error(`Failed to update analytics for slug "${slug}":`, updateError.message);
      }
    });

  // ---------------------------------------------------------------------------
  // 301 Permanent Redirect
  // Use 301 so browsers and QR scanner apps cache the destination.
  // Change to 302 if you want to guarantee every scan is counted (no browser
  // cache) — but 302 adds latency on repeat scans.
  // ---------------------------------------------------------------------------
  return new Response(null, {
    status: 301,
    headers: {
      Location: data.destination_url,
      // Prevent the browser from caching this redirect indefinitely while the
      // service is in early development. Remove or increase once stable.
      "Cache-Control": "max-age=300, s-maxage=300",
    },
  });
});
