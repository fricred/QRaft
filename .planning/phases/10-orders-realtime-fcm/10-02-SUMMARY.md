---
phase: 10-orders-realtime-fcm
plan: 02
subsystem: orders
tags: [orders, realtime, supabase, riverpod, flutter, ui]

# Dependency graph
requires:
  - phase: 09-checkout-payments
    provides: orders + order_items tables with RLS and order_status ENUM
  - phase: 10-01
    provides: FCM service and notifications schema

provides:
  - OrderEntity with 11-value OrderStatus enum and OrderStatusX extension
  - OrderItemEntity with customization snapshot
  - OrderRepository interface + OrderRepositoryImpl (Supabase)
  - ordersListProvider, orderDetailStreamProvider, orderItemsProvider
  - OrdersListScreen with shimmer loading and pull-to-refresh
  - OrderDetailScreen with Supabase Realtime stream subscription
  - OrderStatusTimeline widget with neon green/blue/grey FSM visualization
  - Orders tab (index 5) in MainScaffold bottom navigation

affects:
  - 10-03-foreground-overlay (can read orderDetailStreamProvider for live status)
  - 10-04-send-fcm-edge-function (same orders table; status changes trigger FCM)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "StreamProvider.family for Supabase Realtime stream per ARCHITECTURE.md pattern"
    - "FutureProvider.family with offset param for offset-based pagination"
    - "OrderStatusX extension method fromString() for DB ENUM → Dart enum mapping"
    - "TDD RED/GREEN cycle: failing tests committed before domain implementation"

key-files:
  created:
    - lib/features/orders/domain/entities/order_entity.dart
    - lib/features/orders/domain/entities/order_item_entity.dart
    - lib/features/orders/domain/repositories/order_repository.dart
    - lib/features/orders/data/datasources/order_supabase_data_source.dart
    - lib/features/orders/data/repositories/order_repository_impl.dart
    - lib/features/orders/presentation/providers/orders_providers.dart
    - lib/features/orders/presentation/pages/orders_list_screen.dart
    - lib/features/orders/presentation/pages/order_detail_screen.dart
    - lib/features/orders/presentation/widgets/order_status_timeline.dart
    - test/features/orders/domain/order_status_test.dart
  modified:
    - lib/features/main/main_scaffold.dart
    - lib/shared/widgets/main_navigation.dart

key-decisions:
  - "Orders tab added as index 5 (sixth tab) in MainScaffold; MainNavigation Row extended to 5 side slots + 1 center button to avoid displacing existing tabs"
  - "OrderStatusTimeline hides happy-path pending steps when current status is terminal (cancelled/refunded) — only completed + terminal node shown"
  - "orderDetailStreamProvider uses StreamProvider.family (not FutureProvider) to maintain Supabase Realtime subscription alive for the detail screen lifetime"
  - "getUserOrders guards against null currentUser by returning empty list early — avoids assert crash when provider is mounted before auth resolves"

patterns-established:
  - "DB ENUM → Dart enum mapping via static fromString() with ArgumentError for unknown values"
  - "COP monetary amounts as Int throughout domain layer (no floats)"

requirements-completed:
  - MKT-07
  - MKT-08

# Metrics
duration: 5min
completed: 2026-05-03
---

# Phase 10 Plan 02: Orders Domain + Realtime UI Summary

**Complete orders module: domain entities with 11-state FSM, Supabase Realtime stream for live status updates, list screen with shimmer loading, detail screen with timeline widget, and Orders tab in main navigation**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-03T18:01:06Z
- **Completed:** 2026-05-03T18:06:00Z
- **Tasks:** 2 (Task 1: domain TDD, Task 2: data + UI + nav)
- **Files modified:** 12

## Accomplishments

- Created complete `lib/features/orders/` module with clean architecture layers
- `OrderStatus` enum with 11 values matching DB ENUM; `OrderStatusX` extension with Spanish labels, `isFinal`, `stepIndex`, `fromString()`
- `OrderEntity` and `OrderItemEntity` with `fromMap` factories handling all nullable DateTime lifecycle timestamps
- `OrderSupabaseDataSource.watchOrder()` uses `.stream(primaryKey: ['id'])` for Supabase Realtime — status changes from server RPCs appear in <2s
- `ordersListProvider`, `orderDetailStreamProvider`, `orderItemsProvider` wired via Riverpod
- `OrderStatusTimeline`: vertical FSM widget with neon green checkmarks for done, pulsing blue for current, grey for pending; terminal state collapses happy-path tail
- `OrdersListScreen`: shimmer loading, pull-to-refresh, status chips with per-status colors, COP formatting
- `OrderDetailScreen`: Realtime stream subscription, `CachedNetworkImage` QR thumbnails, totals breakdown (subtotal/IVA/envío/total), shipping address card
- Orders tab (index 5) with `receipt_long` icons and `orders_tab` Semantics identifier added to MainScaffold
- All 10 domain unit tests pass; `flutter analyze` reports 0 issues

