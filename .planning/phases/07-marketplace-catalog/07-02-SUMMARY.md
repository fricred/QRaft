---
phase: 07-marketplace-catalog
plan: "02"
subsystem: marketplace
tags: [flutter, riverpod, shimmer, flutter_animate, intl, catalog-ui]
dependency_graph:
  requires:
    - catalogProvider (FutureProvider<List<ProductVariantEntity>>) — from 07-01
    - activeMaterialFilterProvider (StateProvider<String>) — from 07-01
    - filteredCatalogProvider (derived Provider) — from 07-01
    - MaterialGradients.forCategory() — from product_entity.dart
  provides:
    - MaterialFilterBar (ConsumerWidget — horizontal scrollable material chips)
    - ProductVariantCard (StatelessWidget — glassmorphism variant card)
    - ProductVariantCardShimmer (StatelessWidget — skeleton loading card)
    - ProductDetailScreen (ConsumerWidget — variant detail with qrCodeId hook)
    - MarketplaceScreen (replaced — live Supabase catalog, no ComingSoonOverlay)
  affects:
    - Phase 7 plan 07-03 (MaterialPreviewWidget replaces qr_preview_placeholder in ProductDetailScreen)
    - Phase 7 plan 07-04 (wires qrCodeId into ProductDetailScreen)
    - Phase 8 (Cart — ProductDetailScreen CTA button is a placeholder snackbar)
tech_stack:
  added: []
  patterns:
    - filteredCatalogProvider.when() — AsyncValue loading/error/data in GridView
    - Shimmer.fromColors — loading skeleton for chips and grid cards
    - flutter_animate entrance (fadeIn + slideY) on ProductVariantCard
    - MaterialGradients.forCategory() as texture fallback (texture images are plan 07-03)
    - intl NumberFormat.currency(locale: 'es_CO') for COP prices
key_files:
  created:
    - lib/features/marketplace/presentation/widgets/material_filter_bar.dart
    - lib/features/marketplace/presentation/widgets/product_variant_card.dart
    - lib/features/marketplace/presentation/pages/product_detail_screen.dart
  modified:
    - lib/features/marketplace/marketplace_screen.dart
decisions:
  - "ProductDetailScreen accepts qrCodeId (optional String) — null in Phase 7; wired by plan 07-04"
  - "MaterialFilterBar derives chip list from catalogProvider (not hardcoded) — future materials appear automatically"
  - "Add-to-cart button shows snackbar placeholder — cart implementation is Phase 8 concern"
  - "qr_preview_placeholder Key('qr_preview_placeholder') placed as SizedBox.shrink inside Stack — plan 07-03 targets this anchor"
  - "Old product_details_screen.dart (ProductEntity-based) preserved untouched per plan spec"
metrics:
  duration: "~4 minutes"
  completed: "2026-05-03"
  tasks_completed: 2
  files_created: 3
  files_modified: 1
---

# Phase 7 Plan 02: Marketplace Catalog UI Summary

**One-liner:** MaterialFilterBar (live chips from catalogProvider + shimmer), ProductVariantCard (glassmorphism + COP price via intl), MarketplaceScreen replaced with filteredCatalogProvider grid, and ProductDetailScreen skeleton with qrCodeId hook and qraft.link info banner.

## What Was Built

### Task 1: MaterialFilterBar + ProductVariantCard widgets

**`lib/features/marketplace/presentation/widgets/material_filter_bar.dart`**
- `MaterialFilterBar extends ConsumerWidget` — horizontal `ListView` of animated chip widgets; "Todos" chip always first; remaining chips derived from unique materials in `catalogProvider` (not hardcoded).
- Selected chip: `Color(0xFF00FF88)` background with dark text. Unselected: `Color(0xFF2E2E2E)` with grey text.
- Tapping a material chip calls `ref.read(activeMaterialFilterProvider.notifier).state = material.id`; "Todos" sets to `''`.
- Loading state: `_ShimmerChipRow` — 4 placeholder containers via `Shimmer.fromColors`.
- Error state: `SizedBox.shrink()` (silent, catalog error shown in grid).

