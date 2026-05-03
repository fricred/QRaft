---
phase: 09-checkout-wompi-compliance
plan: 03
subsystem: payments
tags: [flutter, webview, wompi, supabase, deeplink, payments, checkout]

# Dependency graph
requires:
  - phase: 09-checkout-wompi-compliance
    plan: 01
    provides: orders table with order_status FSM + create_order RPC
  - phase: 09-checkout-wompi-compliance
    plan: 02
    provides: CheckoutSession entity with wompiCheckoutUrl (consumed by WompiWebViewScreen)

provides:
  - WompiWebViewScreen: full-screen WebView that loads wompiCheckoutUrl and intercepts qraft://payment-result redirect
  - PaymentResultScreen: server-authoritative order status display with Supabase polling, 3 states, Ley 1480 disclaimer
  - appNavigatorKey: global navigator key for cold-launch deep link navigation
  - DeepLinkService payment-result handler: qraft://payment-result before auth checks (T-09-12)

affects:
  - 09-04 (checkout-review screen that pushes WompiWebViewScreen with a CheckoutSession)
  - 10-orders-realtime (navigates to OrderDetailScreen — placeholder wired)
  - deeplink routing for all future qraft:// schemes

# Tech tracking
tech-stack:
  added: []
  patterns:
    - NavigationDecision.prevent intercept for WebView redirect-based payment flow completion
    - Server-authoritative payment status (never trust Wompi URL params — query orders table)
    - PSE/async retry loop (max 5 retries, 2s delay, then pendingPSE UI state)
    - Global navigator key for Riverpod-less navigation from DeepLinkHandler
    - Deep link namespace guard (payment-result checked before auth links, T-09-12)

key-files:
  created:
    - lib/features/checkout/presentation/pages/payment_result_screen.dart
  modified:
    - lib/core/services/deeplink_service.dart
    - lib/main.dart
  previously-committed:
    - lib/features/checkout/presentation/pages/wompi_webview_screen.dart
    - lib/features/checkout/domain/entities/checkout_session.dart

key-decisions:
  - "appNavigatorKey defined in deeplink_service.dart and wired into MaterialApp.navigatorKey in main.dart — avoids circular import"
  - "PaymentResultScreen uses switch expression on _OrderStatus enum for exhaustive state coverage"
  - "GlassButton (not PrimaryGlassButton) used for 'Volver al carrito' button to supply custom red gradient — PrimaryGlassButton has no gradientColors param"
  - "_OrderDetailPlaceholder added inline as a private class — Phase 10 will replace with full OrderDetailScreen at '/orders/{orderId}'"
  - "Linting fix: flutter/foundation.dart import removed as redundant with flutter/material.dart"

patterns-established:
  - "Payment deep link pattern: qraft://payment-result checked with startsWith prefix so Wompi's appended ?id= params are tolerated"
  - "Retry loop pattern: _fetchStatus() recurses up to _maxRetries via Future.delayed; sets pendingPSE after timeout"

requirements-completed: [MKT-05]

# Metrics
duration: 4min
completed: 2026-05-03
---

# Phase 9 Plan 03: WompiWebViewScreen + PaymentResultScreen + DeepLink Extension Summary

**Wompi Web Checkout WebView with server-authoritative order status polling (Supabase), PSE retry loop, Ley 1480 retracto disclaimer, and cold-launch deep link handler guarded before auth (T-09-12)**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-03T17:17:07Z
- **Completed:** 2026-05-03T17:21:04Z
- **Tasks:** 2 completed
- **Files modified:** 4 (2 new, 2 modified)

## Accomplishments

- `WompiWebViewScreen` (previously partially committed) fully wired: loads `wompiCheckoutUrl`, intercepts `qraft://payment-result` via `NavigationDecision.prevent`, pushes `PaymentResultScreen`
- `PaymentResultScreen` fully implemented: 4-state machine (polling / paid / failed / pendingPSE), Supabase query `orders.select('status, paid_at, total_cop, order_number')`, animated neon checkmark, Ley 1480 Art. 47 retracto disclaimer in success state, "Verificar ahora" retry for async PSE flows
- `deeplink_service.dart` extended: `isPaymentResultLink` + `parsePaymentResultLink` static helpers, `_handlePaymentResult` in `DeepLinkHandler` checked BEFORE any auth state machine processing (T-09-12 collision guard)
- `appNavigatorKey` added in `deeplink_service.dart`, wired to `MaterialApp.navigatorKey` in `main.dart` for cold-launch deep link navigation

## Task Commits

1. **Task 1 (previously committed): WompiWebViewScreen + PaymentResultScreen initial** - `0249a69` (feat)
2. **Task 2: DeepLink extension + navigatorKey** - `56488a3` (feat)

## Files Created/Modified

