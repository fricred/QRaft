---
phase: 05-qr-customization
plan: "04"
subsystem: qr-generation
tags: [flutter, pretty_qr_code, shapes, presets, tdd, gallery, frame]

requires:
  - phase: 05-qr-customization
    plan: "02"
    provides: QrDecorationBuilder.buildDecoration(), QrDecorationBuilder.buildQrImage()
  - phase: 05-qr-customization
    plan: "03"
    provides: QrDecorationBuilder.buildBrush(QRCustomization)

provides:
  - QrDecorationBuilder.buildShape(QRCustomization) — PrettyQrShape.custom with 8 module + 8 eye presets
  - QrDecorationBuilder._moduleSymbol(int, dynamic) — module preset factory (0-7)
  - QrDecorationBuilder._eyeSymbol(int, dynamic) — eye preset factory (0-7)
  - QrPresetGalleryWidget — horizontal scrollable 8+8 preset thumbnail gallery
  - QrFrameWidget — CTA frame wrapper with respected quiet zone
  - 4 new buildShape unit tests (19 total in decoration builder suite)
  - 3 frame widget tests (quiet zone invariant + padding + CTA text layout)

affects:
  - 05-05-qr-templates (uses QrDecorationBuilder.buildDecoration which now includes shape)
  - QRPreviewWidget (automatically picks up shape via buildDecoration — no changes needed)

tech-stack:
  added: []
  patterns:
    - "PrettyQrShape.custom @experimental — wrapped in try-catch; fallback to PrettyQrSquaresSymbol() (T-05-04-01)"
    - "Switch expression with _ fallback for out-of-range preset index — no RangeError (T-05-04-02)"
    - "QrFrameWidget never calls decoration.copyWith(quietZone:) — quiet zone invariant enforced (T-05-04-04)"
    - "TDD RED/GREEN cycle: failing test committed before buildShape implementation"

key-files:
  created:
    - lib/features/qr_generator/presentation/widgets/qr_preset_gallery.dart
    - lib/features/qr_generator/presentation/widgets/qr_frame_widget.dart
    - test/features/qr_generator/widgets/qr_frame_widget_test.dart
  modified:
    - lib/features/qr_generator/domain/services/qr_decoration_builder.dart

key-decisions:
  - "PrettyQrShape is abstract — fallback in catch block uses PrettyQrSquaresSymbol() not PrettyQrShape() (which would not compile)"
  - "PrettyQrDotsSymbol module presets (5-7) use unifiedFinderPattern:false — eye preset handles finder pattern separately via PrettyQrShape.custom finderPattern: param"
  - "QrFrameWidget does not accept quietZone parameter at all — decoration is passed through unchanged"
  - "PrettyQrGradientBrush extends Color so cast to Color is safe for symbol color param"

metrics:
  duration: ~55min
  completed: 2026-05-02T22:30:00Z
  tasks: 2 (Task 1 TDD RED+GREEN, Task 2 standard)
  files-modified: 4 (3 created, 1 modified)
---

# Phase 5 Plan 04: buildShape, Preset Gallery, and Frame Widget Summary

**buildShape() completing QrDecorationBuilder with 8 module + 8 eye presets via PrettyQrShape.custom @experimental, plus QrPresetGalleryWidget scrollable thumbnail gallery and QrFrameWidget CTA frame with ISO 18004 quiet zone invariant**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-05-02T21:35:00Z
- **Completed:** 2026-05-02T22:30:00Z
- **Tasks:** 2 (Task 1 TDD RED+GREEN, Task 2 standard)
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- `QrDecorationBuilder.buildShape()` assembles `PrettyQrShape.custom(moduleSymbol, finderPattern: eyeSymbol)` using 8-entry switch expressions for both module and eye presets; wrapped in try-catch with `PrettyQrSquaresSymbol()` fallback — cannot crash app regardless of @experimental API behavior (T-05-04-01)
- `buildDecoration()` now passes `shape: buildShape(c)` — all downstream renderers (QRPreviewWidget, QrExportService, QrFrameWidget) automatically get module/eye preset shapes
- `QrPresetGalleryWidget` renders two horizontal scrollable sections (Module shape, Eye style), each with 8 `_PresetCard` thumbnails (64×64 `PrettyQrView` with active neon green border); `Semantics(identifier: 'qr_preset_gallery')` for Maestro tests
- `QrFrameWidget` wraps `PrettyQrView` in a `Column` inside a bordered `Container`; 8px padding is outside QR bounds; CTA text below; decoration passed through unchanged — quiet zone invariant enforced (T-05-04-04)
- 19 total tests in decoration builder suite (15 existing + 4 new buildShape tests), all green
- 3 frame widget tests pass (CTA text below QR, container >= 8px padding, quiet zone invariant)
- `flutter analyze lib/features/qr_generator/` = 0 issues

