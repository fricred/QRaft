---
phase: 04-redirect-service-foundation
plan: "02"
subsystem: redirect
tags: [supabase, edge-function, deno, redirect, analytics]
dependency_graph:
  requires: [04-01-redirects-table-ddl]
  provides: [redirect-edge-function]
  affects: [04-03-flutter-destination-editing]
tech_stack:
  added: [deno-std@0.168.0, supabase-js@2/esm.sh]
  patterns: [fire-and-forget-analytics, read-modify-write-scan-count, 301-permanent-redirect]
key_files:
  created:
    - supabase/functions/redirect/index.ts
    - supabase/functions/redirect/deno.json
  modified: []
decisions:
  - "301 (permanent) used for QR scanner caching; can downgrade to 302 if analytics require every scan counted"
  - "Fire-and-forget analytics (not awaited) to minimize redirect latency — analytics loss on crash is acceptable for v1"
  - "Slug validation regex ^[a-z0-9-]{1,64}$ rejects path traversal and SQL injection attempts at function boundary"
  - "Cache-Control: max-age=300 during early dev to limit browser caching before domain/DNS is stable"
  - "Service role key used (not anon key) so the update bypasses RLS; public_read_by_slug RLS policy handles SELECT"
metrics:
  duration: "~1 minute"
  completed: "2026-05-02T11:58:00Z"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 4 Plan 02: Supabase Edge Function for Redirect Summary

## One-liner

Deno Edge Function that resolves `qraft.link/{slug}` → 301 to `destination_url`, incrementing `scan_count` and `last_scanned_at` as fire-and-forget analytics on every hit.

## What Was Built

### `supabase/functions/redirect/index.ts`

The core redirect handler:

| Behavior | Detail |
|---|---|
| Method guard | Returns 405 for any non-GET request |
| Slug extraction | Strips `/redirect` Supabase prefix + leading slash from `pathname` |
| Slug validation | `^[a-z0-9-]{1,64}$` — rejects path traversal, SQL injection, long payloads |
| DB lookup | `SELECT id, destination_url, scan_count FROM redirects WHERE slug = $1` via service role (bypasses RLS) |
| Not found | 404 `{ "error": "Redirect not found" }` JSON |
| Analytics | Fire-and-forget `UPDATE redirects SET scan_count = scan_count+1, last_scanned_at = now() WHERE id = $id` |
| Redirect | 301 with `Location: destination_url` + `Cache-Control: max-age=300` |

**Why service role key for analytics update?** The `public_read_by_slug` RLS policy allows unauthenticated `SELECT`, but `UPDATE` is restricted to `owner_update` (`auth.uid() = owner_id`). The Edge Function runs without a user session, so the service role key is required for the analytics write. The SELECT could use the anon key, but using service role for both calls keeps the code simpler.

### `supabase/functions/redirect/deno.json`

Import map resolving:
- `std/http/server` → `https://deno.land/std@0.168.0/http/server.ts`
- `@supabase/supabase-js` → `https://esm.sh/@supabase/supabase-js@2`

## Deployment Steps (Manual — Human Action Required)

The function is code-complete and committed. Three steps are needed before it can serve live traffic:

### Step 1: Apply the redirects table migration (from plan 04-01)

If not already done from plan 04-01:

