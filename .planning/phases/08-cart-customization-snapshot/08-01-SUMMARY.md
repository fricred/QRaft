---
phase: 08-cart-customization-snapshot
plan: "01"
subsystem: database
tags: [supabase, postgres, rls, rpc, riverpod, cart, flutter, dart]

requires:
  - phase: 07-marketplace-catalog
    provides: product_variants table + ProductVariantEntity with price_cop

provides:
  - cart_items Supabase table with RLS (SELECT/INSERT/UPDATE/DELETE scoped to user_id = auth.uid())
  - server_compute_order_totals() Postgres RPC (IVA 19% + flat 15000 COP envio, SECURITY DEFINER)
  - CartItemEntity domain model with fromJson/toJson round-trip
  - CartTotalsEntity with zero sentinel + fromRpcRow factory
  - CartRepository abstract interface (5 CRUD + computeTotals)
  - CartRepositoryImpl (Supabase-backed, quantity cap 1..99, PostgrestException → CartException)
  - CartSupabaseDataSource (watchCart stream + upsert + computeTotals RPC)
  - cartItemsProvider (StreamProvider) + cartTotalsProvider (FutureProvider)
  - QRCustomization.toJson()/fromJson() for JSONB snapshot serialization

affects:
  - 08-02 (cart UI screen consumes cartItemsProvider + cartTotalsProvider)
  - 08-03 (QR snapshot upload uses QRCustomization.toJson() as JSONB payload)
  - 08-04 (add-to-cart CTA calls CartRepository.addItem())
  - 09-checkout (computeTotals RPC is the server-authoritative total for Wompi)

tech-stack:
  added: []
  patterns:
    - "CartException wraps PostgrestException with stable code/message contract"
    - "quantity clamped 1..99 client-side (T-08-01-02); Postgres CHECK >0 is second layer"
    - "CartTotalsEntity.zero sentinel avoids null-checks in UI"
    - "watchCart uses Supabase stream API (.stream(primaryKey) + .eq + .order)"
    - "computeTotals calls RPC via Supabase.instance.client.rpc()"
    - "QRCustomization.fromJson falls back GradientType.solid for unknown enum values"

key-files:
  created:
    - supabase/migrations/20260504000000_cart_items_and_compute_totals.sql
    - lib/features/cart/domain/entities/cart_item_entity.dart
    - lib/features/cart/domain/entities/cart_totals_entity.dart
    - lib/features/cart/domain/repositories/cart_repository.dart
    - lib/features/cart/data/models/cart_item_model.dart
    - lib/features/cart/data/datasources/cart_supabase_data_source.dart
    - lib/features/cart/data/repositories/cart_repository_impl.dart
    - lib/features/cart/presentation/providers/cart_providers.dart
    - test/features/cart/domain/cart_entities_test.dart
  modified:
    - lib/features/qr_generator/domain/entities/qr_code_entity.dart

key-decisions:
  - "Migration requires manual application via Supabase Dashboard → SQL Editor (same pattern as plan 04-01 redirects)"
  - "price_cop stays in whole COP pesos in cart_items; Wompi ×100 conversion deferred to Phase 9 create_payment_intent Edge Function"
  - "cartItemsProvider returns Stream.empty() for unauthenticated users (not error) so StreamProvider yields AsyncValue.data([]) not AsyncValue.error"
  - "cartTotalsProvider short-circuits to CartTotalsEntity.zero on empty cart to avoid unnecessary RPC round-trip"
  - "QRCustomization.fromJson uses .firstWhere orElse for GradientType resolution — forward-compatible with future enum additions"

requirements-completed:
  - MKT-03
  - MKT-12

duration: 5min
completed: 2026-05-03
---

# Phase 8 Plan 01: Cart & Customization Snapshot Summary

**Supabase cart_items table + RLS + server_compute_order_totals() RPC + Dart cart domain/data/providers + QRCustomization JSON serialization**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-03T14:26:23Z
- **Completed:** 2026-05-03T14:31:00Z
- **Tasks:** 2
- **Files modified:** 10 (9 created, 1 modified)

## Accomplishments

- Supabase migration creates `cart_items` table with 4 RLS policies (all scoped to `user_id = auth.uid()`) and `server_compute_order_totals()` SECURITY DEFINER RPC computing IVA 19% + flat 15,000 COP envio
- Complete Dart cart feature skeleton: entities → repository interface → Supabase datasource → repository impl → Riverpod providers; Plans 02–04 can depend on this immediately
- `QRCustomization.toJson()`/`fromJson()` added to enable freezing customization as JSONB snapshot in cart_items and order_items (Anti-Pattern 2 + Pattern 1 from ARCHITECTURE.md)

## Task Commits

1. **Task 1: Supabase migration** — `b25d5f7` (feat)
2. **Task 2: Cart domain/data/providers + QRCustomization serialization** — `3da36fb` (feat)

## Files Created/Modified

