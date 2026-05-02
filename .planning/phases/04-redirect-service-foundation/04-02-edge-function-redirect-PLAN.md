---
phase: 04-redirect-service-foundation
plan: 02
type: execute
wave: 2
depends_on:
  - 04-01
files_modified:
  - supabase/functions/redirect/index.ts
  - supabase/functions/redirect/deno.json
autonomous: true
requirements:
  - RDR-01
  - RDR-02
  - RDR-05
must_haves:
  truths:
    - "Supabase Edge Function `redirect` exists at `supabase/functions/redirect/index.ts`"
    - "Function handles GET `/{slug}` — queries `redirects` table, increments `scan_count`, updates `last_scanned_at`, and returns 301 to `destination_url`"
    - "Returns 404 JSON if slug not found"
    - "Function is deployable via `supabase functions deploy redirect` (noted as manual step — user action at deployment)"
    - "scan_count increment and last_scanned_at update are done via Supabase REST API inside the Edge Function using the service role key from env"
    - "`flutter analyze --no-fatal-warnings` exits 0 (no Flutter changes in this plan)"
  artifacts:
    - path: "supabase/functions/redirect/index.ts"
      provides: "Edge Function for qraft.link/{slug} redirects"
      contains: "301"
---

# Plan 04-02: Supabase Edge Function for Redirect

## Objective
Create the Supabase Edge Function that serves `qraft.link/{slug}` redirects. When a QR code is scanned, the scanner hits `qraft.link/{slug}` which routes to this Edge Function.

## Note on Domain
`qraft.link` domain registration is a user-action gate (deferred — user must register domain + configure DNS to Supabase Edge Runtime). This plan writes the function code so it's ready to deploy once the domain is registered. Document this as a manual step.

## Tasks

### Task 1 — Write Edge Function

`supabase/functions/redirect/index.ts`:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const url = new URL(req.url)
  const slug = url.pathname.replace(/^\//, '')

  if (!slug) {
    return new Response(JSON.stringify({ error: 'No slug provided' }), {
      status: 400, headers: { 'Content-Type': 'application/json' }
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data, error } = await supabase
    .from('redirects')
    .select('id, destination_url')
    .eq('slug', slug)
    .single()

  if (error || !data) {
    return new Response(JSON.stringify({ error: 'Redirect not found' }), {
      status: 404, headers: { 'Content-Type': 'application/json' }
    })
  }

  // Fire-and-forget analytics update
  supabase.from('redirects').update({
    scan_count: supabase.rpc('increment', { row_id: data.id }),
    last_scanned_at: new Date().toISOString(),
  }).eq('id', data.id)

  return new Response(null, {
    status: 301,
    headers: { 'Location': data.destination_url }
  })
})
```

Also create `supabase/functions/redirect/deno.json` with import map.

### Task 2 — Document deployment steps

In SUMMARY.md: document the manual steps:
1. `supabase functions deploy redirect`
2. Register `qraft.link` → configure DNS to point to `<project>.supabase.co/functions/v1/redirect`
3. Or use Supabase custom domain feature

Commit, create SUMMARY.md, update STATE/ROADMAP.
