---
phase: 12-premium-polish-ga
plan: "02"
subsystem: observability
tags: [crashlytics, analytics, firebase, error-handling, monitoring]
dependency_graph:
  requires: [12-01]
  provides: [ObservabilityService]
  affects: [main.dart, payment_result_screen, orders_list_screen, qr_generator_controller]
tech_stack:
  added: []
  patterns: [singleton-facade, error-handler-wiring, analytics-breadcrumbs]
key_files:
  created:
    - lib/core/services/observability_service.dart
  modified:
    - lib/main.dart
    - lib/features/checkout/presentation/pages/payment_result_screen.dart
    - lib/features/orders/presentation/pages/orders_list_screen.dart
    - lib/features/qr_generator/presentation/controllers/qr_generator_controller.dart
decisions:
  - Analytics logEvent suppressed in kDebugMode to avoid polluting production dashboards
  - qr_created event added to QRGeneratorController.generateQR() (not QRCustomizationController which has no save method)
  - PlatformDispatcher import from dart:ui (not flutter/foundation) for non-framework Dart errors
metrics:
  duration: "10 minutes"
  completed: "2026-05-03"
  tasks: 2
  files: 5
---

# Phase 12 Plan 02: Firebase Crashlytics + Analytics Activation Summary

**One-liner:** ObservabilityService facade wires FlutterError + PlatformDispatcher error handlers to Crashlytics, and logs qr_created + payment_complete analytics events in key user flows.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | ObservabilityService + error handler wiring in main.dart | 0597a96 | observability_service.dart, main.dart |
| 2 | Analytics events in payment + QR creation; non-fatal capture | 0597a96 | payment_result_screen.dart, orders_list_screen.dart, qr_generator_controller.dart |

## Decisions Made

- **PlatformDispatcher** imported from `dart:ui` (not `flutter/foundation`) — required for `PlatformDispatcher.instance.onError` which catches Dart isolate errors outside the Flutter widget tree.
- **qr_created event** placed in `QRGeneratorController.generateQR()` rather than `QRCustomizationController` — the customization controller only manages UI state, actual Supabase persistence happens in the generator controller.
- **Non-fatal crash reporting** uses `recordNonFatal` pattern with explicit context keys; no PII (no email, phone, payment card data) is logged per T-12-05/T-12-06.
- **firebase_performance package** not in pubspec.yaml — skipped per plan guidance; Crashlytics + Analytics fulfill OPT-03.

## Deviations from Plan

**[Rule 3 - Blocking] PlatformDispatcher requires dart:ui import**
- Found during: Task 1
- Issue: `PlatformDispatcher` undefined without `import 'dart:ui'`
- Fix: Added `import 'dart:ui'` to main.dart
- Files modified: lib/main.dart

**[Deviation - File] qr_created event added to QRGeneratorController, not QRCustomizationController**
- The plan specified `qr_customization_controller.dart` but that controller has no save method.
- The `saveQr()` / persistence happens in `QRGeneratorController.generateQR()`.
- Same behavioral outcome — event fires on successful QR save.

## Known Stubs

None.

## Known Gaps

firebase_performance package is not in pubspec.yaml. Performance monitoring auto-traces not activated. OPT-03 is covered by Crashlytics + Analytics per plan guidance.

## Threat Flags

None beyond those in the plan's threat register (T-12-05, T-12-06, T-12-07).

## Self-Check: PASSED

- `lib/core/services/observability_service.dart` — FOUND
- `grep -c "ObservabilityService.onFlutterError" lib/main.dart` returns 1 — PASS
- `grep -c "logEvent" lib/features/checkout/presentation/pages/payment_result_screen.dart` returns 1 — PASS
- `grep -c "logEvent" lib/features/qr_generator/presentation/controllers/qr_generator_controller.dart` returns 1 — PASS
- No unguarded print() in modified files — PASS
- Commit 0597a96 — FOUND
- `flutter analyze` — 0 issues
