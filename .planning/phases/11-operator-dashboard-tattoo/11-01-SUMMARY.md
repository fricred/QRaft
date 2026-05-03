---
phase: 11-operator-dashboard-tattoo
plan: 01
subsystem: operator-dashboard
tags: [flutter-web, operator, riverpod, supabase-rpc, fsm, sla-alerting, tdd]

# Dependency graph
requires:
  - phase: 10-orders-realtime-fcm/10-04
    provides: transition_order RPC (GRANT EXECUTE service_role only)
  - phase: 10-orders-realtime-fcm/10-02
    provides: OrderEntity + OrderItemEntity + OrderStatus enum

provides:
  - OperatorOrdersScreen: 4-tab order queue with stale-order flagging
  - OperatorOrderDetailScreen: full order detail + status action bar
  - operatorOrdersProvider: FutureProvider.family for queue by status list
  - transitionOrderStateProvider: StateNotifier for FSM transition async state
  - OperatorOrderRow: lightweight DTO with client-side isStale computation
  - kValidTransitions: FSM transition map (operator-facing edges only)

affects:
  - 11-03-operator-auth: will swap operatorDatasourceProvider to service_role client
  - app router: must add /operator route guarded by operator auth (plan 11-03)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - FutureProvider.family keyed on List<String> statuses for tab-filtered queue
    - Client-side SLA staleness computation via kSlaThresholds map at OperatorOrderRow.fromMap
    - StateNotifier + invalidate pattern for post-transition cache invalidation
    - TDD: RED (test(11-01) commit a46ea48) then GREEN (feat(11-01) commit 7c556a7)

key-files:
  created:
    - lib/features/operator/domain/entities/operator_order_row.dart
    - lib/features/operator/domain/repositories/operator_repository.dart
    - lib/features/operator/data/datasources/operator_supabase_datasource.dart
    - lib/features/operator/data/repositories/operator_repository_impl.dart
    - lib/features/operator/presentation/providers/operator_providers.dart
    - lib/features/operator/presentation/pages/operator_orders_screen.dart
    - lib/features/operator/presentation/pages/operator_order_detail_screen.dart
    - lib/features/operator/presentation/widgets/operator_order_card.dart
    - lib/features/operator/presentation/widgets/operator_status_action_bar.dart
    - test/features/operator/operator_repository_test.dart
  modified: []

key-decisions:
  - "OperatorOrderRow is a lightweight DTO separate from OrderEntity — avoids over-fetching full entity fields in queue list; detail screen uses raw map from fetchOrderDetail"
  - "isStale computed client-side in OperatorOrderRow.fromMap against kSlaThresholds — avoids DB function overhead for low-volume operator traffic (T-11-04 accepted)"
  - "Standard Supabase client used for now (plan 11-03 will swap to service_role); documented in both datasource and providers with explicit TODO"
  - "kValidTransitions const map in action bar encodes operator-facing FSM edges only — payment transitions belong to Wompi webhook"
  - "FutureProvider.family(List<String>) used for tab statuses — invalidated by TransitionOrderNotifier after each successful RPC call"
  - "Web build confirmed successful (flutter build web --no-pub) validating cross-platform compatibility of all new widgets"

requirements-completed:
  - MKT-11

# Metrics
duration: 7min
completed: 2026-05-03
---

# Phase 11 Plan 01: Operator Order Queue + Detail Screen Summary

**Operator dashboard Flutter Web screens: 4-tab order queue with SLA stale-alerting + order detail with FSM transition action bar calling transition_order RPC via Riverpod StateNotifier**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-03T18:30:18Z
- **Completed:** 2026-05-03T18:36:53Z
- **Tasks:** 2 auto tasks (TDD for Task 1)
- **Files created:** 10

## TDD Gate Compliance

- **RED commit:** `a46ea48` — `test(11-01): add failing tests for operator data layer (RED)` — tests failed as expected (missing implementation)
- **GREEN commit:** `7c556a7` — `feat(11-01): operator data layer — OperatorOrderRow + repository + providers` — 9/9 tests pass
- **REFACTOR:** Not needed — code was clean on first pass after analyzer fixes

## Accomplishments

### Task 1: Operator data layer + providers (TDD)

- `OperatorOrderRow` — lightweight DTO with `isStale` computed client-side against `kSlaThresholds`:
  - `paid` > 1h = stale
  - `received_by_ops` > 4h = stale
  - `engraving` > 24h = stale
  - `engraving_done` > 4h = stale
