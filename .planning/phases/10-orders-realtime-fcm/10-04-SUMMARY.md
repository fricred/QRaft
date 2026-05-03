---
phase: 10-orders-realtime-fcm
plan: 04
subsystem: notifications
tags: [fcm, firebase, supabase, edge-function, push-notifications, postgres-rpc, db-webhook]

# Dependency graph
requires:
  - phase: 10-orders-realtime-fcm/10-01
    provides: notifications table + user_fcm_tokens table with RLS
  - phase: 10-orders-realtime-fcm/10-03
    provides: FCM foreground overlay + background/killed-app navigation
  - phase: 09-checkout-payments/09-01
    provides: orders table + apply_payment_event RPC + FSM trigger

provides:
  - insert_order_notification: SECURITY DEFINER helper writing to notifications table
  - transition_order: operator RPC for FSM state changes (Phase 11 will call this)
  - apply_payment_event: patched via CREATE OR REPLACE to insert notification on APPROVED
  - supabase/functions/send-fcm: Deno Edge Function triggered by DB webhook on notifications INSERT

affects:
  - 11-operator-dashboard (will call transition_order RPC directly)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - DB Webhook on notifications INSERT → send-fcm Edge Function (event-driven FCM dispatch)
    - Service account JWT RS256 + OAuth2 exchange via crypto.subtle (no external package)
    - Automatic stale FCM token cleanup on UNREGISTERED response
    - SECURITY DEFINER helper function pattern for cross-privilege DB writes

key-files:
  created:
    - supabase/migrations/20260510000001_notify_on_order_transition.sql
    - supabase/functions/send-fcm/index.ts
  modified: []

key-decisions:
  - "transition_order GRANT EXECUTE only to service_role (T-10-15); authenticated client has zero EXECUTE privilege — FSM trigger validates legality of any UPDATE regardless"
  - "send-fcm returns 200 always (even on partial failure) to prevent DB webhook retry storms creating duplicate notifications; per-row fcm_state tracks actual outcome"
  - "Unregistered FCM tokens are auto-deleted on 404 or UNREGISTERED response to prevent accumulation (T-10-16 cleanup)"
  - "OAuth2 access token obtained via crypto.subtle RS256 JWT exchange — no external package; error logs never contain service account key or access token (T-10-14)"
  - "apply_payment_event patched via CREATE OR REPLACE — idempotent; wompi-webhook Edge Function requires no changes since it already calls this RPC"
  - "insert_order_notification is a SECURITY DEFINER helper called by both transition_order and apply_payment_event — single INSERT point for audit trail completeness"
  - "send-fcm validates Authorization: Bearer <service_role_key> header (T-10-12); unauth callers get 401"
  - "notification title/body built server-side in parameterized CASE statements — no user-supplied text in notification payload (T-10-13)"

requirements-completed:
  - MKT-09

# Metrics
duration: 5min
completed: 2026-05-03
---

# Phase 10 Plan 04: send-fcm Edge Function + DB Webhook Trigger Summary

**Server-side FCM loop closed: transition_order RPC + apply_payment_event patch insert notifications rows; DB Webhook on notifications INSERT triggers send-fcm Edge Function which dispatches FCM HTTP v1 push to all user tokens**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-03T18:13:54Z
- **Completed:** 2026-05-03T18:20:00Z
- **Tasks:** 2 auto tasks + 1 checkpoint (auto-approved, autonomous mode per execution rules)
- **Files created:** 2

## Accomplishments

- Created `supabase/migrations/20260510000001_notify_on_order_transition.sql` with:
  - `insert_order_notification()` SECURITY DEFINER helper — single INSERT point for all FSM transitions
  - `transition_order(order_id, new_status)` RPC — operator-facing FSM driver with Spanish notification text for all 8 non-payment states; GRANT EXECUTE only to service_role (T-10-15)
  - `apply_payment_event` patched via CREATE OR REPLACE — inserts payment_approved notification on Wompi APPROVED; wompi-webhook Edge Function requires no changes
- Created `supabase/functions/send-fcm/index.ts`:
  - Authorization header validation (T-10-12)
  - OAuth2 access token via crypto.subtle RS256 JWT + Google token exchange — no external package
  - Fetches all user FCM tokens; skips gracefully (marks sent) when no tokens registered
  - Sends FCM HTTP v1 push to each token with `title_es`/`body_es` + order data for deep-link
  - Android: `channel_id: qraft_orders`, `HIGH` priority; APNs: `sound: default`
  - Auto-deletes UNREGISTERED tokens on 404/UNREGISTERED response (T-10-16 cleanup)
  - Updates `notifications.fcm_state` = `sent` or `failed` + `fcm_retries` + `sent_at`
  - Always returns 200 to prevent DB webhook duplicate-send retries

