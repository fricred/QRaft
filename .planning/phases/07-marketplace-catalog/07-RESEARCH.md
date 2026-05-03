# Phase 7: Marketplace Catalog + QR Export Pipeline - Research

**Researched:** 2026-05-01
**Domain:** Flutter marketplace UI, Supabase catalog schema, QR-on-material preview compositing, QrExportService integration
**Confidence:** HIGH (codebase verified via direct file reads; architecture from ARCHITECTURE.md which cites official docs)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MKT-01 | Browse catalog by material × size × price with filters and previews | `products`, `product_variants`, `materials` tables; `FutureProvider` for catalog; existing `MarketplaceScreen` stub to replace |
| MKT-02 | Live preview of user's QR on selected material (composite render) | `Stack` widget pattern; `QrExportService.exportPrintSafe` already exists at `lib/features/qr_generator/domain/services/qr_export_service.dart`; material textures in Supabase Storage `material-textures/` bucket |

</phase_requirements>

---

## Summary

Phase 7 delivers a working marketplace catalog (MKT-01) and a live QR-on-material preview (MKT-02). Both requirements are in scope; cart, checkout, and payment are Phase 8+.

The existing codebase already has a `MarketplaceScreen` stub with a "coming soon" overlay and a `ProductEntity` (client-side only, no Supabase-backed tables yet). Phase 7 replaces the static stub with Supabase-backed data. The QR export pipeline (`QrExportService`) was fully built in Phase 5 — Phase 7 wires it into the marketplace preview.

The product data model in the existing `ProductEntity` uses `double price`, `String currency`, and `LinearGradient` (Flutter-specific). These cannot be serialized to Supabase. Phase 7 must introduce a parallel Supabase-native schema (integers for COP, text for material IDs) and a `ProductModel` that maps to/from the Supabase rows while keeping the existing `ProductEntity` for the UI layer.

**Primary recommendation:** Keep `ProductEntity` as the UI model (no breaking changes to existing screens). Add `ProductVariantEntity` + `MaterialEntity` as domain layer additions. Map Supabase rows through new `ProductModel` / `ProductVariantModel` in the data layer.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Catalog data (products, variants, materials) | API / Supabase Postgres | — | Static master data; read-only for consumers; served via PostgREST |
| Catalog list + filter UI | Frontend (Flutter widget) | — | Client-side filter over in-memory loaded catalog; no server-side filtering needed at MVP scale |
| Material texture images | CDN / Supabase Storage (public bucket) | — | PNG textures; cacheable; `cached_network_image` handles cache layer |
| QR-on-material preview compositing | Frontend (Flutter widget) | — | Pure widget composition (`Stack`); no server round-trip |
| QR export for engraver | Frontend (isolate) | Supabase Storage | `QrExportService.exportPrintSafe` produces 2160 px PNG; upload to `order-assets/` bucket is Phase 8 concern |
| Slug assignment for marketplace QR | API / Supabase (redirects table) | Flutter (RedirectRepository) | `redirects` table + `SlugGenerator` built in Phase 4; Phase 7 only needs to display the slug on product detail |

---

## Standard Stack

### Core (all already installed — verified from pubspec.yaml)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `supabase_flutter` | ^2.0.0 | PostgREST queries for products/variants/materials | [VERIFIED: pubspec.yaml] |
| `flutter_riverpod` | ^2.4.9 | `FutureProvider` for catalog; `StateProvider` for active filter | [VERIFIED: pubspec.yaml] |
| `cached_network_image` | ^3.3.0 | Cache material texture PNGs from Supabase Storage | [VERIFIED: pubspec.yaml] |
| `pretty_qr_code` | ^3.6.0 | `PrettyQrView` for live QR preview inside the material card | [VERIFIED: pubspec.yaml] |
| `shimmer` | ^3.0.0 | Loading skeleton for catalog cards while `FutureProvider` resolves | [VERIFIED: pubspec.yaml] |
| `flutter_animate` | ^4.3.0 | Card entrance animations; already used in existing marketplace widgets | [VERIFIED: pubspec.yaml] |