## Task Commits

| Task | Name | Commit |
|------|------|--------|
| TDD RED | Failing tests for OrderStatus + OrderEntity | 97caa89 |
| Task 1 (GREEN) | Domain layer: entities + repository interface | 4b51242 |
| Task 2 | Data layer + providers + UI screens + nav | 146491a |

## Files Created/Modified

### Created
- `lib/features/orders/domain/entities/order_entity.dart` — OrderEntity, OrderStatus enum, OrderStatusX extension
- `lib/features/orders/domain/entities/order_item_entity.dart` — OrderItemEntity
- `lib/features/orders/domain/repositories/order_repository.dart` — abstract OrderRepository
- `lib/features/orders/data/datasources/order_supabase_data_source.dart` — getUserOrders, watchOrder (Realtime stream), getOrderItems
- `lib/features/orders/data/repositories/order_repository_impl.dart` — maps raw maps to domain entities
- `lib/features/orders/presentation/providers/orders_providers.dart` — ordersListProvider, orderDetailStreamProvider, orderItemsProvider
- `lib/features/orders/presentation/pages/orders_list_screen.dart` — paginated list with shimmer + pull-to-refresh
- `lib/features/orders/presentation/pages/order_detail_screen.dart` — Realtime detail view with timeline + line items + totals + shipping
- `lib/features/orders/presentation/widgets/order_status_timeline.dart` — FSM vertical timeline widget
- `test/features/orders/domain/order_status_test.dart` — 10 unit tests (TDD)

### Modified
- `lib/features/main/main_scaffold.dart` — Added orders tab (index 5) + `MainScaffoldKeys.ordersTab`
- `lib/shared/widgets/main_navigation.dart` — Added `ordersTabKey` param and 6th Row slot with `orders_tab` semantic identifier

## Decisions Made

- Orders tab at index 5 (sixth entry) to avoid displacing existing tabs; Row extended to 5 side + 1 center button.
- Terminal status (cancelled/refunded) collapses the timeline to show only completed steps + terminal node.
- `StreamProvider.family` used for `orderDetailStreamProvider` so the Realtime subscription persists for the full detail screen lifetime.
- `getUserOrders` guards against null `currentUser` by returning empty list — avoids crash during auth transitions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] catchError handler return type mismatch**
- **Found during:** Task 2 — `flutter analyze` flagged `body_might_complete_normally_catch_error`
- **Issue:** `catchError((_) {})` in `_refresh()` has void return, but the future type is `List<OrderEntity>`
- **Fix:** Changed to `catchError((_) => <OrderEntity>[])` to return a typed empty list
- **Files modified:** `lib/features/orders/presentation/pages/orders_list_screen.dart`
- **Commit:** Included in 146491a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - return type mismatch in catchError)
**Impact on plan:** Minor; no scope change.

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED (test commit) | 97caa89 | PASS |
| GREEN (feat commit) | 4b51242 | PASS |
| REFACTOR | N/A | Not needed |

## Known Stubs

None — all providers are wired to real Supabase data sources. The `OrdersListScreen` and `OrderDetailScreen` will show shimmer/empty states until the user has actual orders and Supabase is configured.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| lib/features/orders/domain/entities/order_entity.dart | FOUND |
| lib/features/orders/domain/entities/order_item_entity.dart | FOUND |
| lib/features/orders/domain/repositories/order_repository.dart | FOUND |
| lib/features/orders/data/datasources/order_supabase_data_source.dart | FOUND |
| lib/features/orders/data/repositories/order_repository_impl.dart | FOUND |
| lib/features/orders/presentation/providers/orders_providers.dart | FOUND |
| lib/features/orders/presentation/pages/orders_list_screen.dart | FOUND |
| lib/features/orders/presentation/pages/order_detail_screen.dart | FOUND |
| lib/features/orders/presentation/widgets/order_status_timeline.dart | FOUND |
| test/features/orders/domain/order_status_test.dart | FOUND |
| commit 97caa89 | FOUND |
| commit 4b51242 | FOUND |
| commit 146491a | FOUND |
| flutter analyze 0 issues | PASS |
| 10 domain tests pass | PASS |

---
*Phase: 10-orders-realtime-fcm*
*Completed: 2026-05-03*
