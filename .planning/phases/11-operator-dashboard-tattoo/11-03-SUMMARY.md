---
phase: 11-operator-dashboard-tattoo
plan: 03
subsystem: operator-auth
tags: [flutter, supabase, operator, rls, service-role, security, riverpod]

# Dependency graph
requires:
  - phase: 11-operator-dashboard-tattoo/11-01
    provides: OperatorOrdersScreen, OperatorSupabaseDatasource, operator_providers.dart

provides:
  - operator_profiles table with RLS (service_role-only management)
  - is_operator() SECURITY DEFINER function
  - RLS policies granting operator SELECT on orders/order_items/shipments
  - SupabaseService.operatorClient: service_role secondary Supabase client
  - OperatorLoginScreen: dedicated operator email+password login
  - isOperatorProvider: FutureProvider<bool> for route guard
  - ProfileScreen operator section: visible only to operator users

affects:
  - lib/features/operator/data/datasources/operator_supabase_datasource.dart: uses operatorClient
  - lib/features/operator/presentation/providers/operator_providers.dart: isOperatorProvider added
  - lib/features/profile/presentation/pages/profile_screen.dart: operator section wired in
  - lib/core/services/supabase_service.dart: operatorClient getter added

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Secondary SupabaseClient pattern using service_role key (separate from anon client)
    - String.fromEnvironment for build-time secret injection (never runtime)
    - SECURITY DEFINER function pattern for cross-RLS queries
    - StateError fail-loud pattern for misconfigured operator builds

key-files:
  created:
    - supabase/migrations/20260511000001_operator_role_rls.sql
    - lib/features/auth/presentation/pages/operator_login_screen.dart
  modified:
    - lib/core/services/supabase_service.dart
    - lib/features/operator/data/datasources/operator_supabase_datasource.dart
    - lib/features/operator/presentation/providers/operator_providers.dart
    - lib/features/profile/presentation/pages/profile_screen.dart

key-decisions:
  - "operatorClient throws StateError when OPERATOR_SERVICE_ROLE_KEY absent — consumer builds fail loudly not silently (T-11-09)"
  - "OperatorLoginScreen performs post-auth is_operator() check and signs out immediately if user is not operator — defense in depth beyond route guard"
  - "isOperatorProvider returns false on any error (StateError, network, RPC) — safe default for route guard (T-11-10)"
  - "ProfileScreen operator section uses isOperatorProvider.when — renders SizedBox.shrink() for non-operator and loading states (invisible to consumer)"
  - "Checkpoint auto-approved in autonomous mode per orchestrator instructions"

requirements-completed:
  - MKT-11

# Metrics
duration: 7min
completed: 2026-05-03
---

# Phase 11 Plan 03: Operator RLS + Auth Guard Summary

**Operator role security: Supabase migration with operator_profiles + is_operator() function + 3 RLS policies; secondary service_role Supabase client; OperatorLoginScreen with post-auth role check; isOperatorProvider route guard; ProfileScreen operator section hidden from consumers.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-03T18:48:00Z
- **Completed:** 2026-05-03T18:55:00Z
- **Tasks:** 1 auto task + 1 auto-approved checkpoint
- **Files created:** 2
- **Files modified:** 4

## Accomplishments

### Task 1: Operator RLS migration + service_role client + route guard

- `supabase/migrations/20260511000001_operator_role_rls.sql`:
  - `operator_profiles` table (user_id PK FK auth.users, granted_at, granted_by)
  - RLS: `FOR ALL USING (false) WITH CHECK (false)` — service_role manages only
  - `is_operator()`: SECURITY DEFINER STABLE SQL function reading operator_profiles for auth.uid()
  - `operator_read_all_orders` policy: SELECT on orders WHERE is_operator()
  - `operator_read_all_order_items` policy: SELECT on order_items WHERE is_operator()
  - Shipments policy in DO block (gracefully skips if table not yet created)