### No new packages required for Phase 7.

---

## Architecture Patterns

### System Architecture Diagram

```
User selects QR from library
         │
         ▼
MarketplaceScreen (catalog tab)
   │   FutureProvider<List<ProductVariantEntity>>
   │   ◄── Supabase PostgREST: products JOIN product_variants JOIN materials
   │
   ├── FilterBar (material category chips + size selector)
   │         │ client-side filter on in-memory list
   │
   └── ProductVariantGrid (GridView.builder)
             │ tap
             ▼
      ProductDetailScreen
         │
         ├── MaterialPreviewWidget ◄── Stack: texture image + QrPreviewWidget
         │         │
         │         ├── CachedNetworkImage (materials.texture_url from Storage)
         │         └── QrDecorationBuilder.buildDecoration(qrCustomization)
         │                    └── PrettyQrView
         │
         └── (Phase 8) "Add to Cart" button
```

### Recommended Project Structure Additions

```
lib/features/marketplace/
├── data/
│   ├── datasources/
│   │   └── product_supabase_data_source.dart    NEW — PostgREST queries
│   ├── models/
│   │   ├── product_model.dart                   NEW — toEntity() / fromJson()
│   │   ├── product_variant_model.dart           NEW
│   │   └── material_model.dart                  NEW
│   └── repositories/
│       └── product_repository_impl.dart         NEW
├── domain/
│   ├── entities/
│   │   ├── product_entity.dart                  EXTEND — add variantId, slug ref
│   │   ├── product_variant_entity.dart          NEW
│   │   └── material_entity.dart                 NEW
│   ├── repositories/
│   │   └── product_repository.dart              NEW (abstract)
│   └── use_cases/
│       └── get_catalog_use_case.dart            NEW
└── presentation/
    ├── providers/
    │   └── marketplace_providers.dart           NEW — FutureProvider + filter StateProvider
    ├── pages/
    │   └── marketplace_screen.dart              REPLACE stub
    └── widgets/
        ├── product_variant_card.dart            NEW
        ├── material_filter_bar.dart             NEW
        └── material_preview_widget.dart         NEW — QR-on-material Stack

assets/
└── data/
    └── products_seed.dart (or JSON)             NEW — local seed for offline/dev

supabase/
└── migrations/
    └── 20260501000000_marketplace_catalog.sql   NEW
```

### Pattern 1: Supabase Catalog Schema (New Tables)

**What:** Three new tables with a simple relational model. Phase 7 is read-only from the Flutter perspective.

```sql
-- Source: ARCHITECTURE.md (verified schema sketch)
-- materials: static reference table
CREATE TABLE materials (
  id TEXT PRIMARY KEY,              -- 'wood','acrylic','metal','leather','glass','stone'
  display_name_es TEXT NOT NULL,
  display_name_en TEXT NOT NULL,
  texture_url TEXT NOT NULL,        -- public Supabase Storage URL for PNG texture
  laser_compatible BOOLEAN DEFAULT true,
  notes JSONB                       -- engraving constraints (e.g. min contrast ratio)
);

-- products: base product catalog
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name_es TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description_es TEXT,
  description_en TEXT,
  hero_image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- product_variants: size × material × price combinations
CREATE TABLE product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  material_id TEXT NOT NULL REFERENCES materials(id),
  size_label TEXT NOT NULL,         -- '5x5cm','10x10cm','llavero','placa-grande'
  width_mm INT NOT NULL,
  height_mm INT NOT NULL,
  price_cop INT NOT NULL,           -- COP in pesos (NOT cents); e.g. 89000 = $89.000 COP
  sku TEXT UNIQUE,
  stock INT,                        -- null = unlimited (made-to-order)
  is_active BOOLEAN DEFAULT true
);

-- RLS: public SELECT (catalog is public); no INSERT/UPDATE for anon/authenticated
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_materials" ON materials FOR SELECT USING (true);
CREATE POLICY "public_read_products" ON products FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_variants" ON product_variants FOR SELECT USING (is_active = true);
```

