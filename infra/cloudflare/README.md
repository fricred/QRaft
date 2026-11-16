# Cloudflare

`scanqraft-redirect.js` is the Worker on the `scanqraft.app` apex route. It serves the
dynamic QR codes (`/<slug>` → Supabase function `redirect`) and sends `/` to the website.

Deploy (dashboard: Workers & Pages → scanqraft-redirect → Edit code, paste, Deploy), or
with wrangler once logged in:

    npx wrangler deploy infra/cloudflare/scanqraft-redirect.js --name scanqraft-redirect --compatibility-date 2026-11-01

Routes and DNS stay as configured in the dashboard (apex `scanqraft.app/*`).