- `supabase/migrations/20260504000000_cart_items_and_compute_totals.sql` — cart_items DDL + 4 RLS policies + server_compute_order_totals() RPC
- `lib/features/cart/domain/entities/cart_item_entity.dart` — CartItemEntity with fromJson/toJson + Equatable
- `lib/features/cart/domain/entities/cart_totals_entity.dart` — CartTotalsEntity with zero sentinel + fromRpcRow
- `lib/features/cart/domain/repositories/cart_repository.dart` — abstract CartRepository (5 CRUD methods + computeTotals)
- `lib/features/cart/data/models/cart_item_model.dart` — CartItemModel extends CartItemEntity; fromSupabaseRow
- `lib/features/cart/data/datasources/cart_supabase_data_source.dart` — watchCart stream + upsert + computeTotals RPC
- `lib/features/cart/data/repositories/cart_repository_impl.dart` — CartRepositoryImpl + CartException; quantity clamp 1..99
- `lib/features/cart/presentation/providers/cart_providers.dart` — cartRepositoryProvider + cartItemsProvider + cartTotalsProvider
- `lib/features/qr_generator/domain/entities/qr_code_entity.dart` — QRCustomization.toJson() + QRCustomization.fromJson()
- `test/features/cart/domain/cart_entities_test.dart` — 9 unit tests (entities, model, totals, JSON serialization)

## Decisions Made

- Migration requires **manual application** via Supabase Dashboard SQL Editor — same pattern established in plan 04-01 for redirects; CLI not configured for this project.
- `price_cop` in `cart_items` reflects whole COP pesos (not centavos). The Wompi ×100 multiplication happens at checkout (Phase 9) in the `create_payment_intent` Edge Function — documented in migration SQL comment.
- `cartItemsProvider` returns `Stream.empty()` for unauthenticated users so the `StreamProvider` yields `AsyncValue.data([])` rather than an error state — cleaner null handling downstream.
- `cartTotalsProvider` short-circuits to `CartTotalsEntity.zero` when cart is empty, avoiding an unnecessary RPC round-trip.
- `QRCustomization.fromJson` uses `.firstWhere(orElse: () => GradientType.solid)` for GradientType resolution — forward-compatible if future plans add new gradient types without breaking existing snapshots.

## Deviations from Plan

**1. [Rule 1 - Bug] Removed unnecessary cast in CartSupabaseDataSource**
- **Found during:** Task 2 (flutter analyze check)
- **Issue:** `row as Map<String, dynamic>` was redundant; Supabase stream returns typed `List<Map<String, dynamic>>`
- **Fix:** Removed the cast
- **Files modified:** `lib/features/cart/data/datasources/cart_supabase_data_source.dart`
- **Verification:** `flutter analyze` 0 issues on lib/features/cart/
- **Committed in:** `3da36fb` (part of task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - unnecessary cast)
**Impact on plan:** Trivial lint fix, no behavior change.

## Issues Encountered

- Plan verification check specified `grep -c "user_id = auth.uid()"` but RLS policies were initially written with `auth.uid() = user_id` (equivalent SQL). Updated to match the grep check format exactly.

## User Setup Required

**Manual Supabase step required before Phase 8 Plans 02–04:**

Apply migration `supabase/migrations/20260504000000_cart_items_and_compute_totals.sql` via:
1. Supabase Dashboard → SQL Editor
2. Paste full migration content
3. Execute

Verify: `SELECT COUNT(*) FROM cart_items;` returns 0 (empty table, schema created).

## Next Phase Readiness

- **Plan 08-02** (Cart UI screen): `cartItemsProvider` + `cartTotalsProvider` ready; `CartRepository.addItem/removeItem/updateQuantity` all implemented
- **Plan 08-03** (QR snapshot PNG upload): `QRCustomization.toJson()` ready; PNG URL stored in `cart_items.png_storage_url`
- **Plan 08-04** (Add-to-cart CTA): `CartRepository.addItem()` with upsert semantics; `customizationSnapshot` parameter accepts `QRCustomization.toJson()` output

## Threat Surface Scan

No new network endpoints introduced in Dart layer beyond what was planned. The `server_compute_order_totals` RPC is the only new server-side surface — its SECURITY DEFINER + p_user_id guard is documented in the migration and in the plan's threat register (T-08-01-04).

---

## Self-Check: PASSED

Files verified:
- `supabase/migrations/20260504000000_cart_items_and_compute_totals.sql` — FOUND
- `lib/features/cart/domain/entities/cart_item_entity.dart` — FOUND
- `lib/features/cart/domain/entities/cart_totals_entity.dart` — FOUND
- `lib/features/cart/domain/repositories/cart_repository.dart` — FOUND
- `lib/features/cart/data/models/cart_item_model.dart` — FOUND
- `lib/features/cart/data/datasources/cart_supabase_data_source.dart` — FOUND
- `lib/features/cart/data/repositories/cart_repository_impl.dart` — FOUND
- `lib/features/cart/presentation/providers/cart_providers.dart` — FOUND
- `test/features/cart/domain/cart_entities_test.dart` — FOUND
- `lib/features/qr_generator/domain/entities/qr_code_entity.dart` — FOUND (modified)

Commits verified:
- `b25d5f7` — Task 1: migration
- `3da36fb` — Task 2: cart domain/data/providers

Tests: 9/9 passing
flutter analyze lib/features/cart/ + qr_code_entity.dart: 0 issues

---
*Phase: 08-cart-customization-snapshot*
*Completed: 2026-05-03*
