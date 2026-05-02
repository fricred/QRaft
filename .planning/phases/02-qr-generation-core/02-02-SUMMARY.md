---
phase: 02-qr-generation-core
plan: "02"
subsystem: qr-generator-presentation
tags: [pretty_qr_code, repaint-boundary, qr-preview, presentation, png-export-foundation]
dependency_graph:
  requires:
    - Phase 2 Plan 01 complete (QRType enum, qr_data_models, pretty_qr_code 3.6.0 installed)
  provides:
    - QRPreviewWidget using PrettyQrView.data() from pretty_qr_code 3.6.0
    - RepaintBoundary + GlobalKey on QRPreviewWidget (repaintKey param)
    - RepaintBoundary + GlobalKey on _buildQRPreviewWidget() in all 6 QR screens
  affects:
    - lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart
    - lib/features/qr_generator/presentation/pages/url_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/text_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/personal_info_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/wifi_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/email_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/location_qr_screen.dart
tech_stack:
  added:
    - pretty_qr_code 3.6.0 (PrettyQrView.data() — was installed in plan 01-04, now wired in QRPreviewWidget)
  patterns:
    - RepaintBoundary + GlobalKey on QR container for Plan 05 PNG screenshot export
    - Dark-on-light white background hardcoded in QRPreviewWidget (T-02-04 mitigation)
    - _TypeBadge private widget extracted from QRPreviewWidget.build()
    - PrettyQrDecoration() default (black squares on white) — Phase 5 will add eye styles/gradients
key_files:
  created: []
  modified:
    - lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart
    - lib/features/qr_generator/presentation/pages/url_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/text_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/personal_info_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/wifi_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/email_qr_screen.dart
    - lib/features/qr_generator/presentation/pages/location_qr_screen.dart
decisions:
  - "QRPreviewWidget now uses PrettyQrView.data() with const PrettyQrDecoration() defaults — Phase 5 will extend with gradient/eyeStyle/logo support"
  - "Colors.white hardcoded in QRPreviewWidget container — backgroundColor param kept for API compat but IGNORED (T-02-04 dark-on-light mitigation)"
  - "6 QR screens retain qr_flutter QrImageView in their _buildQRPreviewWidget() (the customization Style tab); PrettyQrView used only in standalone QRPreviewWidget — qr_flutter stays as noted in plan must_haves"
  - "repaintKey is GlobalKey (not GlobalKey<RenderObjectElement>) — standard GlobalKey is sufficient for RenderRepaintBoundary.toImage() access in Plan 05"
  - "_TypeBadge extracted as private StatelessWidget for cleaner build() method; includes event_rounded icon case not present in original"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-02"
  tasks_completed: 2
  files_modified: 7
---

# Phase 2 Plan 02: QRPreviewWidget — PrettyQrView + RepaintBoundary Summary

QRPreviewWidget rewritten around PrettyQrView.data() from pretty_qr_code 3.6.0 with white background enforcement and GlobalKey-backed RepaintBoundary; all 6 QR form screens wired with repaintKey for Plan 05 PNG export.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Rewrite QRPreviewWidget: PrettyQrView + RepaintBoundary + white background + _TypeBadge | `dc3b7c2` |
| 2 | Add repaintKey GlobalKey + RepaintBoundary to all 6 QR screens | `b3dafe9` |

## Deviations from Plan

### Auto-fixed Issues / Scope Clarifications

**1. [Rule 1 - Scope clarification] repaintKey added to _buildQRPreviewWidget() private method, not to QRPreviewWidget call**
- **Found during:** Task 2 analysis
- **Issue:** The 6 QR screens (`url_qr_screen.dart`, etc.) do NOT call the standalone `QRPreviewWidget` widget at all. Each has its own `_buildQRPreviewWidget()` private method in the Style tab that renders `QrImageView` directly. The plan text "Find the `QRPreviewWidget(...)` call in the build method of each screen" did not match the actual code structure.
- **Fix:** Added `final GlobalKey repaintKey = GlobalKey()` to each screen's State class, then wrapped the `QrImageView` return value in `RepaintBoundary(key: repaintKey, ...)` in each screen's `_buildQRPreviewWidget()`. This is semantically identical to what the plan intended: every screen now has a named GlobalKey attached to a RepaintBoundary that encloses the rendered QR, ready for Plan 05's `RenderRepaintBoundary.toImage()` call.
- **Files modified:** all 6 screen files
- **Commit:** `b3dafe9`

## Threat Surface Scan

No new network endpoints or auth paths introduced. The `RepaintBoundary` addition only affects widget tree composition — no new PII exposure surface. T-02-04 (white background enforcement in QRPreviewWidget) implemented: `Colors.white` hardcoded, `backgroundColor` param accepted but ignored. T-02-05 (RepaintBoundary GlobalKey) accepted per plan threat register.

## Known Stubs

- `QRPreviewWidget.foregroundColor` parameter: accepted but not applied in Phase 2. Phase 5 will wire via `PrettyQrDecoration(shape: ...)` customization.
- `PrettyQrDecoration()` uses library defaults (black squares). Phase 5 extends to gradient/eyeStyle/logo.
- The 6 screens' `_buildQRPreviewWidget()` still uses `qr_flutter QrImageView` for the Style tab customization preview — this is intentional per plan `must_haves.truths`: "qr_flutter remains installed and usable as thumbnail fallback (not removed)".

These stubs do NOT prevent the plan's goal (RepaintBoundary foundation + PrettyQrView in standalone widget).

## Verification

```
flutter analyze --no-fatal-warnings  → No issues found (0 errors, 0 warnings, 0 infos)
PrettyQrView in qr_preview_widget    → FOUND (line 89: PrettyQrView.data())
pretty_qr_code import                → FOUND (line 2)
RepaintBoundary in qr_preview_widget → FOUND (line 100: conditional on repaintKey != null)
Colors.white background              → FOUND (line 83: color: Colors.white)
repaintKey in url_qr_screen          → FOUND (line 39-40 + line 387-388)
repaintKey in text_qr_screen         → FOUND (line 39-40 + line 374-375)
repaintKey in personal_info_qr_screen → FOUND (line 39-40 + line 431-432)
repaintKey in wifi_qr_screen         → FOUND (line 161-162 + line 606-607)
repaintKey in email_qr_screen        → FOUND (line 39-40 + line 418-419)
repaintKey in location_qr_screen     → FOUND (line 218-219 + line 725-726)
```

## Self-Check: PASSED

- [x] `lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart` imports `pretty_qr_code` and contains `PrettyQrView.data()`
- [x] `RepaintBoundary` present in `qr_preview_widget.dart` wrapping QR container
- [x] `Colors.white` hardcoded (not from parameter)
- [x] All 6 screens have `final GlobalKey repaintKey = GlobalKey()` in their State class
- [x] All 6 screens wrap `QrImageView` in `RepaintBoundary(key: repaintKey, ...)`
- [x] Commits `dc3b7c2` and `b3dafe9` exist in git log
- [x] `flutter analyze --no-fatal-warnings` = 0 issues