**Price unit decision:** Use whole pesos (INT), not cents. Wompi accepts `amountInCents` for its API — multiply by 100 at checkout time. Using whole pesos matches how Colombians think about prices ($89.000 COP) and avoids `/100` conversions everywhere in the UI. [ASSUMED — ARCHITECTURE.md uses `price_cop INT` without specifying cents vs. whole pesos; clarify with team.]

### Pattern 2: Flutter Catalog Data Flow

```dart
// Source: ARCHITECTURE.md Pattern + existing Riverpod patterns in codebase

// Provider
final catalogProvider = FutureProvider.autoDispose<List<ProductVariantEntity>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getActiveCatalog();
});

// Repository impl — single denormalized query
Future<List<ProductVariantEntity>> getActiveCatalog() async {
  final rows = await _supabase
    .from('product_variants')
    .select('''
      id, size_label, width_mm, height_mm, price_cop, sku,
      product:products(id, slug, name_es, name_en, description_es, hero_image_url),
      material:materials(id, display_name_es, display_name_en, texture_url)
    ''')
    .eq('is_active', true)
    .order('material_id')
    .order('price_cop');

  return rows.map(ProductVariantModel.fromJson).map((m) => m.toEntity()).toList();
}
```

### Pattern 3: QR-on-Material Preview Widget (MKT-02)

**What:** `Stack` widget overlays a live `PrettyQrView` on top of a material texture image. No pixel manipulation or BlendMode needed for MVP — the QR widget has a white background (forced by `QrExportService.exportPrintSafe` contract) which creates a natural "label" on the material.

**How the live preview works:**
1. User arrives at `ProductDetailScreen` with their selected `QRCodeEntity` (passed from library or customization screen).
2. `QrDecorationBuilder.buildDecoration(qrEntity.customization)` builds the decoration (already implemented in Phase 5 at `lib/features/qr_generator/domain/services/qr_decoration_builder.dart`).
3. A `MaterialPreviewWidget` composites them via `Stack`.

