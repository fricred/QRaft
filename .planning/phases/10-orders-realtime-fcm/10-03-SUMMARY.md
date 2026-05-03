---
phase: 10-orders-realtime-fcm
plan: 03
subsystem: notifications
tags: [fcm, firebase, flutter_local_notifications, riverpod, navigation]

# Dependency graph
requires:
  - phase: 10-orders-realtime-fcm/10-01
    provides: FcmService + firebase_messaging activated
  - phase: 10-orders-realtime-fcm/10-02
    provides: OrderDetailScreen with orderId constructor

provides:
  - notificationHandlerProvider: wires onMessageOpenedApp → OrderDetailScreen navigation
  - checkInitialFcmMessage(): killed-app cold-launch tap handler
  - FcmOverlayHandler: foreground FCM → flutter_local_notifications heads-up banner
  - MainScaffold wraps body with FcmOverlayHandler; initState activates providers

affects:
  - 10-04-send-fcm-edge-function (consumers of this notification pipeline)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Side-effect Riverpod provider for FCM lifecycle listener (notificationHandlerProvider)
    - StatefulWidget wrapper for flutter_local_notifications initialization (FcmOverlayHandler)
    - postFrameCallback deferral for cold-launch navigation readiness

key-files:
  created:
    - lib/features/notifications/presentation/providers/notification_providers.dart
    - lib/features/notifications/presentation/widgets/fcm_overlay_handler.dart
  modified:
    - lib/features/main/main_scaffold.dart

key-decisions:
  - "notificationHandlerProvider is a side-effect Provider<void>; reading it in initState activates the listener without exposing state to the widget tree"
  - "checkInitialFcmMessage is a standalone async function (not a provider) because getInitialMessage is async and Riverpod providers must be synchronous"
  - "FcmOverlayHandler uses message.hashCode as notification ID to uniquely identify each FCM message without maintaining state"
  - "MainScaffold converted from ConsumerWidget to ConsumerStatefulWidget to gain initState for one-time FCM wiring"
  - "DarwinInitializationSettings sets all request*Permission to false — FcmService.requestPermission already handles the permission dialog"
  - "T-10-09: Navigation to OrderDetailScreen is safe because the screen fetches via Supabase with user_id RLS; forged order_id yields empty/error state"

requirements-completed:
  - MKT-09

# Metrics
duration: 1min
completed: 2026-05-03
---

# Phase 10 Plan 03: FCM Foreground Overlay + Background/Killed-App Navigation Summary

**FCM notification pipeline closed: FcmOverlayHandler shows flutter_local_notifications banners for foreground messages; notificationHandlerProvider + checkInitialFcmMessage navigate to OrderDetailScreen for background and killed-app notification taps**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-05-03T18:09:18Z
- **Completed:** 2026-05-03T18:10:45Z
- **Tasks:** 1 auto task + 1 checkpoint (auto-approved, autonomous mode)
- **Files modified:** 3

## Accomplishments

- Created `notificationHandlerProvider` Riverpod provider wiring `FirebaseMessaging.onMessageOpenedApp` to navigate to `OrderDetailScreen` when `data['order_id']` is present
- Created `checkInitialFcmMessage()` async function handling killed-app cold-launch tap via `getInitialMessage()` with `postFrameCallback` deferral
- Created `FcmOverlayHandler` StatefulWidget wrapping MainScaffold body: initializes `flutter_local_notifications`, creates Android notification channel `qraft_orders`, shows heads-up banner on `FirebaseMessaging.onMessage`
- Converted `MainScaffold` from `ConsumerWidget` to `ConsumerStatefulWidget`; `initState` reads `notificationHandlerProvider` and calls `checkInitialFcmMessage()`
- `flutter analyze` reports 0 issues on all new/modified files
- No new pubspec.yaml dependencies added (both `firebase_messaging` and `flutter_local_notifications` were installed in Phase 1 plan 04)

## Task Commits

1. **Task 1: FCM overlay handler + notification provider + MainScaffold update** - `59e3d7e` (feat)

## Files Created/Modified

- `lib/features/notifications/presentation/providers/notification_providers.dart` - notificationHandlerProvider (side-effect Provider) + checkInitialFcmMessage() function
- `lib/features/notifications/presentation/widgets/fcm_overlay_handler.dart` - StatefulWidget wrapper initializing flutter_local_notifications and showing banners on foreground FCM
- `lib/features/main/main_scaffold.dart` - ConsumerWidget → ConsumerStatefulWidget; initState activates FCM providers; body wrapped with FcmOverlayHandler

## Decisions Made

- Used a `Provider<void>` side-effect pattern for `notificationHandlerProvider` so it is activated once by `ref.read()` without exposing state to the widget tree; this avoids the `ref.listen` overhead while keeping the wiring centralized.
- `checkInitialFcmMessage` is a standalone top-level function (not a Riverpod provider) because `FirebaseMessaging.instance.getInitialMessage()` is `async` and Riverpod providers must be synchronous.
- `FcmOverlayHandler` uses `message.hashCode` as the notification ID — unique per message instance without requiring persistent counter state.
- iOS `DarwinInitializationSettings` suppresses permission re-request (`requestAlertPermission: false`, etc.) since `FcmService.requestPermission()` in plan 01 already handles this on sign-in.

## Deviations from Plan

None — plan executed exactly as written. The checkpoint was auto-approved per autonomous mode rules (analyzer: 0 issues, code complete).

## Checkpoint

**Type:** human-verify (auto-approved in autonomous mode)
**Reason:** Analyzer reported 0 issues; all three FCM lifecycle handlers implemented; FcmOverlayHandler wraps scaffold body; notificationHandlerProvider and checkInitialFcmMessage wired in MainScaffold.initState.
**Auto-approved:** Yes

## Known Stubs

None — all providers and handlers are fully wired to real FCM streams.

## Threat Flags

No new threat surface beyond what is documented in the plan's threat model (T-10-09, T-10-10, T-10-11). Navigation uses `appNavigatorKey` which was already in use for payment result deep links; no new trust boundaries introduced.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| lib/features/notifications/presentation/providers/notification_providers.dart | FOUND |
| lib/features/notifications/presentation/widgets/fcm_overlay_handler.dart | FOUND |
| lib/features/main/main_scaffold.dart modified | FOUND |
| commit 59e3d7e | FOUND |
| FcmOverlayHandler in main_scaffold.dart | FOUND |
| notificationHandlerProvider in main_scaffold.dart | FOUND |
| checkInitialFcmMessage in main_scaffold.dart | FOUND |
| pubspec.yaml unchanged | CONFIRMED |

---
*Phase: 10-orders-realtime-fcm*
*Completed: 2026-05-03*
