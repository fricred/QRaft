---
phase: 02-qr-generation-core
plan: "04"
subsystem: qr-generator-presentation
tags: [share_plus, png-export, repaint-boundary, qr-share, library, i18n]
dependency_graph:
  requires:
    - Phase 2 Plan 02 complete (RepaintBoundary + GlobalKey on all 6 QR screens)
    - Phase 2 Plan 03 complete (EventQRScreen)
  provides:
    - QrShareButton widget: RenderRepaintBoundary.toImage(pixelRatio:3.0) → PNG → Share.shareXFiles
    - Share button on all 6 QR form screens (shown when form isValid)
    - QRLibraryScreen._shareQRCode: QrPainter offscreen canvas → PNG → Share.shareXFiles (replaces stub)
    - shareQR + exportQRPng i18n keys (en + es)
  affects:
    - lib/features/qr_generator/presentation/widgets/qr_share_button.dart (CREATED)
    - lib/features/qr_generator/presentation/pages/url_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/text_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/personal_info_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/wifi_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/email_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/location_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/event_qr_screen.dart
    - lib/features/qr_library/qr_library_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_es.arb
    - lib/l10n/app_localizations.dart (regenerated)
    - lib/l10n/app_localizations_en.dart (regenerated)
    - lib/l10n/app_localizations_es.dart (regenerated)
tech_stack:
  added: []
  patterns:
    - QrShareButton uses RenderRepaintBoundary.toImage(pixelRatio:3.0) → ui.ImageByteFormat.png → Directory.systemTemp → Share.shareXFiles
    - QRLibraryScreen uses QrPainter offscreen canvas (no RepaintBoundary needed) for library-item PNG generation
    - QrShareButton only shown when form isValid (conditional rendering pattern matching existing screens)
    - Semantics(identifier:'qr_share_button') added for Maestro automation
key_files:
  created:
    - lib/features/qr_generator/presentation/widgets/qr_share_button.dart
  modified:
    - lib/features/qr_generator/presentation/pages/url_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/text_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/personal_info_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/wifi_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/email_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/location_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/event_qr_screen.dart
    - lib/features/qr_library/qr_library_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_es.arb
decisions:
  - "QrShareButton only appears when form isValid — prevents sharing incomplete/empty QR images"
  - "Library share uses QrPainter offscreen canvas rather than RepaintBoundary (no widget in tree for library items)"
  - "QrPainter deprecated color/emptyColor replaced with eyeStyle/dataModuleStyle to keep analyzer clean"
  - "dart:ui imported both aliased (as ui) and unaliased in qr_library_screen.dart to preserve existing ImageFilter usages without churn"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-02"
  tasks_completed: 3
  files_modified: 14
---

# Phase 2 Plan 04: QR Share and Export Summary

QrShareButton widget implemented: captures RepaintBoundary at 3x pixel ratio → PNG → OS share sheet via share_plus. All 6 QR form screens wired. Library screen stub replaced with functional QrPainter offscreen-canvas PNG export.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1+2 | Create QrShareButton widget + wire to 6 screens + library + i18n | `8bba9fa` |
| 3 | l10n regeneration + verify analyzer + APK build | `a0e4da1` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ByteData missing import in qr_share_button.dart**
- **Found during:** Task 1 flutter analyze
- **Issue:** `ByteData` not resolved; requires `dart:typed_data`
- **Fix:** Added `import 'dart:typed_data';`
- **Files modified:** qr_share_button.dart
- **Commit:** `8bba9fa` (fixed before commit)

**2. [Rule 1 - Bug] ImageFilter unresolved after aliasing dart:ui in qr_library_screen.dart**
- **Found during:** Task 2 flutter analyze
- **Issue:** Original file used `import 'dart:ui'` (unaliased) for `ImageFilter`. Adding `import 'dart:ui' as ui` broke the 5 existing `ImageFilter.blur()` calls since they now need the `ui.` prefix.
- **Fix:** Retained both `import 'dart:ui';` (unaliased, for `ImageFilter`) and `import 'dart:ui' as ui;` (aliased, for `ui.Image`, `ui.PictureRecorder`, etc.)
- **Files modified:** qr_library_screen.dart
- **Commit:** `8bba9fa` (fixed before commit)

**3. [Rule 1 - Bug] Unnecessary dart:typed_data import in qr_library_screen.dart**
- **Found during:** Task 2 flutter analyze info
- **Issue:** `dart:typed_data` was added but all types already provided by `flutter/services.dart`
- **Fix:** Removed the `dart:typed_data` import
- **Files modified:** qr_library_screen.dart
- **Commit:** `8bba9fa` (fixed before commit)

**4. [Rule 1 - Bug] QrPainter deprecated color/emptyColor params**
- **Found during:** Task 2 flutter analyze info (2 deprecated_member_use infos)
- **Issue:** `QrPainter(color:, emptyColor:)` are deprecated in qr_flutter; replacement is `eyeStyle` + `dataModuleStyle`
- **Fix:** Replaced with `eyeStyle: QrEyeStyle(color:)` + `dataModuleStyle: QrDataModuleStyle(color:)`; white background still painted separately via `canvas.drawRect`
- **Files modified:** qr_library_screen.dart
- **Commit:** `8bba9fa` (fixed before commit)

## Threat Surface Scan

No new network endpoints or auth paths. PNG files are written to `Directory.systemTemp` (OS-managed, automatically purged) and shared via OS share sheet — no new PII storage. The shared image is a QR code the user explicitly chose to share.

## Known Stubs

None. QrShareButton is fully functional. Library share replaces the previous "share coming soon" stub completely.

## Verification

```
flutter analyze --no-fatal-warnings  → No issues found (0 errors, 0 warnings, 0 infos)
flutter build apk --debug            → Built build/app/outputs/flutter-apk/app-debug.apk
QrShareButton file exists            → FOUND at lib/features/qr_generator/presentation/widgets/qr_share_button.dart
QrShareButton in url_qr_screen       → FOUND (import + conditional rendering on isValid)
QrShareButton in text_qr_screen      → FOUND
QrShareButton in personal_info_qr    → FOUND
QrShareButton in wifi_qr_screen      → FOUND
QrShareButton in email_qr_screen     → FOUND
QrShareButton in location_qr_screen  → FOUND
QrShareButton in event_qr_screen     → FOUND
_shareQRCode in qr_library_screen    → FOUND (QrPainter PNG export — no longer a stub)
Semantics(identifier: 'qr_share_button') → FOUND in qr_share_button.dart
shareQR in app_en.arb                → FOUND ("Share QR")
shareQR in app_es.arb                → FOUND ("Compartir QR")
exportQRPng in app_en.arb            → FOUND ("Export as PNG")
exportQRPng in app_es.arb            → FOUND ("Exportar como PNG")
```

## Self-Check: PASSED

- [x] `lib/features/qr_generator/presentation/widgets/qr_share_button.dart` exists
- [x] `RenderRepaintBoundary` + `toImage(pixelRatio: 3.0)` present in qr_share_button.dart
- [x] `Share.shareXFiles` called with XFile(tmpFile.path)
- [x] `Semantics(identifier: 'qr_share_button')` wraps widget
- [x] All 6 QR screens import and use QrShareButton
- [x] `_shareQRCode` in qr_library_screen.dart uses QrPainter offscreen canvas → Share.shareXFiles
- [x] `shareQR` and `exportQRPng` present in both ARB files
- [x] `flutter analyze --no-fatal-warnings` = 0 issues
- [x] `flutter build apk --debug` succeeded
- [x] Commits `8bba9fa` and `a0e4da1` exist in git log