- `OperatorSupabaseDatasource` — `fetchOrdersByStatuses` (joined with `order_items(qr_png_url)`), `transitionOrder` (calls `transition_order` RPC), `fetchOrderDetail`
- `OperatorRepositoryImpl` — wraps `PostgrestException` as `OperatorException`
- `operator_providers.dart`:
  - `operatorOrdersProvider` — `FutureProvider.family<List<OperatorOrderRow>, List<String>>`
  - `transitionOrderStateProvider` — `StateNotifierProvider<TransitionOrderNotifier, TransitionOrderState>` with `performTransition` + queue invalidation
  - `operatorOrderDetailProvider` — `FutureProvider.family<Map<String, dynamic>?, String>`
- 9/9 unit tests pass (6 stale-flag, 3 transition tests)

### Task 2: Operator screens + widgets

- `OperatorOrdersScreen` — 4 tabs: Por atender (paid), En proceso (received_by_ops/engraving), Listos/Enviados (engraving_done/shipped), Todos; each tab has pull-to-refresh, empty state, error state with retry
- `OperatorOrderDetailScreen` — customer info section, itemized list with CachedNetworkImage QR PNG thumbnails, price breakdown (subtotal/IVA/shipping/total COP), pinned action bar
- `OperatorOrderCard` — order number + stale flag (Icons.flag red), recipient+city, COP total (formatted with dots), time-ago, status chip
- `OperatorStatusActionBar` — derives next-state buttons from `kValidTransitions` const map; each `GlassButton` keyed as `operator_transition_btn_{newStatus}`; loading overlay blocks re-press; SnackBar on error; `onSuccess` callback pops screen

## Task Commits

1. **RED: failing tests** — `a46ea48`
2. **GREEN: operator data layer** — `7c556a7`
3. **feat: operator screens + widgets** — `4ff784a`

## Verification Results

- `flutter analyze lib/features/operator/` — **0 issues**
- `flutter test test/features/operator/` — **9/9 pass**
- `flutter build web --no-pub` — **succeeded** (✓ Built build/web)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Analyzer: unnecessary_cast in fetchOrderDetail return**
- **Found during:** Task 1 (post-implementation analyze pass)
- **Issue:** `maybeSingle()` already returns `Map<String, dynamic>?`; explicit cast `as Map<String, dynamic>?` triggered `unnecessary_cast` warning
- **Fix:** Removed redundant cast
- **Files modified:** `lib/features/operator/data/datasources/operator_supabase_datasource.dart`

**2. [Rule 1 - Bug] Analyzer: unnecessary_import in providers and repository_impl**
- **Found during:** Task 1 (post-implementation analyze pass)
- **Issue:** Redundant imports of `operator_order_row.dart` (already transitively exported by repository)
- **Fix:** Removed redundant imports; moved export directives before class declarations per Dart language requirement (`directive_after_declaration` error)
- **Files modified:** `lib/features/operator/presentation/providers/operator_providers.dart`, `lib/features/operator/data/repositories/operator_repository_impl.dart`

## Known Stubs

**Service_role client** — `operatorDatasourceProvider` currently uses the standard authenticated Supabase client. Plan 11-03 will swap this to a service_role client to:
1. Bypass user-scoped RLS on `orders` (operators must see all users' orders)
2. Execute `transition_order` RPC (GRANT EXECUTE only to service_role)

Until plan 11-03, the operator screen will only show orders belonging to the authenticated operator user (RLS enforced). This is intentional and documented in both `operator_supabase_datasource.dart` and `operator_providers.dart`.

## Threat Flags

No new threat surface beyond the plan's threat model (T-11-01 through T-11-04). All implemented mitigations:
- T-11-03: `kValidTransitions` const map restricts UI to valid next-state buttons; `transition_order` RPC enforces FSM server-side independently
- T-11-04: `isStale` computed client-side (no DB scan); `idx_orders_ops_queue` index from Phase 9 covers queue queries

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| lib/features/operator/domain/entities/operator_order_row.dart | FOUND |
| lib/features/operator/domain/repositories/operator_repository.dart | FOUND |
| lib/features/operator/data/datasources/operator_supabase_datasource.dart | FOUND |
| lib/features/operator/data/repositories/operator_repository_impl.dart | FOUND |
| lib/features/operator/presentation/providers/operator_providers.dart | FOUND |
| lib/features/operator/presentation/pages/operator_orders_screen.dart | FOUND |
| lib/features/operator/presentation/pages/operator_order_detail_screen.dart | FOUND |
| lib/features/operator/presentation/widgets/operator_order_card.dart | FOUND |
| lib/features/operator/presentation/widgets/operator_status_action_bar.dart | FOUND |
| test/features/operator/operator_repository_test.dart | FOUND |
| RED commit a46ea48 | FOUND |
| GREEN commit 7c556a7 | FOUND |
| Screens commit 4ff784a | FOUND |
| flutter analyze 0 issues | CONFIRMED |
| 9/9 tests passing | CONFIRMED |
| flutter build web success | CONFIRMED |

---
*Phase: 11-operator-dashboard-tattoo*
*Completed: 2026-05-03*
