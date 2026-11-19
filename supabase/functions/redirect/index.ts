// Supabase Edge Function: redirect — the public answer for scanqraft.app/<slug>.
// The Cloudflare Worker on scanqraft.app proxies /<slug> here. Deploy with --no-verify-jwt
// (supabase/config.toml has verify_jwt = false for this function): scanners send no JWT.
//
// What each state answers lives in render.ts (pure, unit-tested):
//   active link/location → 302 (iPhone location → Apple Maps) · iPhone contact/event → the .vcf/.ics
//   itself (Safari's native sheet) · other types → 200 page with native buttons (+ ?dl=, ?view=page)
//   paused / pending_payment → 200 notice · unknown → 404 · revoked → 410 · blocked → 451
//   lookup failure → 503 + Retry-After. Only real views of active codes count as scans.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { detectPlatform, errorOutcome, pickLang, type RedirectRow, respond } from "./render.ts";

const SLUG = /^[a-z0-9-]{1,64}$/;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { persistSession: false } },
);

// Supabase serves function responses with `Content-Type: text/plain` and a sandbox CSP
// (anti-phishing on *.supabase.co). The scanqraft.app Worker restores the real values from
// these headers, which only it reads.
function send(req: Request, out: { status: number; headers: Record<string, string>; body: string | null }): Response {
  const headers: Record<string, string> = { ...out.headers };
  if (headers["Content-Type"]) headers["X-Qraft-Content-Type"] = headers["Content-Type"];
  if (headers["Content-Security-Policy"]) headers["X-Qraft-Csp"] = headers["Content-Security-Policy"];
  return new Response(req.method === "HEAD" ? null : out.body, { status: out.status, headers });
}

function nonce(): string {
  const b = new Uint8Array(16);
  crypto.getRandomValues(b);
  return btoa(String.fromCharCode(...b));
}

declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return new Response(null, { status: 405, headers: { Allow: "GET, HEAD" } });
  }

  const url = new URL(req.url);
  // Supabase routes /functions/v1/redirect/<slug> as "/redirect/<slug>".
  const slug = url.pathname.replace(/^\/redirect/, "").replace(/^\/+|\/+$/g, "").toLowerCase();
  const lang = pickLang(req.headers.get("accept-language"));
  const n = nonce();

  if (!slug) {
    return new Response(null, { status: 302, headers: { Location: "https://www.scanqraft.app", "Cache-Control": "no-store" } });
  }

  let row: RedirectRow | null = null;
  if (SLUG.test(slug)) {
    const { data, error } = await supabase
      .from("redirects")
      .select("id, slug, status, content_type, content")
      .eq("slug", slug)
      .maybeSingle();
    if (error) {
      console.error(`lookup failed for ${slug}:`, error.message);
      return send(req, errorOutcome(lang, slug, n));
    }
    row = data as RedirectRow | null;
  }

  const out = respond(slug, row, {
    lang,
    dl: url.searchParams.get("dl"),
    view: url.searchParams.get("view"),
    platform: detectPlatform(req.headers.get("user-agent")),
    nonce: n,
    now: new Date(),
  });

  // HEAD = link previews / scanner pre-checks, not a person scanning.
  if (out.countScan && row && req.method === "GET") {
    const country = req.headers.get("cf-ipcountry") ?? req.headers.get("x-country");
    const scan = Promise.resolve(supabase
      .rpc("record_redirect_scan", { p_redirect: row.id, p_country: country && /^[A-Z]{2}$/.test(country) ? country : null })
      .then(({ error }) => { if (error) console.error(`scan count failed for ${slug}:`, error.message); }));
    if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(scan);
    else await scan;
  }

  return send(req, out);
});