```dart
// Source: codebase pattern from qr_decoration_builder.dart + Stack widget API
class MaterialPreviewWidget extends StatelessWidget {
  final String textureUrl;      // materials.texture_url
  final QRCodeEntity qrCode;
  final double previewSize;

  const MaterialPreviewWidget({
    super.key,
    required this.textureUrl,
    required this.qrCode,
    this.previewSize = 280,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = QrDecorationBuilder.buildDecoration(qrCode.customization);
    final qrImage = QrImage(qrCode.data);

    return Container(
      width: previewSize,
      height: previewSize,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: material texture (full bleed)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: textureUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _ShimmerBox(size: previewSize),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF2E2E2E),
                ),
              ),
            ),
            // Layer 2: QR code as a centered white "label"
            // White background is enforced by PrettyQrDecoration.background = white
            Container(
              width: previewSize * 0.72,
              height: previewSize * 0.72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: PrettyQrView(
                qrImage: qrImage,
                decoration: decoration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Why Stack + white background instead of BlendMode/SVG mask:**
- BlendMode compositing (e.g., `BlendMode.multiply`) would make the QR inherit the wood grain texture, making it harder to scan — bad for physical products.
- SVG masking requires `flutter_svg` custom painting and is disproportionate complexity for v1.
- The white-label-on-material approach is what physical laser-engraved products actually look like (the engraver burns dark marks on the material surface around a white pad or directly into the material).
- `QrExportService.exportPrintSafe` already enforces `background: Colors.white` — the preview and the export artifact are visually consistent.

[VERIFIED: qr_export_service.dart — `exportDecoration = decoration.copyWith(background: Colors.white)` already enforced]

### Pattern 4: QrExportService Integration Point

**What Phase 7 does vs. what Phase 8 does:**

| Action | Phase |
|--------|-------|
| Show live QR preview on material (in memory, no upload) | Phase 7 |
| Let user pick QR from library for the preview | Phase 7 |
| Export 2160 px PNG and upload to Supabase Storage `order-assets/` | Phase 8 (add to cart + order creation) |

`QrExportService` is already built at `lib/features/qr_generator/domain/services/qr_export_service.dart`. Phase 7 only calls it for preview rendering (optional — `PrettyQrView` widget is enough for the live preview; the export call is only needed at order time in Phase 8).

Phase 7 must ensure that `ProductDetailScreen` knows which `QRCodeEntity` to preview. The entry point must accept a `qrCodeId` parameter and load the entity via an existing `qrCodeProvider`.

### Pattern 5: Slug Anchor for Marketplace QRs (Phase 4 Integration)

**Context from Phase 4 (verified via 04-01-SUMMARY.md + redirect/index.ts):**
- `redirects` table exists with `slug TEXT UNIQUE` (6-char a-z0-9).
- `SlugGenerator` in `lib/features/redirect/domain/utils/slug_generator.dart` generates slugs.
- Edge Function `supabase/functions/redirect/index.ts` resolves `qraft.link/{slug}` → 301 to `destination_url`.

**How it connects to Phase 7:**
- For marketplace QRs (physical products), the QR data field should be a `qraft.link/{slug}` URL rather than the user's final URL directly. This means the engraved QR always points to the redirect service, so the user can update the destination after engraving (per RDR-03/RDR-04).
- Phase 7 scope: display the `qraft.link/{slug}` preview on `ProductDetailScreen` so users understand what will be engraved. Slug generation and `redirects` row creation happen at order time (Phase 8).
- **Phase 7 does NOT need to create slugs.** It only shows a placeholder `qraft.link/xxxxxx` label in the UI to explain the concept.

[VERIFIED: supabase/functions/redirect/index.ts — redirect service is live and resolves slugs correctly]

### Anti-Patterns to Avoid

- **Storing Flutter-specific types in Supabase rows:** `ProductEntity` currently has `IconData` and `LinearGradient` fields. These must NOT be in the database schema. Map them locally in `ProductVariantModel.toEntity()` based on `material_id` (use existing `MaterialGradients.forCategory()` from `product_entity.dart`).
- **Using `double` for COP prices:** The existing `ProductEntity.price` is `double`. Never store COP as double (floating point rounding). Database uses `INT`. Convert to double only at UI display time.
- **Fetching variants and products in separate queries:** Use the nested select pattern above to get all data in one round-trip.
- **Rendering QR preview with inverted colors:** `PrettyQrView` in the preview must use the same white-background constraint as the export. Call `decoration.copyWith(background: Colors.white)` before passing to `PrettyQrView` in `MaterialPreviewWidget`.
- **No fallback when texture URL is unavailable:** `CachedNetworkImage` must have an `errorWidget` fallback showing the `MaterialGradients.forCategory(material.id)` gradient. Texture URLs may be empty in dev/seed data.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Material texture caching | Custom download manager | `cached_network_image` ^3.3.0 | Already installed; handles LRU disk cache, error states, placeholders |
| QR rendering in preview | Custom QR painter | `PrettyQrView` from `pretty_qr_code` | Already fully wired in Phase 5; `QrDecorationBuilder.buildDecoration()` already exists |
| Catalog state management | Manual setState + lists | `FutureProvider.autoDispose` + `StateProvider` for filters | Riverpod already in tree; same pattern as Phase 4 redirect providers |
| Price formatting in COP | Custom currency formatter | `intl` NumberFormat | `intl` is already in `pubspec.yaml`; `NumberFormat.currency(locale: 'es_CO', symbol: '\$')` formats `89000` → `$89.000` |
| Material gradient for missing texture | Custom code | `MaterialGradients.forCategory()` in `product_entity.dart` | Already implemented; covers all 6 material categories |

---

## Common Pitfalls

### Pitfall 1: ProductEntity.price is double — causes COP rounding errors

**What goes wrong:** Developer stores `89000.0` as double in COP, multiplies by 1.19 for IVA → floating point drift → displayed total is `$105.990,00000001`.
**Why it happens:** Existing `ProductEntity.price` is `double`. Easy to accidentally pipe the DB `INT` through double arithmetic.
**How to avoid:** DB column is `price_cop INT`. `ProductVariantEntity.priceCop` must be `int`. Convert to double only for `NumberFormat.currency` display. Never perform arithmetic on double prices.
**Warning signs:** Price totals with unexpected decimal fractions.

### Pitfall 2: Texture URL is null in seed data → CachedNetworkImage crashes

**What goes wrong:** Seed data for dev has `texture_url = ''` or null. `CachedNetworkImage` throws on empty string URL.
**How to avoid:** `errorWidget` fallback + guard `imageUrl.isEmpty` before constructing `CachedNetworkImage`. Use gradient fallback.

### Pitfall 3: QR preview shows dark-on-dark if material is dark and background is transparent

**What goes wrong:** If `PrettyQrDecoration.background` is not forced to white in the preview widget, QRs with dark foreground on transparent background become invisible against dark material textures (e.g., black acrylic).
**How to avoid:** Always pass `decoration.copyWith(background: Colors.white)` to the preview's `PrettyQrView`. This mirrors what `QrExportService.exportPrintSafe` already enforces for exports.

### Pitfall 4: Catalog query returns too many rows as product count grows

**What goes wrong:** The denormalized JOIN query returns `N_products × N_materials × N_sizes` rows. At MVP scale (6 materials × 4 sizes × 3 products = 72 rows) this is fine. At 50+ products it becomes a concern.
**How to avoid:** For MVP, load all active variants once (they change rarely) and cache with `FutureProvider.autoDispose`. Add pagination or server-side filtering only when row count exceeds ~500. Document this limit as a known threshold.

### Pitfall 5: Existing MarketplaceScreen uses hard-coded ProductEntity list with IconData

**What goes wrong:** The existing `MarketplaceScreen` constructs `ProductEntity` objects inline with `Icons.` constants. These can't come from Supabase. The transition must replace the static list with Supabase data while keeping the same visual widget structure.
**How to avoid:** Phase 7 replaces the body of `MarketplaceScreen` entirely (the "coming soon" overlay hides the old static list). Map `material_id` → `IconData` in `ProductVariantModel.toEntity()` using a local lookup map. Keep `MaterialGradients.forCategory()` for gradient mapping.

---

## Code Examples

### COP Price Display with intl

```dart
// Source: intl package NumberFormat API (intl already in pubspec.yaml)
import 'package:intl/intl.dart';

