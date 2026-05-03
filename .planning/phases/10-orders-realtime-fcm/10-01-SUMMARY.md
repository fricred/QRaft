---
phase: 10-orders-realtime-fcm
plan: 01
subsystem: infra
tags: [firebase, fcm, push-notifications, supabase, riverpod]

# Dependency graph
requires:
  - phase: 09-checkout-payments
    provides: orders table with user_id FK (notifications table references orders.id)
  - phase: 01-foundation
    provides: Firebase.initializeApp() in main.dart (D-01)

provides:
  - user_fcm_tokens table with RLS (authenticated INSERT/UPDATE/DELETE own rows)
  - notifications table with RLS (SELECT own rows; service_role INSERT only)
  - FcmService: requestPermission, initialize, _registerToken via Supabase upsert
  - firebaseBackgroundMessageHandler top-level @pragma entry point
  - fcmServiceProvider Riverpod provider
  - FCM background handler wired in main() before runApp

affects:
  - 10-02-order-status-realtime
  - 10-03-foreground-overlay
  - 10-04-send-fcm-edge-function

# Tech tracking
tech-stack:
  added:
    - firebase_messaging 16.2.0 (activated from dormant state; was installed in plan 04)
  patterns:
    - FcmService.testInstance injectable factory for unit testing Firebase services
    - currentUserIdResolver: () => ... pattern for Supabase auth guard in service classes

key-files:
  created:
    - supabase/migrations/20260510000000_notifications_fcm_schema.sql
    - lib/core/services/fcm_service.dart
    - test/core/services/fcm_service_test.dart
  modified:
    - lib/main.dart

key-decisions:
  - "FcmService uses injectable testInstance factory (messaging + currentUserIdResolver params) to enable unit testing without real Firebase/Supabase"
  - "firebaseBackgroundMessageHandler is a no-op stub — Phase 10 plan 03 adds local notification display"
  - "notifications table has NO INSERT/UPDATE/DELETE policy for authenticated role — only service_role (Edge Function) may write (T-10-02)"
  - "user_fcm_tokens UNIQUE(user_id, token) constraint is the DoS guard (T-10-04); upsert on conflict only updates last_seen_at"

patterns-established:
  - "Service testInstance pattern: injectable FirebaseMessaging and resolver for auth guard"
  - "FCM token never logged — only 'token registered successfully' debug message (T-10-03)"

requirements-completed:
  - MKT-09

# Metrics
duration: 3min
completed: 2026-05-03
---

# Phase 10 Plan 01: FCM Token Registration + Notifications Schema Summary

**FCM activated from dormant state: FcmService upserts device tokens into Supabase user_fcm_tokens on sign-in, with background handler wired before runApp and notifications table ready for service_role inserts**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-03T17:54:58Z
- **Completed:** 2026-05-03T17:58:00Z
- **Tasks:** 2 (Task 1: migration, Task 2: FcmService TDD)
- **Files modified:** 4

## Accomplishments

- Created `user_fcm_tokens` and `notifications` Supabase tables with complete RLS policies
- Implemented `FcmService` with injectable test factory, permission request, token upsert, and token-refresh listener
- Wired `FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler)` in `main()` before `runApp()`
- All 5 FcmService unit tests pass (TDD RED → GREEN cycle completed)
- `flutter analyze` reports 0 issues on new/modified files

## Task Commits

1. **Task 1: Supabase migration** - `c084a3d` (feat)
2. **TDD RED gate** - `554ee00` (test)
3. **Task 2: FcmService + main.dart** - `d50c4c2` (feat)

## Files Created/Modified

- `supabase/migrations/20260510000000_notifications_fcm_schema.sql` - user_fcm_tokens + notifications tables with RLS; documents DB webhook wiring for Plan 04
- `lib/core/services/fcm_service.dart` - FcmService singleton + testInstance factory + fcmServiceProvider
- `test/core/services/fcm_service_test.dart` - 5 unit tests covering permission, no-op guard, and background handler
- `lib/main.dart` - Added firebase_messaging import, onBackgroundMessage before runApp, FCM init on sign-in

## Decisions Made

- Used `FcmService.testInstance(messaging:, currentUserIdResolver:)` injectable factory so tests never touch real Firebase or Supabase singletons. The production singleton (`FcmService.instance`) uses `FirebaseMessaging.instance` and `SupabaseService.client`.
- `firebaseBackgroundMessageHandler` is a stub (just logs messageId) — Plan 03 adds foreground overlay via `flutter_local_notifications`.
- `notifications` table has zero INSERT/UPDATE/DELETE policies for the `authenticated` role; only the `service_role` key used by the send-fcm Edge Function (Plan 04) may write.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed NotificationSettings constructor: providesAppNotificationSettings is AppleNotificationSetting not bool**

- **Found during:** Task 2 TDD RED phase
- **Issue:** Test file used `providesAppNotificationSettings: false` (bool) but the `firebase_messaging_platform_interface` package requires `AppleNotificationSetting` enum.
- **Fix:** Changed to `providesAppNotificationSettings: AppleNotificationSetting.notSupported` in all three `NotificationSettings` mock constructors.
- **Files modified:** `test/core/services/fcm_service_test.dart`
- **Verification:** `flutter test` passed after fix.
- **Committed in:** d50c4c2 (Task 2 commit, after GREEN gate)

---

**Total deviations:** 1 auto-fixed (Rule 1 - type mismatch in test mock)
**Impact on plan:** Necessary correction; no scope change.

## Issues Encountered

None beyond the auto-fixed type mismatch above.

## User Setup Required

**Migration must be applied manually.**

1. Go to Supabase Dashboard → SQL Editor
2. Copy and execute the contents of `supabase/migrations/20260510000000_notifications_fcm_schema.sql`

This creates:
- `user_fcm_tokens` table with RLS
- `notifications` table with RLS and pending-state index

The DB webhook (notifications INSERT → send-fcm Edge Function) is configured in Plan 04.

## Next Phase Readiness

- `user_fcm_tokens` and `notifications` tables are defined and ready for use
- `FcmService.initialize()` will register the device token on sign-in once the migration is applied
- Plan 02 (order status realtime) can proceed — it reads from `notifications` via SELECT RLS
- Plan 03 (foreground overlay) can proceed — it extends `FcmService` with `flutter_local_notifications`
- Plan 04 (send-fcm Edge Function) can proceed — it writes to `notifications` via service_role key

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| supabase/migrations/20260510000000_notifications_fcm_schema.sql | FOUND |
| lib/core/services/fcm_service.dart | FOUND |
| test/core/services/fcm_service_test.dart | FOUND |
| commit c084a3d | FOUND |
| commit 554ee00 | FOUND |
| commit d50c4c2 | FOUND |

---
*Phase: 10-orders-realtime-fcm*
*Completed: 2026-05-03*
