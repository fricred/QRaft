---
phase: 05-qr-customization
plan: "03"
subsystem: qr-generation
tags: [flutter, pretty_qr_code, gradient, export, color-picker, tdd]

requires:
  - phase: 05-qr-customization
    plan: "01"
    provides: GradientType enum, QRCustomization with hasGradient/gradientStart/gradientEnd fields
  - phase: 05-qr-customization
    plan: "02"
    provides: QrDecorationBuilder class (additive — buildBrush added as new static method)

provides:
  - QrDecorationBuilder.buildBrush(QRCustomization) — returns Color or PrettyQrBrush.gradient
  - QrExportService.exportPrintSafe(QrImage, PrettyQrDecoration) — 2160px print-safe PNG export
  - QrColorPickerWidget — 8 Carden Pro preset swatches + validated hex input field
  - 4 new unit tests for buildBrush coverage (15 total in decoration builder test suite)

affects:
  - 05-04-qr-frame-and-export (integrates buildBrush into shape field of buildDecoration)
  - 05-05-qr-templates (uses QrExportService for template export)

tech-stack:
  added: []
  patterns:
    - "PrettyQrBrush.gradient() factory for LinearGradient/RadialGradient — extends solid Color subtype"
    - "QrImage.toImageAsBytes() for widget-tree-independent export (not RepaintBoundary)"
    - "exportPrintSafe forces white background via copyWith — theme bypass prevented (T-05-03-04)"
    - "Hex color input validated with RegExp(^[0-9A-Fa-f]{6}$) before int.parse — no parse on invalid (T-05-03-01)"
    - "TDD RED/GREEN cycle: failing tests committed before implementation"

key-files:
  created:
    - lib/features/qr_generator/domain/services/qr_export_service.dart
    - lib/features/qr_generator/presentation/widgets/qr_color_picker.dart
  modified:
    - lib/features/qr_generator/domain/services/qr_decoration_builder.dart
    - test/features/qr_generator/domain/qr_decoration_builder_test.dart

key-decisions:
  - "buildBrush return type is dynamic — PrettyQrBrush extends Color so it IS a Color at runtime; plan 05-04 casts to PrettyQrBrush when wiring into shape constructor"
  - "GradientType.solid falls through to plain Color(foregroundColor) even with hasGradient=true (defensive consistency)"
  - "QrColorPickerWidget uses toARGB32() for color equality (Color.value deprecated in current Flutter SDK)"
  - "QrExportService size fixed at 2160px — not user-controllable — so DoS via size parameter is impossible (T-05-03-02 accepted)"
  - "RepaintBoundary mention in doc comment uses [NOT RepaintBoundary] pattern — clarifies architectural intent without using the API"

metrics:
  duration: ~83min
  completed: 2026-05-02T21:28:51Z
  tasks: 2 (Task 1 TDD RED+GREEN, Task 2 standard)
  files-modified: 4 (2 created, 2 modified)
---

# Phase 5 Plan 03: Gradient Brush, Export Service, and Color Picker Summary

**buildBrush() extending QrDecorationBuilder with LinearGradient/RadialGradient via PrettyQrBrush.gradient, print-safe 2160px PNG export using QrImage.toImageAsBytes, and 8-preset Carden Pro color picker with regex-validated hex input**

## Performance

- **Duration:** ~83 min
- **Started:** 2026-05-02T20:05:58Z
- **Completed:** 2026-05-02T21:28:51Z
- **Tasks:** 2 (Task 1 TDD RED+GREEN, Task 2 standard)
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- `QrDecorationBuilder.buildBrush()` extends the existing class as a new static method: returns `Color(foregroundColor)` for solid fills, `PrettyQrBrush.gradient(LinearGradient)` for linear, `PrettyQrBrush.gradient(RadialGradient)` for radial; null-guard falls back to Color when gradientStart/gradientEnd missing
- `QrExportService.exportPrintSafe()` uses `qrImage.toImageAsBytes(size: 2160)` directly — no RepaintBoundary dependency; forces white background via `copyWith(background: Colors.white)` regardless of in-app theme (T-05-03-04 mitigated)
- `QrColorPickerWidget` shows 8 Carden Pro preset swatches with active border ring, plus a `TextFormField` hex input validated by `^[0-9A-Fa-f]{6}$` before any `Color` is constructed (T-05-03-01 mitigated)
- 15 total tests in decoration builder suite (11 existing + 4 new buildBrush tests), all green
- `flutter analyze lib/features/qr_generator/` = 0 issues

## Task Commits

1. **Task 1 RED: Failing buildBrush tests** - `ae4e1a5` (test)
2. **Task 1 GREEN: buildBrush + QrExportService implementation** - `23cebed` (feat)
3. **Task 2: QrColorPickerWidget** - `14ccacc` (feat)

## Files Created/Modified

- `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` — `buildBrush(QRCustomization)` added as new static method; `buildDecoration` unchanged (plan 05-04 integrates brush into shape)
- `lib/features/qr_generator/domain/services/qr_export_service.dart` — static `exportPrintSafe(QrImage, PrettyQrDecoration)` returns `Uint8List`; `QrExportException` for null byte data
- `lib/features/qr_generator/presentation/widgets/qr_color_picker.dart` — `QrColorPickerWidget` with 8 presets, `_SwatchCircle` private widget, hex `TextFormField` with regex validation
- `test/features/qr_generator/domain/qr_decoration_builder_test.dart` — 4 new `buildBrush` tests added to existing suite

## Decisions Made

- `buildBrush` return type is `dynamic`: `PrettyQrBrush` extends `Color` so both are valid at runtime; plan 05-04 casts to `PrettyQrBrush` when wiring into `PrettyQrSmoothSymbol.color`
- `GradientType.solid` falls through to `Color(foregroundColor)` even when `hasGradient=true` for defensive consistency
- Color equality uses `toARGB32()` not `.value` — `.value` is deprecated in current Flutter SDK
- Export size fixed at 2160px — not a user parameter — so no DoS surface via size (T-05-03-02 accepted)

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

Task 1 followed RED/GREEN cycle:
- RED: `ae4e1a5` (test) — compilation fails with "Member not found: QrDecorationBuilder.buildBrush"
- GREEN: `23cebed` (feat) — all 15 tests pass

## Known Stubs

None — `buildBrush` returns real `PrettyQrBrush` instances. `QrExportService` calls real `toImageAsBytes` API. `QrColorPickerWidget` wires `onColorSelected` callback on each swatch tap and valid hex submit. No placeholder or hardcoded data.

## Threat Flags

No new threat surface beyond what was documented in the plan's threat model. T-05-03-01 mitigated in `QrColorPickerWidget._validateHex`. T-05-03-02 accepted (fixed size). T-05-03-03 accepted (display prefs). T-05-03-04 mitigated in `QrExportService.exportPrintSafe`.

## Self-Check: PASSED

- FOUND: `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` (contains buildBrush)
- FOUND: `lib/features/qr_generator/domain/services/qr_export_service.dart`
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_color_picker.dart`
- FOUND commit: `ae4e1a5` (RED gate)
- FOUND commit: `23cebed` (GREEN gate)
- FOUND commit: `14ccacc` (Task 2)
- No unexpected file deletions in any commit

---
*Phase: 05-qr-customization*
*Completed: 2026-05-02*
