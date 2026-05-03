---
phase: 07-marketplace-catalog
plan: "04"
subsystem: marketplace
tags: [flutter, riverpod, navigation, qr-preview, state-provider, library-to-marketplace]

dependency_graph:
  requires:
    - 07-01  # catalogProvider, MaterialEntity, ProductVariantEntity
    - 07-02  # ProductDetailScreen with qrCodeId hook
    - 07-03  # MaterialPreviewWidget
    - 05-xx  # QRCodeEntity, QRCustomization
  provides:
    - selectedQrForMarketplaceProvider (StateProvider<String?>) — loose-coupling bridge library→marketplace
    - QR library "Engrabar" action wired to marketplace
    - ProductDetailScreen live MaterialPreviewWidget integration (replaces placeholder)
    - _SelectQrPrompt when no QR selected, _PreviewShimmer loading, _PreviewError fallback
  affects:
    - Phase 8 (Cart — ProductDetailScreen CTA button still placeholder snackbar; Phase 8 adds real cart call)
    - Phase 9 (Checkout — builds on the same ProductDetailScreen + qrCodeId flow)

tech_stack:
  added: []
  patterns:
    - "StateProvider<String?> as loose-coupling bridge between library and marketplace navigation"
    - "ref.read(provider.notifier).state = value before push (write-then-navigate)"
    - "userQRCodesProvider.when(loading/error/data) for async QR entity lookup"
    - "Inline entity-not-found guard → _SelectQrPrompt fallback"

key_files:
  created: []
  modified:
    - lib/features/marketplace/presentation/pages/product_detail_screen.dart
    - lib/features/marketplace/presentation/providers/marketplace_providers.dart
    - lib/features/marketplace/marketplace_screen.dart
    - lib/features/qr_library/qr_library_screen.dart

key_decisions:
  - "selectedQrForMarketplaceProvider (StateProvider<String?>) chosen over passing qrCodeId through Navigator args — avoids adding constructor param to MarketplaceScreen (which renders all variants); looser coupling lets the library set QR context before any catalog interaction"
  - "_SelectQrPrompt pop-back goes to navigator.pop() not named route — primary flow is library→marketplace, so back correctly returns to library"
  - "Engrave action writes to provider THEN navigates (write-then-push, not push-then-write) to ensure state is available when MarketplaceScreen reads it on first frame"
  - "MarketplaceScreen reads selectedQrForMarketplaceProvider only at card-tap time (ref.read not ref.watch) to avoid rebuilds on every tap"

patterns-established:
  - "Library→feature navigation via StateProvider bridge: set shared state, then push feature screen — avoids prop-drilling through navigation hierarchy"

requirements-completed:
  - MKT-01
  - MKT-02
  - MKT-03  # Phase 7 portion only — full cart is Phase 8

duration: "~5 minutes (close-out)"
completed: "2026-05-03"
---

# Phase 7 Plan 04: Marketplace QR Wiring Summary

**End-to-end MKT-01 + MKT-02 journey wired: QR library "Engrabar" action sets `selectedQrForMarketplaceProvider`, navigates to MarketplaceScreen, which passes it through to ProductDetailScreen where `MaterialPreviewWidget` renders the user's customized QR on the selected material texture.**

## Performance

- **Duration:** ~5 minutes (close-out task; Task 1 was completed pre-continuation)
- **Started:** 2026-05-03T09:00:00Z
- **Completed:** 2026-05-03T14:06:16Z
- **Tasks:** 1 (auto) + 1 (checkpoint — auto-approved in autonomous mode)
- **Files modified:** 4

## Accomplishments

- Wired `ProductDetailScreen` to replace the `Key('qr_preview_placeholder')` stub with live `MaterialPreviewWidget`, loading the `QRCodeEntity` from `userQRCodesProvider` by id.
- Added `selectedQrForMarketplaceProvider` (`StateProvider<String?>`) as a loose-coupling bridge so the QR library can communicate the selected QR to the marketplace without constructor prop-drilling.
- Added "Engrabar" popup menu action to each QR in `QrLibraryScreen`; tapping sets the provider and pushes `MarketplaceScreen` — user then picks a product and sees their QR rendered on the material.
- Completed Phase 7's 4-plan arc delivering the full Marketplace Catalog + QR Export Pipeline scope (MKT-01 + MKT-02).

