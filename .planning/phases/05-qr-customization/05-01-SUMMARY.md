---
phase: 05-qr-customization
plan: "01"
subsystem: qr-generation
tags: [flutter, pretty_qr_code, riverpod, material3, domain-entity, validator]

requires:
  - phase: 01-mvp
    provides: QRCustomization entity and QRCustomizationController (StateNotifier) wired in all QR screens

provides:
  - QrProfile enum (printSafe/digitalOnly/tattooSafe) with per-profile constraint extensions
  - GradientType enum (solid/linear/radial)
  - QrProfileValidator domain service with logo cap and dark-on-light enforcement
  - QrValidationResult with isValid getter
  - QRCustomization extended with 9 new Phase 5 fields (backward-compatible defaults)
  - QRCustomizationController extended with 6 new methods (updateProfile, updateModulePreset, updateEyePreset, updateGradient, updateFrameText, updateLogoCoverage)
  - QrProfileToggle widget: 3-segment SegmentedButton for profile selection

affects:
  - 05-02-qr-gradients-and-module-shapes
  - 05-03-qr-logo-embed
  - 05-04-qr-frame-and-export
  - 05-05-qr-templates

tech-stack:
  added: []
  patterns:
    - "QrProfileConstraints extension on enum for per-profile max/flag lookup"
    - "copyWith nullable clearance via module-level const _sentinelRef = Object()"
    - "updateLogoCoverage clamps to profile.maxLogoScale before storing (T-05-01-01)"
    - "updateProfile auto-enforces EC-H when profile.requiresEcH is true"
    - "GradientType.solid as default means zero-field change for existing QRs"

key-files:
  created:
    - lib/features/qr_generator/domain/value_objects/qr_profile.dart
    - lib/features/qr_generator/domain/services/qr_profile_validator.dart
    - lib/features/qr_generator/presentation/widgets/qr_profile_toggle.dart
    - test/features/qr_generator/domain/qr_profile_validator_test.dart
    - test/features/qr_generator/presentation/controllers/qr_customization_controller_phase5_test.dart
  modified:
    - lib/features/qr_generator/domain/entities/qr_code_entity.dart
    - lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart

key-decisions:
  - "profile stored as int (index) in QRCustomization for Equatable/JSON compat; QrProfile.values[profile] used in controller"
  - "logoCoverage clamp enforced at controller entry point (updateLogoCoverage), not just at validator, satisfying T-05-01-01 first-line defense"
  - "updateGradient(hasGradient: false) uses full QRCustomization constructor to explicitly null gradientStart/gradientEnd — sentinel pattern cannot be used with const defaults in this context"
  - "updateFrameText uses full constructor for same reason as above"
  - "updateLogo initialises logoCoverage to 0.15 (within all profile caps) when logo first added with coverage=0.0"

patterns-established:
  - "Profile-aware controller: updateProfile() side-effects EC level for print/tattoo safety"
  - "Sentinel clearance pattern: const _sentinelRef = Object() at module level for copyWith nullable fields"

requirements-completed: [QR-10]

duration: ~25min
completed: 2026-05-01
---

# Phase 5 Plan 01: QrProfile + Entity Extension + Controller + Toggle Summary

**QrProfile enum, QrProfileValidator domain service, 9-field QRCustomization extension, 6 new controller methods, and QrProfileToggle widget — the foundation all Phase 5 plans depend on**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-01T00:00:00Z
- **Completed:** 2026-05-01T17:14:43Z
- **Tasks:** 2 (both TDD)
- **Files modified:** 7 (2 extended, 3 created domain/widget, 2 test files)

## Accomplishments

- QrProfile enum with printSafe/digitalOnly/tattooSafe values and QrProfileConstraints extension (maxLogoScale, requiresDarkOnLight, requiresEcH)
- QrProfileValidator enforces logo coverage cap and dark-on-light color requirement; 8 unit tests covering all profile/constraint combinations
- QRCustomization extended with 9 new fields (hasGradient, gradientStart, gradientEnd, gradientType, modulePreset, eyePreset, profile, frameText, logoCoverage) with backward-compatible defaults
- QRCustomizationController extended with 6 new methods; updateLogoCoverage clamps to profile cap (T-05-01-01); updateProfile auto-enforces EC-H
- QrProfileToggle: Material 3 SegmentedButton with Semantics(identifier: 'qr_profile_toggle')

## Task Commits

1. **Task 1 RED: Failing validator tests** - `c2f992b` (test)
2. **Task 1 GREEN: QrProfile enum + QrProfileValidator + entity extension** - `19bdca9` (feat)
3. **Task 2 RED: Failing controller tests** - `d61a72f` (test)
4. **Task 2 GREEN: Extended controller + QrProfileToggle widget** - `f34f456` (feat)

## Files Created/Modified

- `lib/features/qr_generator/domain/value_objects/qr_profile.dart` - QrProfile + GradientType enums with QrProfileConstraints extension
- `lib/features/qr_generator/domain/services/qr_profile_validator.dart` - QrProfileValidator static service + QrValidationResult
- `lib/features/qr_generator/domain/entities/qr_code_entity.dart` - QRCustomization extended with 9 Phase 5 fields + copyWith sentinel pattern
- `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` - 6 new methods added; updateLogo extended; all existing methods preserved
- `lib/features/qr_generator/presentation/widgets/qr_profile_toggle.dart` - 3-segment SegmentedButton widget with Semantics identifier
- `test/features/qr_generator/domain/qr_profile_validator_test.dart` - 8 unit tests for all validation rules
- `test/features/qr_generator/presentation/controllers/qr_customization_controller_phase5_test.dart` - 16 unit tests for Phase 5 controller methods

## Decisions Made

- profile stored as `int` index in QRCustomization entity for Equatable props and future JSON serialisation compatibility; controllers and validators convert via `QrProfile.values[index]`
- `logoCoverage` clamped at controller entry (updateLogoCoverage) before storing, providing first-line defence as required by T-05-01-01; QrProfileValidator provides second-line check at export time
- `updateGradient(hasGradient: false)` uses full QRCustomization constructor to explicitly set `gradientStart`/`gradientEnd` to null — the sentinel copyWith pattern does not accept non-Object? values
- `updateFrameText(null)` uses same full-constructor approach for explicit null clearance
- GradientType.solid as default value means all existing QRCustomization instances are unchanged (zero migration cost)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Pre-existing test failures in `test/features/qr_generator/presentation/pages/location_qr_screen_test.dart` and `test/features/qr_scanner/qr_scanner_lifecycle_test.dart` were confirmed to pre-date this plan (failed identically on HEAD before changes). These are out-of-scope and logged to deferred items.

## TDD Gate Compliance

Both tasks followed RED/GREEN cycle:
- Task 1: `c2f992b` (test/RED) → `19bdca9` (feat/GREEN)
- Task 2: `d61a72f` (test/RED) → `f34f456` (feat/GREEN)

RED gate: tests failed before implementation. GREEN gate: all tests pass after implementation.

## Known Stubs

None — no UI data stubs or placeholder values introduced. All fields have correct functional defaults.

## Threat Flags

No new threat surface introduced beyond what was documented in the plan's threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 5 plans 02-05 can now proceed: QRCustomization has all fields they need
- QrProfile and GradientType are available for import
- QrProfileValidator ready for use in export pipeline (plan 04)
- QrProfileToggle ready for embedding in customization screens (plan 02+)

---
*Phase: 05-qr-customization*
*Completed: 2026-05-01*
