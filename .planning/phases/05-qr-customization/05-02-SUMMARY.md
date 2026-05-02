---
phase: 05-qr-customization
plan: "02"
subsystem: qr-generation
tags: [flutter, pretty_qr_code, riverpod, domain-service, logo-embed, ec-h-enforcement]

requires:
  - phase: 05-qr-customization
    plan: "01"
    provides: QRCustomization entity with 9 Phase 5 fields, QrProfile enum with QrProfileConstraints

provides:
  - QrDecorationBuilder static service (buildDecoration + buildQrImage)
  - QrLogoPickerWidget with PNG/JPG whitelist and 2MB size gate
  - QRPreviewWidget upgraded to ConsumerStatefulWidget with QrImage in initState
  - 11 unit tests for QrDecorationBuilder (coverage clamping, EC-H enforcement, null guards)

affects:
  - 05-03-qr-gradients-and-module-shapes (extends QrDecorationBuilder.buildDecoration shape field)
  - 05-04-qr-frame-and-export (uses QrDecorationBuilder as assembly point)
  - 05-05-qr-templates (same)

tech-stack:
  added: []
  patterns:
    - "QrDecorationBuilder static-only class as single wiring layer between QRCustomization and pretty_qr_code API"
    - "QrImage built in initState/didUpdateWidget never in build() — prevents per-frame regeneration"
    - "logo coverage double-clamp: controller clamps at write (05-01), builder clamps at render (05-02)"
    - "EC-H forced at render time when hasLogo=true regardless of stored errorCorrectionLevel"
    - "PrettyQrQuietZone.standard (never .standart — deprecated typo alias)"

key-files:
  created:
    - lib/features/qr_generator/domain/services/qr_decoration_builder.dart
    - lib/features/qr_generator/presentation/widgets/qr_logo_picker.dart
    - test/features/qr_generator/domain/qr_decoration_builder_test.dart
  modified:
    - lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart

key-decisions:
  - "QrImage created via QrCode.fromData then QrImage(qrCode) — not PrettyQrView.data — so EC level is fully under our control"
  - "foregroundColor/backgroundColor params kept on QRPreviewWidget but marked @Deprecated; rendering uses QrDecorationBuilder.buildDecoration which enforces white background"
  - "qr package import removed from QrDecorationBuilder — QrErrorCorrectLevel re-exported by pretty_qr_code, avoiding depend_on_referenced_packages lint"
  - "Empty data guard (space substitution) prevents QrCode.fromData crash on blank user input"

metrics:
  duration: ~33min
  completed: 2026-05-02T18:32:35Z
  tasks: 2 (Task 1 TDD RED+GREEN, Task 2 standard)
  files-modified: 4 (1 modified, 3 created)
---

# Phase 5 Plan 02: QrDecorationBuilder + Logo Picker + Preview Upgrade Summary

**QrDecorationBuilder factory wiring QRCustomization to pretty_qr_code API, logo picker with file validation, and QRPreviewWidget upgraded to ConsumerStatefulWidget with QrImage in initState**

## Performance

- **Duration:** ~33 min
- **Started:** 2026-05-02T18:32:35Z
- **Completed:** 2026-05-02T19:05:06Z
- **Tasks:** 2 (Task 1 TDD RED+GREEN, Task 2 standard)
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- `QrDecorationBuilder` static service assembles `PrettyQrDecoration` from `QRCustomization`: always white background, always `PrettyQrQuietZone.standard`, logo with coverage clamped to `QrProfile.maxLogoScale`
- `buildQrImage` forces EC level H when `hasLogo=true`, maps 0-3 integers to L/M/Q/H otherwise; empty data guard prevents crash
- `QrLogoPickerWidget` opens image gallery via `image_picker`, enforces PNG/JPG whitelist (T-05-02-01), rejects files >2MB (T-05-02-02), shows user-facing SnackBar errors, has Semantics identifier
- `QRPreviewWidget` converted to `ConsumerStatefulWidget` — `QrImage` built in `initState` and `didUpdateWidget` (never in `build()`); uses `QrDecorationBuilder.buildDecoration(customization)` via `PrettyQrView`
- 11 unit tests covering all clamping, EC enforcement, and null-guard behaviors
- `flutter analyze lib/ = 0 issues`; debug APK build succeeds

## Task Commits

1. **Task 1 RED: Failing QrDecorationBuilder tests** - `5254012` (test)
2. **Task 1 GREEN: QrDecorationBuilder implementation** - `36c7873` (feat)
3. **Task 2: QrLogoPickerWidget + QRPreviewWidget upgrade** - `37b0327` (feat)

## Files Created/Modified

- `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` — static factory: `buildDecoration(QRCustomization)` returns `PrettyQrDecoration`, `buildQrImage(String, QRCustomization)` returns `QrImage`
- `lib/features/qr_generator/presentation/widgets/qr_logo_picker.dart` — logo picker with PNG/JPG validation, 2MB size gate, CircleAvatar preview, remove button
- `lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart` — upgraded to `ConsumerStatefulWidget`; `QrImage` in initState; `PrettyQrView` wired via `QrDecorationBuilder`
- `test/features/qr_generator/domain/qr_decoration_builder_test.dart` — 11 tests: background color, quiet zone, logo null guards, coverage clamping (printSafe/tattooSafe), EC-H forcing, EC passthrough, empty-data guard

## Decisions Made

- `QrImage` created via `QrCode.fromData()` + `QrImage(qrCode)` pattern (not `PrettyQrView.data()`) to retain full control over EC level at build time
- Direct `package:qr/qr.dart` import removed from `QrDecorationBuilder` — `pretty_qr_code` re-exports all needed QR symbols; keeping it caused `depend_on_referenced_packages` lint error
- `foregroundColor`/`backgroundColor` widget params kept (marked `@Deprecated`) for backward API compatibility; they are never used in rendering
- Empty input to `buildQrImage` substituted with a single space to prevent `QrCode.fromData` crash (guard is tested)

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

Task 1 followed RED/GREEN cycle:
- RED: `5254012` (test) — 11 tests failing with "Undefined name 'QrDecorationBuilder'"
- GREEN: `36c7873` (feat) — all 11 tests pass

## Known Stubs

None — `QrDecorationBuilder.buildDecoration` returns a real `PrettyQrDecoration` wired to `QrDecorationBuilder.buildQrImage` output. `QRPreviewWidget` renders live QR via `PrettyQrView`. No placeholder or hardcoded data.

## Threat Flags

No new threat surface beyond what was documented in the plan's threat model (T-05-02-01 through T-05-02-04). T-05-02-01 and T-05-02-02 are mitigated in `QrLogoPickerWidget`. T-05-02-03 is mitigated in `QrDecorationBuilder._buildImage`. T-05-02-04 accepted.

## Self-Check: PASSED

- FOUND: `lib/features/qr_generator/domain/services/qr_decoration_builder.dart`
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_logo_picker.dart`
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart`
- FOUND: `test/features/qr_generator/domain/qr_decoration_builder_test.dart`
- FOUND commit: `5254012` (RED gate)
- FOUND commit: `36c7873` (GREEN gate)
- FOUND commit: `37b0327` (Task 2)
- No unexpected file deletions in any commit

---
*Phase: 05-qr-customization*
*Completed: 2026-05-02*