- `SupabaseService.operatorClient`:
  - Lazy-initialized secondary SupabaseClient using OPERATOR_SERVICE_ROLE_KEY
  - Delivered via `--dart-define-from-file=env.json` (gitignored)
  - Throws StateError with descriptive message when key absent

- `OperatorSupabaseDatasource`:
  - Removed SupabaseClient constructor arg
  - All 3 methods (fetchOrdersByStatuses, transitionOrder, fetchOrderDetail) use `_client` getter → `SupabaseService.operatorClient`
  - 9/9 existing tests still pass (datasource mocked in tests)

- `operator_providers.dart`:
  - `operatorDatasourceProvider`: uses `const OperatorSupabaseDatasource()` (no client arg)
  - `isOperatorProvider`: `FutureProvider<bool>` calling `is_operator()` RPC; returns false on any exception

- `OperatorLoginScreen`:
  - Email + password only (no social auth)
  - Post-auth is_operator() RPC check
  - Signs out immediately if check fails ("Acceso denegado" message)
  - Security notice footer ("Intentos no autorizados son registrados")
  - Route: accessed via Navigator.push from ProfileScreen

- `ProfileScreen._buildOperatorSection`:
  - Watches `isOperatorProvider`
  - Renders `SizedBox.shrink()` for loading/error/non-operator states
  - Shows blue-accent "Panel de Operador" tile only to operator users
  - Semantics key: `profile_operator_dashboard_tile`
  - Navigator.push to OperatorOrdersScreen

## Task Commits

1. **feat(11-03): operator RLS migration, service_role client, login screen, route guard** — `c6aaa6a`

## Verification Results

- `flutter analyze lib/features/operator/ lib/core/services/ lib/features/auth/ lib/features/profile/` — **0 issues**
- `flutter test test/features/operator/` — **9/9 pass**
- `operatorClient` count in datasource: 4 (getter + 3 queries)
- Migration file: FOUND with operator_profiles + is_operator() + 3 policies

## Deviations from Plan

**1. [Auto-approved checkpoint] Checkpoint:human-verify skipped in autonomous mode**
- The plan's `checkpoint:human-verify` gate (migration apply + env.json key + operator user insert) was auto-approved per orchestrator's autonomous mode instructions.
- Human operators must manually apply the migration and configure env.json before running the operator dashboard — documented in migration SQL comments.

## Known Stubs

None — all connections are wired. The operator dashboard remains non-functional until:
1. Migration `20260511000001_operator_role_rls.sql` is applied to the remote DB
2. `OPERATOR_SERVICE_ROLE_KEY` is added to `env.json`
3. An operator user is created via Supabase Dashboard → Auth → Invite User
4. That user's `auth.uid()` is inserted into `operator_profiles`

These are operational setup steps, not code stubs.

## Threat Flags

All threat model items implemented as planned:
- T-11-09: OPERATOR_SERVICE_ROLE_KEY via --dart-define-from-file (gitignored); StateError if absent
- T-11-10: isOperatorProvider returns false on error; ProfileScreen hides operator tile; OperatorLoginScreen signs out non-operators
- T-11-11: is_operator() SECURITY DEFINER — auth.uid() from Postgres session context, cannot be spoofed
- T-11-12: operator_profiles RLS `FOR ALL USING (false)` — consumer reads blocked

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| supabase/migrations/20260511000001_operator_role_rls.sql | FOUND |
| lib/features/auth/presentation/pages/operator_login_screen.dart | FOUND |
| SupabaseService.operatorClient getter | FOUND |
| isOperatorProvider in operator_providers.dart | FOUND |
| profile_operator_dashboard_tile | FOUND |
| commit c6aaa6a | FOUND |
| flutter analyze 0 issues | CONFIRMED |
| 9/9 operator tests passing | CONFIRMED |

---
*Phase: 11-operator-dashboard-tattoo*
*Plan: LAST — Phase 11 COMPLETE*
*Completed: 2026-05-03*
