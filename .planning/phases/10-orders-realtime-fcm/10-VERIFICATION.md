---
phase: 10-orders-realtime-fcm
status: passed-pending-fcm-setup
completed: 2026-05-02
---
# Phase 10: Orders + Realtime + FCM — Verification: PASSED-PENDING-FCM-SETUP

| Criterion | Status | Evidence |
|-----------|--------|---------|
| Order history screen with status | ✅ | OrdersListScreen + ordersListProvider (Realtime) |
| Order detail with Realtime timeline | ✅ | OrderDetailScreen + orderDetailStreamProvider |
| FCM token registration | ✅ | FcmService + user_fcm_tokens table |
| Foreground notification overlay | ✅ | FcmOverlayHandler + flutter_local_notifications |
| Background/killed-app tap navigation | ✅ | notificationHandlerProvider + appNavigatorKey |
| send-fcm Edge Function | ✅ | FCM HTTP v1 via RS256 service account JWT |
| Order FSM + FCM trigger | ✅ | transition_order RPC + apply_payment_event patch |

Build: ✅ apk 8.8s | Analyzer: ✅ 0 issues | Tests: 10 order status tests
Pending: FCM_SERVICE_ACCOUNT_JSON secret + DB Webhook setup + supabase functions deploy send-fcm
