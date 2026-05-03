---
phase: 09-checkout-wompi-compliance
plan: "04"
subsystem: payments
tags: [wompi, webhook, sha256, hmac, deno, supabase-edge-functions, idempotency, order-fsm]

# Dependency graph
requires:
  - phase: 09-checkout-wompi-compliance
    plan: "01"
    provides: "apply_payment_event RPC, payment_events table, orders FSM"
  - phase: 09-checkout-wompi-compliance
    plan: "02"
    provides: "create-payment-intent Edge Function, payments.transaction_ref"
provides:
  - "wompi-webhook Edge Function deployed with --no-verify-jwt at https://cnieotneosdkfzboxazw.supabase.co/functions/v1/wompi-webhook"
  - "SHA256 X-Event-Checksum signature verification (T-09-15 mitigation)"
  - "Idempotent payment_events insert via PRIMARY KEY — duplicate delivery → 200 already_processed"
  - "apply_payment_event RPC integration: APPROVED→paid, DECLINED/VOIDED/ERROR→payment_failed"
  - "WOMPI_EVENTS_SECRET set in Supabase secrets"
affects:
  - "09-05 (webhook registration in Wompi dashboard)"
  - "orders module — server-authoritative status now driven by webhook"
  - "payment result screen — reads orders.status from DB, not Wompi redirect"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deno.serve() with --no-verify-jwt for third-party webhook receivers"
    - "Idempotent webhook: INSERT payment_events → PK collision → 200 without FSM"
    - "HMAC-SHA256 verification via crypto.subtle.digest (Deno built-in, no import)"
    - "service_role Supabase client for Edge Function → DB writes and SECURITY DEFINER RPCs"

key-files:
  created:
    - supabase/functions/wompi-webhook/index.ts
    - supabase/functions/wompi-webhook/deno.json
  modified: []

key-decisions:
  - "Return 200 on RPC errors to prevent Wompi retry storms; event is already idempotently recorded in payment_events for reconciliation"
  - "Check both X-Event-Checksum header AND signature.checksum body field (Wompi may use either; header takes priority per spec)"
  - "Non-transaction events (e.g., nip.updated) are recorded in payment_events but cause no FSM transition"
  - "deno.json import map follows redirect function pattern (esm.sh @supabase/supabase-js@2)"

patterns-established:
  - "Pattern: Signature-first — verify HMAC before touching DB on any inbound webhook"
  - "Pattern: Insert-or-fail idempotency — PK collision = already processed, return 200"
  - "Pattern: Log RPC errors, return 200 — never expose internal error details to Wompi"

requirements-completed:
  - MKT-06

# Metrics
duration: 10min
completed: 2026-05-03
---

# Phase 09 Plan 04: wompi-webhook Edge Function Summary

**Deno Edge Function with HMAC-SHA256 signature verification, idempotent payment_events insert, and apply_payment_event RPC integration — deployed and verified rejecting forged events with HTTP 401**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-03T17:28:37Z
- **Completed:** 2026-05-03T17:38:00Z
- **Tasks:** 1 of 2 complete (Task 2 is checkpoint:human-verify)
- **Files modified:** 2 created

## Accomplishments

- wompi-webhook Edge Function deployed ACTIVE at `cnieotneosdkfzboxazw.supabase.co/functions/v1/wompi-webhook`
- HMAC-SHA256 X-Event-Checksum verification live — forged event with bad checksum tested and correctly rejected with HTTP 401
- Idempotent processing via `payment_events.event_id` PRIMARY KEY collision check (code 23505 → 200 `already_processed`)
- `apply_payment_event` RPC wired: `APPROVED` → `orders.status = paid`, `DECLINED/VOIDED/ERROR` → `payment_failed`
- `WOMPI_EVENTS_SECRET` set in Supabase project secrets
- All STRIDE threats T-09-15 through T-09-19 addressed in implementation

## Task Commits

1. **Task 1: wompi-webhook Edge Function with signature verification + idempotency** - `9fc5056` (feat)

**Plan metadata:** (pending final docs commit after checkpoint verification)

## Files Created/Modified

- `supabase/functions/wompi-webhook/index.ts` — Deno Edge Function: SHA256 checksum verification, idempotent payment_events insert, apply_payment_event RPC call
- `supabase/functions/wompi-webhook/deno.json` — Import map + lint config following project function conventions

## Decisions Made

- Return 200 on `apply_payment_event` RPC errors to prevent Wompi retry storms; event is already idempotently recorded in `payment_events` for manual reconciliation
- Check both `X-Event-Checksum` header AND `signature.checksum` body field (header takes priority per Wompi spec; body fallback for compatibility)
- Non-`transaction.updated` events are recorded in `payment_events` but cause no FSM state change — logged as informational
- `deno.json` import map added following the `redirect` function pattern in this project

## Deviations from Plan

None — plan executed exactly as written. The `deno.json` creation was explicitly specified in the task notes ("follow the pattern from `supabase/functions/ai-stylize/`").

## Issues Encountered

None. Function bundled and deployed cleanly. Forged-event smoke test returned 401 as expected.

## Threat Surface Scan

All threats from plan's `<threat_model>` are mitigated in implementation:

| Threat | Mitigation | Verified |
|--------|-----------|----------|
| T-09-15: Forged APPROVED event | SHA256 checksum before any DB write | Yes — curl test returned 401 |
| T-09-16: Double event delivery | PK collision → 200 without FSM re-run | Yes — code path present |
| T-09-17: service_role_key in response | Key only in Deno.env, never serialized | Yes — grep confirms no key in response paths |
| T-09-18: Replay attack with valid checksum | PK deduplication regardless of timing | Yes — same mechanism as T-09-16 |
| T-09-19: Events secret in source code | Read exclusively from Deno.env | Yes — no hardcoded secrets in index.ts |

No new threat surface introduced beyond what the plan models.

## User Setup Required

**Wompi Dashboard manual step required:**

After deploying, register the webhook URL in Wompi Sandbox dashboard:
1. Wompi Dashboard → Sandbox → Webhooks → Add webhook URL
2. URL: `https://cnieotneosdkfzboxazw.supabase.co/functions/v1/wompi-webhook`
3. Events: `transaction.updated`

This is Task 2 (checkpoint:human-verify) — see checkpoint section.

## Next Phase Readiness

- Webhook is live and verified for signature validation
- Needs Wompi sandbox webhook registration (checkpoint Task 2) before end-to-end payment flow works
- Once webhook is registered and a sandbox payment completes, `payment_events` row should appear and `orders.status` should transition to `paid`

---
*Phase: 09-checkout-wompi-compliance*
*Completed: 2026-05-03*