## Task Commits

1. **Task 1: transition_order RPC + apply_payment_event FCM patch** — `b5b0636` (feat)
2. **Task 2: send-fcm Deno Edge Function** — `fc0b437` (feat)

## Files Created/Modified

- `supabase/migrations/20260510000001_notify_on_order_transition.sql` — insert_order_notification helper + transition_order RPC + apply_payment_event CREATE OR REPLACE with notification INSERT on APPROVED
- `supabase/functions/send-fcm/index.ts` — Deno Edge Function: Authorization validation, OAuth2 JWT exchange, FCM HTTP v1 multi-token dispatch, stale token cleanup, fcm_state update

## Decisions Made

- `transition_order` GRANT EXECUTE restricted to `service_role` only (T-10-15): client cannot drive FSM via direct RPC call. The FSM trigger `validate_order_transition` is an additional independent enforcement layer.
- `send-fcm` returns HTTP 200 for all outcomes (success, partial failure, no tokens): DB Webhook retry-on-5xx would cause duplicate sends; `notifications.fcm_state` provides the per-row audit trail instead.
- FCM service account private key is never logged; error messages use generic text only (T-10-14).
- `insert_order_notification` is a shared helper called by both `transition_order` and `apply_payment_event` — keeps notification INSERT logic in a single location for auditing.

## Deviations from Plan

None — plan executed exactly as written. The checkpoint was auto-approved per execution rules (autonomous mode, both tasks complete, all verifications passing).

## Checkpoint

**Type:** human-verify (auto-approved per execution rules — autonomous mode)
**Reason:** Both tasks complete; migration and Edge Function code written; all verification checks pass.
**Auto-approved:** Yes

**Manual steps still required by user:**
1. Apply `20260510000000_notifications_fcm_schema.sql` in Supabase Dashboard → SQL Editor (if not yet applied from plan 10-01)
2. Apply `20260510000001_notify_on_order_transition.sql` in Supabase Dashboard → SQL Editor
3. Obtain Firebase service account JSON: Firebase Console → Project settings (`qraft-e8a1d`) → Service accounts → Generate new private key
4. Set Supabase secret: Dashboard → Settings → Secrets → `FCM_SERVICE_ACCOUNT_JSON` = full JSON content
5. Enable Cloud Messaging API (V1): Firebase Console → Project settings → Cloud Messaging → Enable
6. Deploy: `supabase functions deploy send-fcm`
7. Configure DB Webhook: Dashboard → Database → Webhooks → Create: table=`notifications`, events=INSERT, URL=`https://<project-ref>.supabase.co/functions/v1/send-fcm`, header `Authorization: Bearer <service_role_key>`
8. Test: `SELECT transition_order('<order-id>', 'received_by_ops');` → expect push on device within 5s

## Known Stubs

None — all FCM pipeline code is fully implemented. The function is ready to deploy; the only remaining work is the user-performed setup steps documented above.

## Threat Flags

No new threat surface beyond the plan's threat model (T-10-12 through T-10-17). All mitigations documented in the threat register are implemented:
- T-10-12: Authorization header validated in send-fcm
- T-10-13: Notification body built server-side via parameterized CASE; no user text
- T-10-14: Private key and access token never logged; generic error messages only
- T-10-15: transition_order GRANT EXECUTE restricted to service_role
- T-10-16: Unregistered tokens auto-deleted on FCM 404/UNREGISTERED response

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| supabase/migrations/20260510000001_notify_on_order_transition.sql | FOUND |
| supabase/functions/send-fcm/index.ts | FOUND |
| transition_order count in migration (≥1) | 6 |
| insert_order_notification count in migration (≥1) | 6 |
| fcm.googleapis.com in send-fcm | 1 |
| FCM_SERVICE_ACCOUNT_JSON in send-fcm | 5 |
| UNREGISTERED cleanup in send-fcm | 1 |
| commit b5b0636 | FOUND |
| commit fc0b437 | FOUND |
| No hardcoded secrets | CONFIRMED (all via Deno.env.get or in-memory object access) |

---
*Phase: 10-orders-realtime-fcm*
*Completed: 2026-05-03*