**`lib/features/marketplace/presentation/widgets/product_variant_card.dart`**
- `ProductVariantCard extends StatelessWidget` — dark glassmorphism card (`Color(0xFF2E2E2E)`, `BorderRadius.circular(16)`, white `withValues(alpha: 0.12)` border).
  - Top 96px container: `MaterialGradients.forCategory(variant.material.id)` gradient with material `displayNameEs` centered (texture images wired in plan 07-03).
  - Body: `productNameEs` (bold white), `sizeLabel` (grey[400] 12px).
  - Bottom row: COP price via `intl.NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)` in neon green, circular "+" button showing snackbar "Agregar al carrito próximamente".
  - `flutter_animate` entrance: `fadeIn(300ms) + slideY(begin: 0.1, 300ms)`.
- `ProductVariantCardShimmer extends StatelessWidget` — full shimmer skeleton matching card height ~200px with `Shimmer.fromColors`.

### Task 2: MarketplaceScreen replacement + ProductDetailScreen

**`lib/features/marketplace/marketplace_screen.dart`** — full replacement:
- `MarketplaceScreen extends ConsumerStatefulWidget` (was `StatefulWidget`).
- `ComingSoonOverlay` import and usage removed entirely.
- Body: Header row → featured promo banner (kept exactly) → `MaterialFilterBar()` → `Expanded(filteredCatalogProvider.when(...))`.
- Loading: 2-column grid of 6 `ProductVariantCardShimmer` items.
- Error: `Center(Text('Error al cargar catálogo'))`.
- Empty: `Center(Text('Sin productos para este material'))`.
- Data: `GridView.builder` with `childAspectRatio: 0.72`; tapping a card navigates to `ProductDetailScreen(variant: variants[i])`.
- `_showCartDialog()` method preserved; old product map methods and `PageController` removed.

**`lib/features/marketplace/presentation/pages/product_detail_screen.dart`** — new file:
- `ProductDetailScreen extends ConsumerWidget` with `required ProductVariantEntity variant` and `String? qrCodeId`.
- AppBar: transparent, white foreground, `productNameEs` title.
- `CustomScrollView` body:
  1. QR preview placeholder: 280px gradient `Container` with "Vista previa del QR" text. `SizedBox.shrink(key: Key('qr_preview_placeholder'))` inside `Stack` as anchor for plan 07-03.
  2. Material/size/dimension info chips (`_InfoChip` widget).
  3. COP price in `Color(0xFF00FF88)` 28px bold.
  4. Optional `productDescriptionEs` in grey[400].
  5. qraft.link info banner: `Color(0xFF2E2E2E)` container with `Icons.info_outline_rounded` prefix and informational text.
  6. `PrimaryGlassButton('Agregar al carrito')` showing snackbar (Phase 8 placeholder).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

**QR preview placeholder in ProductDetailScreen.** The gradient container at the top of `ProductDetailScreen` is a placeholder — plan 07-03 (`MaterialPreviewWidget`) will replace it. The `Key('qr_preview_placeholder')` anchor is in place.

**Material texture thumbnails show gradient fallback.** `MaterialGradients.forCategory()` is used instead of real texture images for all variant cards and the detail screen header — texture images require the Supabase storage step documented in plan 07-01 SUMMARY, and are rendered by plan 07-03.

**"Agregar al carrito" shows snackbar.** Both `ProductVariantCard` add button and `ProductDetailScreen` CTA show a "próximamente" snackbar. Real cart functionality is Phase 8.

## Threat Flags

None. All surfaces in this plan are covered by the plan's own threat model (T-07-05 through T-07-07). No new network endpoints, auth paths, or trust-boundary changes introduced. `filteredCatalogProvider` is client-side in-memory filter over read-only public catalog data.

## Self-Check: PASSED

Files exist:
- FOUND: lib/features/marketplace/presentation/widgets/material_filter_bar.dart
- FOUND: lib/features/marketplace/presentation/widgets/product_variant_card.dart
- FOUND: lib/features/marketplace/presentation/pages/product_detail_screen.dart
- FOUND: lib/features/marketplace/marketplace_screen.dart (modified)
- FOUND: lib/features/marketplace/presentation/pages/product_details_screen.dart (old file preserved)

Commits exist:
- FOUND: 97f4909 (MaterialFilterBar + ProductVariantCard widgets)
- FOUND: 79c9d4a (MarketplaceScreen replacement + ProductDetailScreen)

Verification:
- flutter analyze lib/features/marketplace/: 0 issues
- ComingSoonOverlay not in marketplace_screen.dart: confirmed
- filteredCatalogProvider in marketplace_screen.dart: confirmed
- qrCodeId parameter in product_detail_screen.dart: confirmed
- product_details_screen.dart (old, ProductEntity-based): preserved
