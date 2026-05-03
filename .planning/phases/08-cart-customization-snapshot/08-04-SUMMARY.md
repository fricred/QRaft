---
phase: 08-cart-customization-snapshot
plan: "04"
subsystem: cart-totals-ui
tags: [flutter, riverpod, cart, supabase-rpc, cop-currency, tdd, shimmer]

requires:
  - phase: 08-01
    provides: CartTotalsEntity + cartTotalsProvider FutureProvider
  - phase: 08-02
    provides: CartScreen with _CartSummaryPlaceholder stub
  - phase: 08-03
    provides: snapshot pipeline + cartItemsProvider + cart_providers.dart

provides:
  - CartSummaryWidget (server-authoritative RPC totals: subtotal / IVA 19% / envío / total in COP)
  - CartScreen updated with CartSummaryWidget + 'Proceder al pago' GlassButton
  - _CartSummaryPlaceholder stub removed

affects:
  - 09-checkout (button _onProceedToCheckout is a named replace-point; Phase 9 navigates to CheckoutScreen)

tech-stack:
  added: []
  patterns:
    - "TDD RED/GREEN: failing tests committed before implementation; 4/4 tests pass GREEN"
    - "es_CO locale (NumberFormat.currency) produces trailing-symbol format: '89.000 $' — test helpers use the same formatter to avoid hardcoded locale strings"
    - "cartTotalsProvider FutureProvider watched in CartScreen; totalsReady guard disables button during loading"
    - "_onProceedToCheckout() extracted method — Phase 9 replace-point"

key-files:
  created:
    - lib/features/cart/presentation/widgets/cart_summary_widget.dart
    - test/features/cart/presentation/widgets/cart_summary_widget_test.dart
  modified:
    - lib/features/cart/presentation/pages/cart_screen.dart

key-decisions:
  - "Test expectations use the same _cop() helper (NumberFormat.currency es_CO) as the implementation — prevents locale format divergence between test and widget"
  - "Test 3 (loading state) uses a 10-second delayed future + tester.pump(11s) to drain the timer cleanly rather than a never-completing Completer that triggers 'pending timer' assertion"
  - "Removed _CartSummaryPlaceholder class entirely — no backward-compat needed since stub was private"

requirements-completed:
  - MKT-03

duration: 3min
completed: 2026-05-03
---

# Phase 8 Plan 04: Cart Totals Widget + Checkout Button Summary

**CartSummaryWidget wired to server_compute_order_totals RPC; 'Proceder al pago' button completes Phase 8's user-visible cart experience**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-03T16:49:48Z
- **Completed:** 2026-05-03T16:52:53Z
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments

- `CartSummaryWidget` is a `ConsumerWidget` that watches `cartTotalsProvider` (FutureProvider backed by `server_compute_order_totals` RPC). Renders a 4-row dark glassmorphism card: Subtotal / IVA 19% / Envío / Total — all formatted as `es_CO` COP currency. Shimmer skeleton during loading; error fallback text. Semantics identifiers on widget and each price cell.
- `CartScreen` updated: `_CartSummaryPlaceholder` stub removed, `CartSummaryWidget()` rendered below item list. `PrimaryGlassButton('Proceder al pago')` added with `totalsReady` guard (disabled while `cartTotalsProvider` is loading). `_onProceedToCheckout()` shows placeholder SnackBar — Phase 9 replace-point for checkout navigation.
- 4/4 `CartSummaryWidget` widget tests pass (TDD RED/GREEN cycle).

## Task Commits

1. **RED — failing tests** — `0bee67d` (test)
2. **Task 1: CartSummaryWidget** — `20172ae` (feat)
3. **Task 2: CartScreen integration** — `082f488` (feat)

## Files Created/Modified

- `lib/features/cart/presentation/widgets/cart_summary_widget.dart` — ConsumerWidget with RPC totals display, shimmer loading, error fallback, Semantics identifiers
- `test/features/cart/presentation/widgets/cart_summary_widget_test.dart` — 4 widget tests using ProviderScope overrides
- `lib/features/cart/presentation/pages/cart_screen.dart` — _CartSummaryPlaceholder replaced; CartSummaryWidget + 'Proceder al pago' button wired

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] es_CO locale formats symbol AFTER number ('89.000 $'), not before ('$89.000')**
- **Found during:** Task 1 GREEN phase — test assertions `find.text(r'$89.000')` found 0 widgets
- **Issue:** Plan spec and layout description showed `$89.000` (prefix format) but `NumberFormat.currency(locale: 'es_CO', symbol: r'$')` outputs `89.000 $` (suffix with trailing space). This matches existing marketplace widgets.
- **Fix:** Test helper `_cop(int)` uses the same `NumberFormat.currency` formatter so tests always match implementation regardless of locale output format.
- **Files modified:** `cart_summary_widget_test.dart`
- **Commit:** `20172ae`

**2. [Rule 1 - Bug] Test 3 (loading state) left a pending timer causing assertion failure**
- **Found during:** Task 1 GREEN phase — "A Timer is still pending even after the widget tree was disposed"
- **Issue:** Using `Future.delayed(const Duration(days: 1))` to simulate loading left a 24h pending timer that Flutter test binding detects as a test invariant violation.
- **Fix:** Changed to `Duration(seconds: 10)` delay + `await tester.pump(const Duration(seconds: 11))` to drain all pending timers before test teardown.
- **Files modified:** `cart_summary_widget_test.dart`
- **Commit:** `20172ae`

**3. [Rule 1 - Bug] Test 2 used findsOneWidget for _cop(0) but both subtotal and IVA render as "0 $" on empty cart**
- **Found during:** Task 1 GREEN phase — `Expected exactly one, Found 2 widgets with text "0 $"`
- **Issue:** `CartTotalsEntity.zero` has `subtotalCop=0` AND `ivaCop=0`, both rendering identical `"0 $"` text.
- **Fix:** Changed assertion to `findsAtLeastNWidgets(1)` — the goal of Test 2 is to confirm the zero value IS rendered, not that it appears exactly once.
- **Files modified:** `cart_summary_widget_test.dart`
- **Commit:** `20172ae`

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| _onProceedToCheckout shows SnackBar | cart_screen.dart | ~70 | Phase 9 checkout flow |

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundary changes introduced. `CartSummaryWidget` consumes `cartTotalsProvider` which was already analyzed in Plan 01 threat model (T-08-01-*). The new `_onProceedToCheckout` placeholder has no side effects (SnackBar only).

T-08-04-04 mitigation: Phase 9 will re-call `server_compute_order_totals` at checkout creation time — the displayed total in CartSummaryWidget is NEVER used as the Wompi payment amount.

## Self-Check: PASSED