final _copFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

String formatCop(int priceCop) => _copFormat.format(priceCop);
// formatCop(89000) → "$89.000"
// formatCop(125000) → "$125.000"
```

### Supabase Nested Select for Catalog

```dart
// Source: ARCHITECTURE.md catalog pattern
final rows = await supabase
  .from('product_variants')
  .select('''
    id, size_label, width_mm, height_mm, price_cop, sku,
    product:products(id, slug, name_es, name_en, description_es),
    material:materials(id, display_name_es, texture_url)
  ''')
  .eq('is_active', true)
  .order('price_cop');
```

### Material Seed Data (6 materials for migration)

```sql
-- Source: REQUIREMENTS.md (materials listed: wood, acrylic, metal, leather, glass, stone)
INSERT INTO materials (id, display_name_es, display_name_en, texture_url, laser_compatible) VALUES
  ('wood',    'Madera',    'Wood',    '',  true),
  ('acrylic', 'Acrílico',  'Acrylic', '',  true),
  ('metal',   'Metal',     'Metal',   '',  true),
  ('leather', 'Cuero',     'Leather', '',  true),
  ('glass',   'Vidrio',    'Glass',   '',  true),
  ('stone',   'Piedra',    'Stone',   '',  true);
-- texture_urls populated after uploading assets to material-textures/ bucket
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static hard-coded ProductEntity list | Supabase-backed product_variants table | Phase 7 | Catalog managed via Supabase Studio; no redeploy needed for price/product changes |
| Gradient-based hero in ProductHeroSection | Material texture PNG from Supabase Storage | Phase 7 | Users see realistic material; gradient fallback preserved for loading/error states |
| "Coming soon" overlay on MarketplaceScreen | Live catalog with filter + QR preview | Phase 7 | MKT-01 + MKT-02 fulfilled |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `price_cop INT` stores whole pesos (not cents) in DB | Standard Stack / DB Schema | If team decides to store cents, all seed data and UI formatting code needs adjustment. Clarify before writing migration. |
| A2 | Material texture PNGs (~512×512 px) will be uploaded to Supabase Storage `material-textures/` public bucket before Phase 7 verification | Code Examples / Pattern 3 | Preview shows gradient fallback only; MKT-02 visual goal not met until textures uploaded. Non-blocking for code. |
| A3 | Phase 7 does NOT create the `redirects` row / slug — that happens at order creation in Phase 8 | Pattern 5 (slug anchor) | If Phase 8 scope is misunderstood, the "qraft.link/{slug}" concept might be absent from Phase 7 UI entirely. Only a UX gap, not a data gap. |

