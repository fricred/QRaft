---
phase: 07-marketplace-catalog
plan: "03"
subsystem: marketplace
tags: [widget, qr-preview, material-texture, cached-network-image, pretty-qr-code, shimmer]
dependency_graph:
  requires:
    - 07-01  # MaterialEntity domain model
    - 05-xx  # QrDecorationBuilder, QRCodeEntity, QrExportService contract
  provides:
    - MaterialPreviewWidget (self-contained, drop-in for 07-04 ProductDetailScreen)
  affects:
    - lib/features/marketplace/presentation/widgets/material_preview_widget.dart
tech_stack:
  added: []
  patterns:
    - Stack compositing (texture beneath white QR label pad)
    - CachedNetworkImage with shimmer placeholder and gradient errorWidget fallback
    - copyWith(background: Colors.white) white-bg enforcement mirroring QrExportService
    - URL guard: textureUrl.isEmpty || !textureUrl.startsWith('https://') → gradient fallback
key_files:
  created:
    - lib/features/marketplace/presentation/widgets/material_preview_widget.dart
    - test/features/marketplace/presentation/material_preview_test.dart
  modified: []
decisions:
  - "Import paths use package-relative style (../../../) from the widgets/ directory instead of package:qraft/ style — both work; relative chosen for consistency with existing widget files in the marketplace feature"
  - "RenderBox tree traversal used in size test (walk up from PrettyQrView) rather than Container widget key approach — more robust against decorator wrapping in the widget hierarchy"
metrics:
  duration: "94 seconds"
  completed: "2026-05-03"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 7 Plan 03: MaterialPreviewWidget Summary

**One-liner:** Stack widget compositing material texture (CachedNetworkImage with shimmer + gradient fallback) beneath a white-background PrettyQrView label, satisfying MKT-02 preview contract.

## What Was Built

`MaterialPreviewWidget` is a self-contained `StatelessWidget` that accepts `QRCodeEntity` and `MaterialEntity` and renders a `previewSize x previewSize` (default 280px) square preview with:

- **Layer 1 (bottom):** `CachedNetworkImage` showing the material texture at full bleed inside a rounded-corner `ClipRRect`. Shimmer placeholder while loading. Gradient fallback when `textureUrl` is empty, non-https, or fails to load.
- **Layer 2 (top):** A white `Container` (72% of `previewSize`) with a 12px padding containing `PrettyQrView`. White background is forced via `decoration.copyWith(background: Colors.white)` mirroring the `QrExportService` contract — dark-on-dark is impossible.

The `_MaterialTexture` private widget implements the URL guard at line level: `textureUrl.isEmpty || !textureUrl.startsWith('https://')` sends the render immediately to `_GradientFallback`, satisfying threat T-07-08.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | MaterialPreviewWidget — Stack(texture + white QR label) | 59096c7 | lib/features/marketplace/presentation/widgets/material_preview_widget.dart |
| 2 | Verify widget contract end-to-end with flutter test | 89bf471 | test/features/marketplace/presentation/material_preview_test.dart |

## Verification Results

1. `flutter analyze material_preview_widget.dart` — 0 issues
2. `flutter test material_preview_test.dart` — 4/4 tests pass
3. `copyWith(background: Colors.white)` — 1 match in source
4. `textureUrl.isEmpty` guard — 1 match in source

## Deviations from Plan

None — plan executed exactly as written. Import paths use relative `../../../` style rather than `package:qraft/` as noted in decisions; this is a cosmetic preference, not a behavioral deviation.

## Known Stubs

None. The widget is fully functional: both texture image loading and gradient fallback are implemented. The shimmer placeholder is live (not a stub). Data flows from the `QRCodeEntity` and `MaterialEntity` inputs through to `PrettyQrView` and `CachedNetworkImage` with no hardcoded empty values.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundaries introduced beyond what was documented in the plan's threat model. The only new network surface is `CachedNetworkImage` fetching from the Supabase Storage CDN — this was pre-registered as T-07-08 (Tampering) and is mitigated by the `https://` guard in `_MaterialTexture`.

## Self-Check: PASSED

- [x] `lib/features/marketplace/presentation/widgets/material_preview_widget.dart` exists
- [x] `test/features/marketplace/presentation/material_preview_test.dart` exists
- [x] Commit `59096c7` exists in git log
- [x] Commit `89bf471` exists in git log