- `lib/features/checkout/presentation/pages/payment_result_screen.dart` — Full-screen payment result with Supabase polling, 3 visible states, PSE pendingPSE state, Ley 1480 disclaimer, neon animated checkmark
- `lib/core/services/deeplink_service.dart` — Added `appNavigatorKey`, `isPaymentResultLink`, `parsePaymentResultLink`, `_handlePaymentResult` in DeepLinkHandler before auth checks
- `lib/main.dart` — Wire `appNavigatorKey` into `MaterialApp.navigatorKey`
- `lib/features/checkout/presentation/pages/wompi_webview_screen.dart` — (previously committed) Full WebView with NavigationDecision.prevent intercept, PopScope cancel dialog
- `lib/features/checkout/domain/entities/checkout_session.dart` — (previously committed) CheckoutSession + WompiConfig entities

## Decisions Made

- `appNavigatorKey` is declared in `deeplink_service.dart` to avoid a circular import (main.dart imports deeplink_service; deeplink_service cannot import main.dart)
- `GlassButton` (not `PrimaryGlassButton`) used for the red "Volver al carrito" CTA — `PrimaryGlassButton` has no `gradientColors` parameter
- `_OrderDetailPlaceholder` is a private class inside `payment_result_screen.dart` — Phase 10 will replace with the real `OrderDetailScreen`
- PSE retry max is 5 attempts × 2s = 10s before switching to `pendingPSE` UI state — covers typical card/Nequi latency; PSE users will see the verify-later message

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed unnecessary import lint in deeplink_service.dart**
- **Found during:** Task 2 (deeplink extension)
- **Issue:** `flutter/foundation.dart` redundant after adding `flutter/material.dart`
- **Fix:** Removed `flutter/foundation.dart` import
- **Files modified:** `lib/core/services/deeplink_service.dart`
- **Verification:** `flutter analyze` 0 issues
- **Committed in:** `56488a3` (Task 2 commit)

**2. [Rule 2 - Missing Critical] Added appNavigatorKey wiring in main.dart**
- **Found during:** Task 2
- **Issue:** Plan specified navigator key for cold-launch deep links but no global navigator key existed in the app; without it, `appNavigatorKey.currentState` would always be null
- **Fix:** Added `GlobalKey<NavigatorState> appNavigatorKey` in deeplink_service.dart and wired it to `MaterialApp.navigatorKey` in main.dart
- **Files modified:** `lib/core/services/deeplink_service.dart`, `lib/main.dart`
- **Verification:** `flutter analyze` 0 issues; `appNavigatorKey` correctly referenced in both files
- **Committed in:** `56488a3` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 lint fix, 1 missing critical)
**Impact on plan:** Both auto-fixes necessary for correctness. No scope creep.

## Known Stubs

- `_OrderDetailPlaceholder` in `payment_result_screen.dart`: Shows "Orden en preparación" placeholder instead of real order detail. Plan explicitly notes "Phase 10 will implement the full screen". Not a blocking stub — the payment result UX is fully functional; only the "Ver mi orden" destination is stubbed.

## Threat Flags

All STRIDE threats from the plan's threat model are mitigated:

| Flag | File | Mitigation |
|------|------|------------|
| T-09-11: Forged qraft://payment-result with status=APPROVED in URL | payment_result_screen.dart | URL params never used for status; always queries orders.status from Supabase |
| T-09-12: Deep link collision with auth flow | deeplink_service.dart | isPaymentResultLink checked BEFORE any auth link processing in handleDeepLink |
| T-09-13: PSE flow leaves WebView open indefinitely | wompi_webview_screen.dart | PopScope + cancel confirmation dialog allows user to exit |
| T-09-14: order_id in deep link URL visible in logs | accepted | UUID, not PII; no financial data exposed |

## Self-Check: PASSED

- [x] `lib/features/checkout/presentation/pages/wompi_webview_screen.dart` — FOUND
- [x] `lib/features/checkout/presentation/pages/payment_result_screen.dart` — FOUND
- [x] `lib/core/services/deeplink_service.dart` — FOUND
- [x] Commit `0249a69` — FOUND (WompiWebViewScreen + PaymentResultScreen initial)
- [x] Commit `56488a3` — FOUND (DeepLinkService extension + navigatorKey)
- [x] `NavigationDecision.prevent` in wompi_webview_screen.dart — FOUND (1 instance)
- [x] `qraft://payment-result` in wompi_webview_screen.dart — FOUND (2 references)
- [x] `qraft://payment-result` in deeplink_service.dart — FOUND (5 references)
- [x] `Ley 1480` in payment_result_screen.dart — FOUND (2 references)
- [x] `Supabase.instance` in payment_result_screen.dart — FOUND (1 instance)
- [x] `flutter analyze --no-fatal-warnings` — 0 issues

## Next Phase Readiness

- Plan 09-04 (CheckoutReviewScreen) can now navigate to `WompiWebViewScreen` with a `CheckoutSession`
- `PaymentResultScreen` is fully wired and will display correct state once the `orders` table migration is applied and `create_order` RPC is callable
- The `_OrderDetailPlaceholder` will be replaced by Phase 10's `OrderDetailScreen` at route `/orders/{orderId}`

---
*Phase: 09-checkout-wompi-compliance*
*Completed: 2026-05-03*