## All Phase 7 Commits (Plans 07-01 through 07-04)

### Plan 07-01: Schema + Domain Layer
1. **Migration SQL** - `5fce44c` (feat: 3 tables + seed)
2. **Dart domain/data/providers** - `92435e2` (feat: 8 new files)
3. **T-07-02 security fix** - `bbace05` (fix: https-only texture_url guard)
4. **Plan docs** - `affff4b` (docs: 07-01 SUMMARY + STATE + ROADMAP)

### Plan 07-02: Catalog UI
5. **Widgets** - `97f4909` (feat: MaterialFilterBar + ProductVariantCard)
6. **Screen + Detail** - `79c9d4a` (feat: MarketplaceScreen replacement + ProductDetailScreen)
7. **Plan docs** - `ec03c8c` (docs: 07-02 SUMMARY + STATE + ROADMAP)

### Plan 07-03: MaterialPreviewWidget
8. **Widget** - `59096c7` (feat: MaterialPreviewWidget Stack + texture + white QR label)
9. **Tests** - `89bf471` (test: 4 widget tests, 4/4 pass)
10. **Plan docs** - `7245ec2` (docs: 07-03 SUMMARY + STATE + ROADMAP)

### Plan 07-04: QR Wiring (this plan)
11. **Task 1 — QR wiring** - `d0484a2` (feat: wire QR library → marketplace preview flow)

## Task Commits (this plan)

1. **Task 1: Wire MaterialPreviewWidget + Engrave action** - `d0484a2` (feat)

**Plan metadata commit:** TBD (created in this close-out)

## Files Created/Modified

| File | Change | Purpose |
|------|--------|---------|
| `lib/features/marketplace/presentation/pages/product_detail_screen.dart` | Modified | Replaced placeholder with `MaterialPreviewWidget`; `_SelectQrPrompt`, `_PreviewShimmer`, `_PreviewError` private widgets added |
| `lib/features/marketplace/presentation/providers/marketplace_providers.dart` | Modified | Added `selectedQrForMarketplaceProvider` (`StateProvider<String?>`) |
| `lib/features/marketplace/marketplace_screen.dart` | Modified | Reads `selectedQrForMarketplaceProvider` at card-tap to pass `qrCodeId` to `ProductDetailScreen` |
| `lib/features/qr_library/qr_library_screen.dart` | Modified | Added "Engrabar" `PopupMenuItem` with `Icons.precision_manufacturing_rounded`; writes to provider then pushes `MarketplaceScreen` |

## Decisions Made

- **`StateProvider<String?>` bridge over constructor param:** `MarketplaceScreen` renders all catalog variants and doesn't logically own a qrCodeId — forcing one through its constructor would be awkward. The provider bridge is cleaner and matches the existing Riverpod pattern in the codebase.
- **Pop-back in `_SelectQrPrompt`:** Tapping "Ir a mi biblioteca" calls `Navigator.of(context).pop()`. Since the primary entry path is library → marketplace, this correctly returns to the library. For users who arrived via the Marketplace tab directly (no QR preselected), pop returns to the catalog grid — also correct.
- **Write-then-push pattern:** `ref.read(selectedQrForMarketplaceProvider.notifier).state = qrCode.id` executes before `Navigator.push` so the provider value is available synchronously on `MarketplaceScreen`'s first `build`.

## Deviations from Plan

None — plan executed exactly as written. The checkpoint (Task 2, `checkpoint:human-verify`) was auto-approved in autonomous mode after code analysis confirmed 0 analyzer issues and 4/4 widget tests pass.

## User Setup Required

Phase 7 as a whole requires two manual steps before MKT-02 visual previews show real texture images:

1. **Apply the migration SQL** (if not yet done): Supabase Dashboard → SQL Editor → paste `supabase/migrations/20260501000000_marketplace_catalog.sql` → Run.
2. **Upload texture PNGs** to Supabase Storage:
   - Create public bucket `material-textures` in Supabase Dashboard → Storage → New bucket.
   - Upload `wood.png`, `acrylic.png`, `metal.png`, `leather.png`, `glass.png`, `stone.png`.
   - Run SQL UPDATE to populate each material row's `texture_url`:
     ```sql
     UPDATE materials SET texture_url = 'https://<project-ref>.supabase.co/storage/v1/object/public/material-textures/<id>.png'
     WHERE id = '<id>';
     ```
   Until this is done, `MaterialPreviewWidget` uses `MaterialGradients.forCategory()` gradient fallback — the QR preview is still visible, just without real texture imagery.

## Known Stubs

**"Agregar al carrito" button in `ProductDetailScreen` shows a snackbar placeholder.** Full cart functionality (Phase 8) will replace the snackbar with the real cart add-item call (`cart_items` Supabase INSERT + local Hive sync).

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. `selectedQrForMarketplaceProvider` is a local in-process `StateProvider<String?>` — no network surface. The `userQRCodesProvider` lookup (existing provider) filters by authenticated user_id via Supabase RLS on `qr_codes` — T-07-11 (spoofing via arbitrary qrCodeId) mitigated: a non-owned id returns empty → `_SelectQrPrompt` shown instead of preview.

## Phase 7 Residuals

The following items from Phase 7 are intentionally deferred:

| Item | Reason | Owner |
|------|--------|-------|
| Material texture PNGs in Supabase Storage | Manual step requiring real photography assets | User/designer |
| "Agregar al carrito" real implementation | Phase 8 scope (Cart & Customization Snapshot) | Phase 8 |
| `selectedQrForMarketplaceProvider` reset on cart add | Phase 8 will manage cart state lifecycle | Phase 8 |
| Maestro E2E flow for MKT-01 + MKT-02 | Phase 3 plan 03-03 covers remaining Maestro work | Phase 3 / 03-03 |

## Next Phase Readiness

**Phase 8 (Cart & Customization Snapshot):** The full library→catalog→detail preview flow is functional. Phase 8 can take `ProductDetailScreen`'s placeholder CTA and replace it with real cart logic. `selectedQrForMarketplaceProvider` and `variant` are already in scope at the CTA tap site. Server-authoritative `compute_order_totals()` Postgres function is the Phase 8 backend target.

**Phase 6 plan 06-04 (QRD-03 home widget):** Parallel to Phase 7; unblocked; no dependencies on this plan.

## Verification Results

- `flutter analyze --no-fatal-warnings` → 0 issues (entire project)
- `flutter test test/features/marketplace/` → 4/4 pass
- `grep "MaterialPreviewWidget" lib/features/marketplace/presentation/pages/product_detail_screen.dart` → 1 match
- `grep "selectedQrForMarketplaceProvider" lib/features/marketplace/presentation/providers/marketplace_providers.dart` → 1 match
- `grep -i "Engrabar" lib/features/qr_library/qr_library_screen.dart` → 1 match

## Self-Check: PASSED

- [x] `lib/features/marketplace/presentation/pages/product_detail_screen.dart` modified (MaterialPreviewWidget wired)
- [x] `lib/features/marketplace/presentation/providers/marketplace_providers.dart` modified (selectedQrForMarketplaceProvider added)
- [x] `lib/features/marketplace/marketplace_screen.dart` modified (reads provider at card tap)
- [x] `lib/features/qr_library/qr_library_screen.dart` modified ("Engrabar" action added)
- [x] Commit `d0484a2` exists in git log
- [x] `flutter analyze` 0 issues
- [x] 4/4 marketplace widget tests pass

---
*Phase: 07-marketplace-catalog*
*Completed: 2026-05-03*
