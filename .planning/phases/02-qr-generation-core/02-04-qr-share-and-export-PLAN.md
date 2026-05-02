---
phase: 02-qr-generation-core
plan: 04
type: execute
wave: 3
depends_on:
  - 02-02
  - 02-03
files_modified:
  - lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart
  - lib/features/qr_generator/presentation/widgets/qr_share_button.dart
  - lib/features/qr_library/qr_library_screen.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_es.arb
autonomous: true
requirements:
  - QR-09
must_haves:
  truths:
    - "A `QrShareButton` widget exists that exports the QR as PNG via `RenderRepaintBoundary.toImage()` on the repaintKey GlobalKey, then shares via `Share.shareXFiles` from share_plus"
    - "QrShareButton appears on all 6 QR form screens (url, text, personal_info, wifi, email/location, event)"
    - "QrShareButton also appears on the QR library item detail view or as a swipe/long-press action on library items"
    - "`flutter analyze --no-fatal-warnings` exits 0 — no new issues"
    - "PNG export uses `pixelRatio: 3.0` for print-quality output"
    - "Maestro Key `qr_share_button` added via Semantics(identifier:)"
---

# Plan 02-04: QR Share and Export

## Objective

Implement QR-09: users can share a generated QR via the system share sheet as a PNG image. Wire `RenderRepaintBoundary.toImage()` into the existing `repaintKey` GlobalKeys added by plan 02-02, package the PNG into a temporary file, and call `Share.shareXFiles` from share_plus.

## Context

- `share_plus` is already installed (pubspec.yaml)
- `screenshot` package installed but not needed — repaintKey + RenderRepaintBoundary approach avoids it
- Plans 02-02 added `GlobalKey repaintKey` + `RepaintBoundary(key: repaintKey)` to all 6 QR screens
- QRPreviewWidget also has a `repaintKey` parameter

## Tasks

### Task 1 — Create QrShareButton widget

Create `lib/features/qr_generator/presentation/widgets/qr_share_button.dart`:

```dart
// QrShareButton — captures the RepaintBoundary pointed to by repaintKey,
// encodes to PNG at 3x pixel ratio, writes to a temp file, and calls
// Share.shareXFiles so the OS share sheet handles format selection.
```

- `QrShareButton({required GlobalKey repaintKey, required String qrName})`
- On tap: `RenderRepaintBoundary boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary`
- `ui.Image image = await boundary.toImage(pixelRatio: 3.0)`
- `ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png)`
- Write to `Directory.systemTemp` with name `qraft_${qrName}_${DateTime.now().millisecondsSinceEpoch}.png`
- `Share.shareXFiles([XFile(tmpFile.path)], text: 'QR: $qrName')`
- Show `SnackBar` on error
- Uses `PrimaryGlassButton` or `IconButton` with share icon, Carden Pro style
- Maestro Key: `Semantics(identifier: 'qr_share_button', ...)`

### Task 2 — Add QrShareButton to all 6 QR screens + library

- Add `QrShareButton(repaintKey: repaintKey, qrName: _qrName)` to each of the 6 form screens in the action bar below the preview
- Add share action to QR library items (IconButton in the item tile trailing, or in an action bar when viewing a QR detail)
- Add i18n strings: `shareQR: "Share QR"` / `"Compartir QR"`, `exportQRPng: "Export as PNG"` / `"Exportar como PNG"`

### Task 3 — Verify and commit

- `flutter analyze --no-fatal-warnings` = 0 issues
- `flutter build apk --debug` succeeds
- Commit each task atomically
- Create SUMMARY.md

## Acceptance Criteria

- [ ] QrShareButton widget created and working (captures RepaintBoundary → PNG → share sheet)
- [ ] All 6 QR form screens have share button
- [ ] Library screen has share action per item
- [ ] Analyzer: 0 issues
- [ ] Both debug builds pass