## Task Commits

1. **Task 1 RED: Failing buildShape tests** - `29ebda1` (test)
2. **Task 1 GREEN: buildShape() + module/eye symbol factories** - `2ae992c` (feat)
3. **Task 2: QrPresetGalleryWidget + QrFrameWidget + tests** - `9492b35` (feat)

## Files Created/Modified

- `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` — `buildShape()` added, `_moduleSymbol()` and `_eyeSymbol()` private factories added, `buildDecoration()` updated to pass `shape: buildShape(c)`
- `lib/features/qr_generator/presentation/widgets/qr_preset_gallery.dart` — `QrPresetGalleryWidget` with `_PresetRow`, `_PresetCard`, `_MiniQrView` private widgets; 8 module + 8 eye preset thumbnails
- `lib/features/qr_generator/presentation/widgets/qr_frame_widget.dart` — `QrFrameWidget` with bordered container, CTA text below QR, 8px padding outside quiet zone
- `test/features/qr_generator/widgets/qr_frame_widget_test.dart` — 3 tests: CTA text layout, container padding, quiet zone invariant

## Decisions Made

- `PrettyQrShape` is abstract — catch fallback uses `PrettyQrSquaresSymbol()` not `const PrettyQrShape()` (which fails to compile because `PrettyQrShape` is abstract and cannot be directly instantiated)
- `PrettyQrDotsSymbol` module presets (5, 6, 7) explicitly set `unifiedFinderPattern: false` so the dots do not take over the finder patterns — the eye symbol via `finderPattern:` param handles them
- `QrFrameWidget` does not expose a `quietZone` parameter and does not call `decoration.copyWith(...)` — isolation enforced at the type level

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PrettyQrShape is abstract — cannot instantiate for fallback**
- **Found during:** Task 1 GREEN (compile error)
- **Issue:** Plan specified `return const PrettyQrShape()` as the try-catch fallback, but `PrettyQrShape` is an abstract class and cannot be instantiated directly
- **Fix:** Changed fallback to `return const PrettyQrSquaresSymbol()` — the Classic Square preset, which is always ISO 18004 safe
- **Files modified:** `lib/features/qr_generator/domain/services/qr_decoration_builder.dart`
- **Commit:** `2ae992c`

## Known Stubs

None — `QrPresetGalleryWidget` renders real `PrettyQrView` thumbnails with actual QR data. `QrFrameWidget` passes real `QrImage` and `PrettyQrDecoration` to `PrettyQrView`. No placeholders or hardcoded preview data that flows to production UI state.

## Threat Flags

No new threat surface beyond what was documented in the plan's threat model.

- T-05-04-01 mitigated: `buildShape()` wrapped in try-catch with safe fallback
- T-05-04-02 mitigated: switch `_` fallback for out-of-range preset indices
- T-05-04-03 accepted: `ctaText` rendered as plain `Text` widget — no injection surface
- T-05-04-04 mitigated: `QrFrameWidget` does not modify `decoration.quietZone`

## TDD Gate Compliance

Task 1 followed RED/GREEN cycle:
- RED: `29ebda1` (test) — compilation fails with "Member not found: QrDecorationBuilder.buildShape"
- GREEN: `2ae992c` (feat) — all 19 tests pass

## Self-Check: PASSED

- FOUND: `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` (contains buildShape)
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_preset_gallery.dart`
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_frame_widget.dart`
- FOUND: `test/features/qr_generator/widgets/qr_frame_widget_test.dart`
- FOUND commit: `29ebda1` (RED gate)
- FOUND commit: `2ae992c` (GREEN gate)
- FOUND commit: `9492b35` (Task 2)
- No unexpected file deletions in any commit

---
*Phase: 05-qr-customization*
*Completed: 2026-05-02*
