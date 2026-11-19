// Cloudflare Worker "scanqraft-redirect" on the scanqraft.app apex (account 795ccacd…).
// Source of truth for what is deployed: edit here, then upload (see infra/cloudflare/README.md).
//
// scanqraft.app/<slug> → Supabase edge function `redirect` (dynamic QR codes).
// scanqraft.app/       → the website (www).
// Supabase forces text/plain + a sandbox CSP on function responses, so the real
// Content-Type / CSP come back in X-Qraft-* headers and are restored here.

const FN = "https://cnieotneosdkfzboxazw.supabase.co/functions/v1/redirect/";
const PASS = ["location", "cache-control", "x-robots-tag", "referrer-policy", "content-disposition", "retry-after", "allow", "vary"];

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response(null, { status: 405, headers: { Allow: "GET, HEAD" } });
    }

    const slug = url.pathname.replace(/^\/+|\/+$/g, "");
    if (!slug) return Response.redirect("https://www.scanqraft.app/", 301);
    if (slug === "robots.txt") {
      return new Response("User-agent: *\nDisallow: /\n", { headers: { "Content-Type": "text/plain; charset=utf-8" } });
    }

    const headers = { "X-Forwarded-Host": url.hostname };
    const lang = request.headers.get("accept-language");
    if (lang) headers["Accept-Language"] = lang;
    // The function answers natively per platform (iPhone contact/event sheets, Android intents).
    const ua = request.headers.get("user-agent");
    if (ua) headers["User-Agent"] = ua;
    const country = request.cf?.country ?? request.headers.get("cf-ipcountry");
    if (country) headers["X-Country"] = country;

    let upstream;
    try {
      upstream = await fetch(FN + encodeURIComponent(slug) + url.search, {
        method: request.method,
        redirect: "manual",
        headers,
      });
    } catch {
      return new Response("Service temporarily unavailable", {
        status: 503,
        headers: { "Retry-After": "30", "Cache-Control": "no-store", "Content-Type": "text/plain; charset=utf-8" },
      });
    }

    const out = new Headers();
    for (const h of PASS) {
      const v = upstream.headers.get(h);
      if (v) out.set(h, v);
    }
    out.set("Content-Type", upstream.headers.get("x-qraft-content-type") ?? upstream.headers.get("content-type") ?? "text/plain; charset=utf-8");
    const csp = upstream.headers.get("x-qraft-csp");
    if (csp) out.set("Content-Security-Policy", csp);
    out.set("X-Content-Type-Options", "nosniff");
    if (!out.has("cache-control")) out.set("Cache-Control", "no-store");

    return new Response(request.method === "HEAD" ? null : upstream.body, { status: upstream.status, headers: out });
  },
};
