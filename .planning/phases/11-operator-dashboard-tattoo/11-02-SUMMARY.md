---
phase: 11-operator-dashboard-tattoo
plan: 02
subsystem: marketplace-tattoo
tags: [flutter, supabase, marketplace, tattoo, riverpod, rls]

# Dependency graph
requires:
  - phase: 05-qr-profiles/qr_profile.dart
    provides: QrProfile.tattooSafe enum with maxLogoScale=0.15, requiresEcH=true

provides:
  - TattooProfileEnforcementWidget: banner on product detail for tattoo_transfer variants
  - TattooFaqScreen: 6-entry educational FAQ with ExpansionTile + waitlist CTA
  - TattooWaitlistCta: email form → tattoo_studio_waitlist INSERT
  - ProductVariantEntity.isTattooCategory: computed getter (materialId == tattoo_transfer)
  - tattooProductsProvider: derived Riverpod provider filtering catalog by tattoo_transfer
  - Migration 20260511000000: tattoo material + product + variants + waitlist table

affects:
  - lib/features/marketplace/presentation/pages/product_detail_screen.dart: banner wired in
  - lib/features/marketplace/domain/entities/product_variant_entity.dart: isTattooCategory getter added

# Tech tracking
tech-stack:
  added: []
  patterns:
    - rootBundle.loadString for JSON asset loading in FutureBuilder
    - PostgrestException code 23505 graceful handling (UNIQUE violation → success state)
    - ExpansionTile with dark theme override via Theme.of(context).copyWith(dividerColor)

key-files:
  created:
    - supabase/migrations/20260511000000_tattoo_products.sql
    - assets/data/tattoo_faq.json
    - lib/features/marketplace/presentation/widgets/tattoo_profile_enforcement_widget.dart
    - lib/features/marketplace/presentation/widgets/tattoo_waitlist_cta.dart
    - lib/features/marketplace/presentation/pages/tattoo_faq_screen.dart
  modified:
    - lib/features/marketplace/domain/entities/product_variant_entity.dart
    - lib/features/marketplace/presentation/pages/product_detail_screen.dart
    - lib/features/marketplace/presentation/providers/marketplace_providers.dart

key-decisions:
  - "isTattooCategory computed client-side from materialId — avoids DB round-trip; flag only controls UI (T-11-06 accepted)"
  - "tattooProductsProvider uses whenOrNull to return [] while loading — avoids AsyncValue propagation to callers"
  - "TattooWaitlistCta handles 23505 UNIQUE violation as success path not error — UX matches 'already registered' expectation"
  - "TattooFaqScreen imports TattooWaitlistCta directly — no circular imports since enforcement widget imports faq_screen not cta"

# Metrics
duration: 8min
completed: 2026-05-03
---

# Phase 11 Plan 02: Tattoo Marketplace — FAQ, Enforcement Widget, Waitlist CTA Summary

**Tattoo Stencil/Transfer product category added to marketplace: DB seed migration, TattooSafe profile enforcement banner, educational FAQ screen, and partner waitlist CTA with Supabase insert.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-03T18:40:21Z
- **Completed:** 2026-05-03T18:48:00Z
- **Tasks:** 2 auto tasks
- **Files created:** 5
- **Files modified:** 3

## Accomplishments

### Task 1: Tattoo products migration + FAQ asset

- `supabase/migrations/20260511000000_tattoo_products.sql`:
  - `tattoo_transfer` material (laserCompatible=false, notes JSONB with profile config)
  - `tattoo-qr-transfer` product (ES+EN names and descriptions)
  - 2 variants: 5x5cm @ 15000 COP (SKU: TAT-QR-50x50), 8x8cm @ 22000 COP (SKU: TAT-QR-80x80)
  - `tattoo_studio_waitlist` table: UNIQUE(email), RLS INSERT=open, SELECT=blocked (T-11-07 mitigated)
- `assets/data/tattoo_faq.json`: 6 FAQ entries covering minimum size, body placement, duration, permanence, module sizing, and logo limits

### Task 2: Tattoo marketplace UI

- `TattooProfileEnforcementWidget`: Green-border container banner displaying "Perfil Tattoo-Safe activado" with EC-H / Logo 15% info and "¿Por qué?" nav to TattooFaqScreen
- `TattooFaqScreen`: Loads FAQ JSON via rootBundle, renders 6 ExpansionTile entries with numbered leading icon, TattooWaitlistCta at bottom; AppBar title "¿Cómo funciona el QR en tatuajes?"
- `TattooWaitlistCta`: glassmorphism card with email + optional studio name fields, GlassButton submission → Supabase INSERT; handles 23505 UNIQUE violation as "Ya estás en la lista." success state; Semantics keys: `tattoo_waitlist_cta`, `tattoo_waitlist_email_field`, `tattoo_waitlist_submit_btn`
- `ProductVariantEntity.isTattooCategory`: bool getter `material.id == 'tattoo_transfer'`
- `ProductDetailScreen`: TattooProfileEnforcementWidget inserted below QR preview when `isTattooCategory == true`
- `marketplace_providers.dart`: `tattooProductsProvider` derives from `catalogProvider` via `whenOrNull` filter

## Task Commits

1. **feat(11-02): tattoo marketplace** — `71cd052`

## Verification Results

- `flutter analyze lib/features/marketplace/` — **0 issues**
- Migration file: FOUND with 5 references to tattoo_transfer
- FAQ JSON: FOUND with 6 entries
- All 5 new files created successfully

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — TattooWaitlistCta wires directly to Supabase; form validation is live; TattooFaqScreen loads real asset data.

Note: MaterialFilterBar will automatically pick up the `tattoo_transfer` chip once the migration is applied to the remote DB and the catalog is refreshed (the filter bar reads from materialId of loaded variants — no code change required).

## Threat Flags

All threat model items mitigated as planned:
- T-11-07: `FOR SELECT USING (false)` policy on `tattoo_studio_waitlist` blocks consumer reads
- T-11-06: `isTattooCategory` flag only controls UI display, no security implication
- T-11-05 / T-11-08: UNIQUE(email) prevents spam; 23505 handled gracefully in UI

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| supabase/migrations/20260511000000_tattoo_products.sql | FOUND |
| assets/data/tattoo_faq.json | FOUND |
| lib/features/marketplace/presentation/widgets/tattoo_profile_enforcement_widget.dart | FOUND |
| lib/features/marketplace/presentation/widgets/tattoo_waitlist_cta.dart | FOUND |
| lib/features/marketplace/presentation/pages/tattoo_faq_screen.dart | FOUND |
| commit 71cd052 | FOUND |
| flutter analyze 0 issues | CONFIRMED |

---
*Phase: 11-operator-dashboard-tattoo*
*Completed: 2026-05-03*