---

## Open Questions

1. **Price unit: whole pesos vs. cents?**
   - What we know: `ARCHITECTURE.md` shows `price_cop INT` without specifying the unit. Wompi requires `amountInCents`.
   - What's unclear: Should DB store `89000` (pesos) or `8900000` (cents)?
   - Recommendation: Store whole pesos in DB (matches Colombian mental model for prices); multiply ×100 at Wompi checkout call. Document in migration comment.

2. **Who uploads material texture PNGs and when?**
   - What we know: `material-textures/` is noted as a public Supabase Storage bucket in ARCHITECTURE.md.
   - What's unclear: Are source texture images already created/available? Or is this a content task blocking Phase 7 visual verification?
   - Recommendation: Planner should add a Wave 0 task: "Upload 6 material texture PNGs to `material-textures/` bucket and populate `materials.texture_url`." Phase 7 code ships with graceful fallback.

3. **Should ProductDetailScreen accept a QRCodeEntity parameter or load from qrCodeId?**
   - What we know: Users need to navigate from QR library → select product. The selected QR must flow into the preview.
   - What's unclear: The existing `ProductDetailsScreen` constructor only takes `ProductEntity`. The navigation flow (library → marketplace) needs a design decision.
   - Recommendation: Pass `String? qrCodeId` as optional navigation parameter. If null, show a placeholder "Select your QR" prompt. Load entity via `qrCodeProvider(qrCodeId)`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | Yes | 3.38.5 (stable) | — |
| Supabase project `cnieotneosdkfzboxazw` | Catalog tables | Must confirm tables deployed | — | Seed JSON in assets for dev |
| Supabase Storage `material-textures/` bucket | MKT-02 texture display | Needs creation | — | MaterialGradients.forCategory() gradient fallback |
| `cached_network_image` ^3.3.0 | Texture display | Yes (in pubspec.yaml) | ^3.3.0 | — |
| `pretty_qr_code` ^3.6.0 | QR preview in widget | Yes (in pubspec.yaml) | ^3.6.0 | — |

**Missing dependencies with no fallback:** None — all packages are installed.

**Missing with content dependency:** Material texture PNG assets must be uploaded to Supabase Storage before MKT-02 visual acceptance. This is a content task, not a code task.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK built-in) |
| Config file | none — uses `flutter test` |
| Quick run command | `flutter test test/features/marketplace/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MKT-01 | Catalog loads from Supabase and renders variant cards | widget (mocked repo) | `flutter test test/features/marketplace/presentation/marketplace_screen_test.dart -x` | No — Wave 0 |
| MKT-01 | Filter by material category shows correct subset | unit | `flutter test test/features/marketplace/domain/catalog_filter_test.dart -x` | No — Wave 0 |
| MKT-01 | COP price formatted as "$89.000" | unit | `flutter test test/features/marketplace/domain/price_format_test.dart -x` | No — Wave 0 |
| MKT-02 | MaterialPreviewWidget renders Stack with QR on texture | widget | `flutter test test/features/marketplace/presentation/material_preview_test.dart -x` | No — Wave 0 |
| MKT-02 | Preview decoration forces white background | unit | included in material_preview_test.dart | No — Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/features/marketplace/ -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/features/marketplace/presentation/marketplace_screen_test.dart` — covers MKT-01 render
- [ ] `test/features/marketplace/domain/catalog_filter_test.dart` — covers MKT-01 filter logic
- [ ] `test/features/marketplace/domain/price_format_test.dart` — covers COP formatting
- [ ] `test/features/marketplace/presentation/material_preview_test.dart` — covers MKT-02

