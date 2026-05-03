---
phase: 07-marketplace-catalog
plan: "01"
subsystem: marketplace
tags: [supabase, schema, riverpod, domain-entities, catalog]
dependency_graph:
  requires: []
  provides:
    - catalogProvider (FutureProvider<List<ProductVariantEntity>>)
    - activeMaterialFilterProvider (StateProvider<String>)
    - filteredCatalogProvider (derived, client-side)
    - productRepositoryProvider (Provider<ProductRepository>)
  affects:
    - Phase 8 (Cart & Customization Snapshot — reads catalogProvider)
    - Phase 9 (Checkout — uses priceCop × 100 for Wompi amountInCents)
tech_stack:
  added:
    - supabase/migrations/20260501000000_marketplace_catalog.sql (DDL + seed)
  patterns:
    - Nested SELECT via Supabase PostgREST (product_variants JOIN products + materials)
    - Denormalized read (single query — no N+1)
    - Repository pattern (abstract interface + impl)
    - Equatable value objects for domain entities
key_files:
  created:
    - supabase/migrations/20260501000000_marketplace_catalog.sql
    - lib/features/marketplace/domain/entities/material_entity.dart
    - lib/features/marketplace/domain/entities/product_variant_entity.dart
    - lib/features/marketplace/domain/repositories/product_repository.dart
    - lib/features/marketplace/data/models/material_model.dart
    - lib/features/marketplace/data/models/product_variant_model.dart
    - lib/features/marketplace/data/datasources/product_supabase_data_source.dart
    - lib/features/marketplace/data/repositories/product_repository_impl.dart
    - lib/features/marketplace/presentation/providers/marketplace_providers.dart
  modified: []
decisions:
  - "price_cop stored as INT (whole COP pesos) — Wompi multiply ×100 at checkout (Phase 9)"
  - "texture_url defaults to empty string — caller must guard before loading image"
  - "materials.id is TEXT PK ('wood','acrylic',etc) not UUID — stable FK reference"
  - "product_variants JOIN products + materials via nested SELECT (single query)"
  - "texture_url validated to https:// only in MaterialModel.fromJson (T-07-02 mitigated)"
  - "catalogProvider uses autoDispose to clear cache when no listeners remain"
metrics:
  duration: "~3 minutes"
  completed: "2026-05-03"
  tasks_completed: 2
  files_created: 9
  files_modified: 0
---

# Phase 7 Plan 01: Marketplace Catalog Schema + Data Layer Summary

**One-liner:** Supabase DDL with 3 tables (materials/products/product_variants), public-read RLS, 6-material + 2-product + 12-variant seed, full Dart domain/data layer with `int priceCop` and `catalogProvider` Riverpod providers.

## What Was Built

### Task 1: Supabase Migration
`supabase/migrations/20260501000000_marketplace_catalog.sql` — 94 lines of SQL:
- `materials` table (TEXT PK, 6 material rows seeded)
- `products` table (UUID PK, is_active flag, 2 products seeded)
- `product_variants` table (UUID PK, FK to both, `price_cop INT` not cents, 12 variants seeded)
- 3 RLS policies: public SELECT only (no INSERT/UPDATE/DELETE surface for any role)
- Price semantics documented in SQL comments: whole COP pesos; Wompi ×100 at Phase 9

**Apply manually** via Supabase Dashboard → SQL Editor (copy-paste entire file).

### Task 2: Dart Domain/Data/Provider Stack
8 new files, 0 existing files modified:

| Layer | File | Purpose |
|-------|------|---------|
| Domain entity | `material_entity.dart` | Equatable value object; `textureUrl` may be empty |
| Domain entity | `product_variant_entity.dart` | `int priceCop` — never double |
| Domain interface | `product_repository.dart` | `getActiveCatalog()` abstract |
| Data model | `material_model.dart` | `fromJson` + `toEntity()`; https-only URL guard |
| Data model | `product_variant_model.dart` | Reads nested `product` + `material` keys from PostgREST |
| Data source | `product_supabase_data_source.dart` | Single denormalized JOIN query |
| Data repo | `product_repository_impl.dart` | Maps models → entities |
| Providers | `marketplace_providers.dart` | `catalogProvider`, `activeMaterialFilterProvider`, `filteredCatalogProvider` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Security] T-07-02: texture_url https-only validation added to MaterialModel.fromJson**
- **Found during:** Task 2 — threat model review before SUMMARY
- **Issue:** Plan's threat register marks T-07-02 as `mitigate`; `MaterialModel.fromJson` was passing `texture_url` raw from DB without validation
- **Fix:** Added `https://`-only check in `fromJson`; empty string allowed (legitimate "not uploaded yet" state); non-https non-empty values sanitized to empty string (fail-safe)
- **Files modified:** `lib/features/marketplace/data/models/material_model.dart`
- **Commit:** `bbace05`

## Known Stubs

**texture_url is empty string for all 6 seeded materials.** The migration seeds `texture_url = ''` because PNGs have not been uploaded yet.

Manual step required before Phase 8 UI can render material textures:
1. Go to Supabase Dashboard → Storage → Create bucket `material-textures` (public)
2. Upload `wood.png`, `acrylic.png`, `metal.png`, `leather.png`, `glass.png`, `stone.png`
3. Run SQL update to populate `texture_url`:
   ```sql
   UPDATE materials SET texture_url = 'https://<project>.supabase.co/storage/v1/object/public/material-textures/<id>.png';
   ```

Phase 8 UI should guard `textureUrl.isEmpty` and show `MaterialGradients.forCategory(material.id)` as fallback (already defined in existing `product_entity.dart`).

## Threat Flags

None. All surfaces in this plan are covered by the plan's own threat model (T-07-01 through T-07-04). T-07-01 (no-write RLS) applied in migration. T-07-02 (texture_url validation) applied as deviation. T-07-03 and T-07-04 accepted.

## Self-Check: PASSED

Files exist:
- FOUND: supabase/migrations/20260501000000_marketplace_catalog.sql
- FOUND: lib/features/marketplace/domain/entities/material_entity.dart
- FOUND: lib/features/marketplace/domain/entities/product_variant_entity.dart
- FOUND: lib/features/marketplace/domain/repositories/product_repository.dart
- FOUND: lib/features/marketplace/data/models/material_model.dart
- FOUND: lib/features/marketplace/data/models/product_variant_model.dart
- FOUND: lib/features/marketplace/data/datasources/product_supabase_data_source.dart
- FOUND: lib/features/marketplace/data/repositories/product_repository_impl.dart
- FOUND: lib/features/marketplace/presentation/providers/marketplace_providers.dart

Commits exist:
- FOUND: 5fce44c (migration SQL)
- FOUND: 92435e2 (Dart data/domain stack)
- FOUND: bbace05 (T-07-02 security fix)

flutter analyze lib/features/marketplace/: 0 issues
priceCop is `int` in both entity and model (verified grep)
No existing files modified (product_entity.dart, marketplace_screen.dart, product_details_screen.dart unchanged)