1. Open [Supabase Dashboard](https://app.supabase.com) → Project `cnieotneosdkfzboxazw`
2. Navigate to **SQL Editor**
3. Paste contents of `supabase/migrations/20260502000000_redirects_table.sql`
4. Click **Run**

### Step 2: Deploy the Edge Function

From the project root:

```bash
# Authenticate with Supabase CLI (one-time setup)
supabase login

# Link project (if not already linked)
supabase link --project-ref cnieotneosdkfzboxazw

# Deploy the redirect function
supabase functions deploy redirect
```

The function will be available at:
```
https://cnieotneosdkfzboxazw.supabase.co/functions/v1/redirect/{slug}
```

### Step 3: Register `qraft.link` domain and configure DNS

Two sub-options:

#### Option A — Supabase Custom Domain (recommended)

1. In Supabase Dashboard → **Settings** → **Custom Domains**
2. Add `qraft.link` as a custom domain
3. Follow the DNS verification steps Supabase provides
4. Once verified, Edge Functions are served at `qraft.link/functions/v1/redirect/{slug}`
5. Set up a URL rewrite/redirect rule so `qraft.link/{slug}` → `qraft.link/functions/v1/redirect/{slug}` (requires Cloudflare Worker or Supabase Vercel-style middleware if Supabase custom domain doesn't support path rewrites directly)

#### Option B — Cloudflare Worker / Vercel Edge proxy

1. Register `qraft.link` at any domain registrar
2. Point DNS NS records to Cloudflare (free tier sufficient)
3. In Cloudflare → Workers → Create a Worker that proxies:
   ```javascript
   addEventListener('fetch', event => {
     const url = new URL(event.request.url);
     const target = `https://cnieotneosdkfzboxazw.supabase.co/functions/v1/redirect${url.pathname}`;
     event.respondWith(fetch(target, event.request));
   });
   ```
4. Add a `qraft.link/*` route for the Worker

#### Option C — Supabase Edge Function as direct endpoint (no custom domain)

For testing before domain registration, QR codes can encode:
```
https://cnieotneosdkfzboxazw.supabase.co/functions/v1/redirect/{slug}
```
This is fully functional but uses the Supabase project URL rather than `qraft.link`. Migrate to Option A or B once the domain is acquired.

### Step 4: Verify deployment

```bash
# Test a known slug (replace with a real slug after inserting a test row)
curl -I "https://cnieotneosdkfzboxazw.supabase.co/functions/v1/redirect/test123"
# Expected: HTTP/1.1 404 (if slug doesn't exist) or HTTP/1.1 301 (if it does)

# Test invalid slug (should return 400)
curl -I "https://cnieotneosdkfzboxazw.supabase.co/functions/v1/redirect/../etc/passwd"
# Expected: HTTP/1.1 400
```

## Deviations from Plan

### Auto-fixed Issues

**[Rule 2 - Missing Critical Functionality] Slug input validation added**

The plan template did not include input validation beyond the empty-slug check. Added `^[a-z0-9-]{1,64}$` regex guard before the DB query to prevent path traversal and reject malformed inputs that could reach the DB.

**[Rule 2 - Missing Critical Functionality] Method guard added**

Added `req.method !== "GET"` check returning 405 — the plan template had no method guard, leaving POST/PUT/DELETE requests to fall through to the DB query unnecessarily.

**[Rule 1 - Bug] Fixed plan template's incorrect analytics update**

The plan template used `supabase.rpc('increment', ...)` inside `.update()` which is incorrect Supabase JS v2 API usage (`.rpc()` is a standalone call, not a field value). Replaced with the correct read-modify-write: `scan_count: data.scan_count + 1`.

## Known Stubs

None — this is a pure TypeScript/Deno function with no UI rendering.

The `scan_count` increment is a read-modify-write (not atomic). Under high concurrent traffic, counts could be undercounted. This is a known v1 limitation documented in plan 04-01 as well. A future plan may add a Postgres `increment_redirect_scan(id UUID)` RPC to make it atomic.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: service-role-key-in-function | supabase/functions/redirect/index.ts | Uses SUPABASE_SERVICE_ROLE_KEY for analytics UPDATE. Key is injected by Edge Runtime as env var (not hardcoded). Ensure function is not publicly debuggable. |

The service role key exposure risk is mitigated by Supabase Edge Runtime's automatic injection — the key is never in source code or logs. However, if the function ever logs `req.headers` or `Deno.env`, the key could leak. Current implementation does not log either.

## Self-Check: PASSED

- `supabase/functions/redirect/index.ts`: EXISTS
- `supabase/functions/redirect/deno.json`: EXISTS
- Commit `674c24a` in git history: CONFIRMED
- No unexpected file deletions: CONFIRMED
- No Flutter/Dart files touched: CONFIRMED