---

## Security Domain

### Applicable ASVS Categories (Level 1)

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Catalog is public read |
| V3 Session Management | No | Read-only catalog |
| V4 Access Control | Yes | Supabase RLS: `FOR SELECT USING (is_active = true)` on products/variants/materials |
| V5 Input Validation | Yes | Filter values are client-side on in-memory list — no SQL injection surface |
| V6 Cryptography | No | No sensitive data in Phase 7 |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized catalog mutation | Tampering | RLS: no INSERT/UPDATE policy for anon/auth roles on catalog tables |
| Texture URL injection (malformed URL from Supabase row) | Tampering | `CachedNetworkImage` only loads URLs from trusted Supabase Storage domain; validate URL format in `MaterialModel.fromJson` |

---

## Project Constraints (from CLAUDE.md)

- Use Riverpod (`flutter_riverpod: ^2.4.9`) for all state management — no BLoC, no Provider.
- Clean architecture: `data/` (models, datasources, repository impls) / `domain/` (entities, use cases, abstract repos) / `presentation/` (pages, widgets, controllers, providers) per feature.
- Environment variables via `--dart-define-from-file=env.json`; no secrets in Flutter client.
- Supabase is the backend; migrations go in `supabase/migrations/` with timestamp prefix.
- `flutter analyze` must pass (0 issues) before any commit.
- Price storage: COP as integer. The existing `ProductEntity.price` is `double` — new domain entities must use `int priceCop`. Convert to double only for display.
- Material categories are fixed set: `wood`, `acrylic`, `metal`, `leather`, `glass`, `stone` (per REQUIREMENTS.md).
- QR export: `QrExportService.exportPrintSafe` enforces white background + 2160 px. Do not bypass this contract in marketplace preview.
- Existing `ProductEntity` (UI model) is used by `ProductDetailsScreen`, `ProductGallery`, `ProductHeroSection`, `ProductInfoSection` — do not break these existing widgets during Phase 7.

---

## Sources

### Primary (HIGH confidence)

- Codebase: `lib/features/qr_generator/domain/services/qr_export_service.dart` — QrExportService API verified
- Codebase: `lib/features/qr_generator/domain/entities/qr_code_entity.dart` — QRCustomization entity structure verified
- Codebase: `lib/features/marketplace/domain/entities/product_entity.dart` — existing UI model verified
- Codebase: `lib/features/marketplace/marketplace_screen.dart` — stub structure verified
- Codebase: `pubspec.yaml` — all dependency versions verified
- Codebase: `supabase/functions/redirect/index.ts` — redirect service implementation verified
- `.planning/research/ARCHITECTURE.md` — DB schema sketch (products, variants, materials, cart_items, orders)
- `.planning/phases/04-redirect-service-foundation/04-01-SUMMARY.md` — redirects table + SlugGenerator verified built
- `.planning/phases/05-qr-customization/05-RESEARCH.md` — QrDecorationBuilder, QrExportService, QRCustomization entity
- `.planning/phases/05-qr-customization/05-05-SUMMARY.md` — Phase 5 completion state

### Secondary (MEDIUM confidence)

- `.planning/research/STACK.md` — Wompi, firebase, package selection rationale
- `.planning/research/PITFALLS.md` — material preview UX pitfall, price calculation pitfall

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified in pubspec.yaml; no new additions needed
- Architecture: HIGH — verified against existing codebase structure and ARCHITECTURE.md
- DB schema: HIGH — drawn directly from ARCHITECTURE.md which cites official Supabase patterns
- QR-on-material preview: HIGH — QrExportService and QrDecorationBuilder verified in codebase
- Slug/redirect integration: HIGH — Phase 4 redirect service fully verified in codebase
- Price unit (pesos vs cents): ASSUMED (A1) — needs team confirmation before migration is written

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (stable dependencies; schema sketch from ARCHITECTURE.md is the reference)
