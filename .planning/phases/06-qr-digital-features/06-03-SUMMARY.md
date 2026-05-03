---
phase: 06-qr-digital-features
plan: 03
subsystem: qr-digital, ai-stylize, mobile-scanner
tags: [ai, replicate, controlnet, scannability-gate, mobile-scanner, supabase-edge-function, riverpod, tdd]
dependency_graph:
  requires:
    - 06-01 (ai-stylize Edge Function deployed, exportDigitalOnly on QrExportService)
    - 06-02 (QrDigitalController StateNotifier, supabaseClientProvider)
  provides:
    - QrAiStyleResult entity (imageBytes + scanOk)
    - QrAiStyleService.stylize() — Edge Function proxy + scannability gate
    - QrAiStylePage — prompt input, 8 style presets, result preview, gated Save
    - QrDigitalController extended with generateAiStyle() + AI style state fields
  affects:
    - lib/features/qr_digital/domain/entities/qr_ai_style_result.dart
    - lib/features/qr_digital/domain/services/qr_ai_style_service.dart
    - lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart
    - lib/features/qr_digital/presentation/pages/qr_ai_style_page.dart
    - test/features/qr_digital/services/qr_ai_style_service_test.dart
    - pubspec.yaml (http, path_provider added as direct deps)
tech_stack:
  added:
    - http ^1.2.0 (direct dependency — Replicate CDN image download)
    - path_provider ^2.1.2 (direct dependency — temp file for scannability gate)
  patterns:
    - TDD RED/GREEN cycle (wave-0 sentinel replaced with real tests)
    - analyzeImageOverride + httpGetOverride injection for testability
    - Domain whitelist: replicate.delivery / pbxt.replicate.delivery (T-06-09)
    - Double-layer profile guard: service exception + UI banner/disable (T-06-11)
    - share_plus v10: Share.shareXFiles() API
key_files:
  created:
    - lib/features/qr_digital/domain/entities/qr_ai_style_result.dart
    - lib/features/qr_digital/domain/services/qr_ai_style_service.dart
    - lib/features/qr_digital/presentation/pages/qr_ai_style_page.dart
  modified:
    - lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart
    - test/features/qr_digital/services/qr_ai_style_service_test.dart
    - pubspec.yaml
decisions:
  - "analyzeImageOverride callback injected into stylize() for testability — avoids needing platform-native MobileScannerController in unit tests"
  - "httpGetOverride callback injected into stylize() for testability — avoids real HTTP calls in unit tests"
  - "http and path_provider added as direct deps in pubspec.yaml (were transitive) to satisfy depend_on_referenced_packages lint rule"
  - "share_plus v10 API used: Share.shareXFiles() — matches pattern established in plan 06-02"
  - "QrAiStylePage receives qrStorageUrl as constructor parameter — caller provides pre-uploaded URL to avoid needing upload logic in the page"
  - "Style preset chips apply promptSuffix to the text field rather than overriding — users can still edit after selecting a preset"
metrics:
  duration: "4m 46s"
  completed: "2026-05-03T13:51:29Z"
  tasks_completed: 2
  files_created: 3
  files_modified: 3
---

# Phase 6 Plan 3: AI-Stylized QR via Replicate ControlNet Summary

One-liner: Replicate ControlNet QR stylization via Supabase Edge Function proxy with domain-whitelisted image download, mobile_scanner scannability gate, and a profile-guarded Carden Pro dark UI with 8 style presets.

## What Was Built

### Task 1 — QrAiStyleResult entity + QrAiStyleService (commits d7848d1, 69d3798)

**TDD RED (d7848d1):** Replaced the wave-0 sentinel in `test/features/qr_digital/services/qr_ai_style_service_test.dart` with 7 real failing tests covering all behavior cases.

**TDD GREEN (69d3798):**

`lib/features/qr_digital/domain/entities/qr_ai_style_result.dart`:
- `QrAiStyleResult` with `imageBytes: Uint8List` + `scanOk: bool`

`lib/features/qr_digital/domain/services/qr_ai_style_service.dart`:

**`QrAiStyleException`** — typed exception with codes:
- `wrong_profile` — profile is not digitalOnly
- `monthly_limit_reached` — Edge Function returned 429
- `replicate_failed` — 5xx or Replicate prediction failed
- `invalid_image_source` — output URL not on allow-listed domain
- `network_error` — unexpected exception

**`QrAiStyleService.stylize()`** flow:
1. Profile guard: throws `wrong_profile` if `profile != 1` (T-06-11)
2. Prompt truncation at 200 chars (T-06-08)
3. POST to `ai-stylize` Edge Function — handles 429 / 5xx
4. Poll with `{prediction_id}` every 3 s, 90 s timeout, handles `succeeded`/`failed`/`canceled`
5. Domain whitelist check: `replicate.delivery` or `pbxt.replicate.delivery` only (T-06-09)
6. Download image bytes via `http.get` (or `httpGetOverride` in tests)
7. Scannability gate: write to `getTemporaryDirectory()/ai_scan_check.png`, call `MobileScannerController.analyzeImage()`, cleanup (or `analyzeImageOverride` in tests)
8. Return `QrAiStyleResult(imageBytes, scanOk)`

**Unit tests (7/7 passing):**
- `QrAiStyleResult` entity: scanOk=true for non-empty, scanOk=false for empty
- `stylize()` 429 → `monthly_limit_reached` exception
- `stylize()` 500 → `replicate_failed` exception
- `stylize()` succeeded + barcodes → `QrAiStyleResult(scanOk: true)`
- `stylize()` succeeded + empty barcodes → `QrAiStyleResult(scanOk: false)`
- `stylize()` profile=0 → `wrong_profile` exception
- `stylize()` profile=2 → `wrong_profile` exception

### Task 2 — QrDigitalController + QrAiStylePage (commit f877e31)

**`QrDigitalController` extended** (`qr_digital_controller.dart`):
- New `QrDigitalState` fields: `isStylizing`, `aiStyleResult`, `aiStyleError`
- New `generateAiStyle(prompt, client, qrStorageUrl)` method: sets `isStylizing=true`, calls `QrAiStyleService.stylize()`, sets result or error, always resets `isStylizing=false` in finally

**`QrAiStylePage`** — `ConsumerStatefulWidget`:
- **Profile guard banner**: amber container with "AI Style requires Digital-Only profile. Change profile in the QR editor." — disables all interactive elements
- **Usage counter**: "5 free AI styles / month" label
- **Prompt field**: single-line `TextField`, hint text, 200 char max, `Semantics(identifier: 'ai_style_prompt_field')`
- **8 style preset chips**: Woodblock, Art Nouveau, Cyberpunk, Watercolor, Pencil Sketch, Oil Painting, Geometric, Minimal — animated selection with neon border
- **Generate button**: neon gradient `#00FF88→#00CC6A`, `CircularProgressIndicator` during `isStylizing`, `Semantics(identifier: 'ai_style_generate_button')`
- **Progress row**: `LinearProgressIndicator` + "Generating… (~26s)" text
- **Result preview**: `Image.memory` in 312×312 `#2E2E2E` card (280×280 image)
- **Scannability chip**: green "Scannable ✓" or red "Not scannable — try a different prompt"
- **Save button**: enabled only when `scanOk==true`; calls `Share.shareXFiles` with `image/png`; `Semantics(identifier: 'ai_style_save_button')`
- **Error SnackBar**: `monthly_limit_reached` → upgrade message; others → generic code display

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `http` and `path_provider` needed as direct dependencies**

- **Found during:** Task 1 GREEN — `flutter analyze` reported `depend_on_referenced_packages` for both packages
- **Issue:** Both packages were available as transitive deps (via supabase_flutter and mobile_scanner) but the `depend_on_referenced_packages` lint rule requires directly imported packages to be declared as direct dependencies
- **Fix:** Added `http: ^1.2.0` and `path_provider: ^2.1.2` to `dependencies` in `pubspec.yaml`
- **Files modified:** `pubspec.yaml`, `pubspec.lock`
- **Commit:** 69d3798

**2. [Rule 1 - Bug] `const QrAiStyleResult(imageBytes: Uint8List(0))` not valid**

- **Found during:** Task 1 RED — Dart `Uint8List(0)` is not a `const` expression
- **Issue:** Test used `const` on `QrAiStyleResult` with a `Uint8List(0)` field; `Uint8List` constructor is not const
- **Fix:** Changed `const result = QrAiStyleResult(...)` to `final result = QrAiStyleResult(...)` in the test
- **Files modified:** `test/features/qr_digital/services/qr_ai_style_service_test.dart`
- **Commit:** 69d3798

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED  | d7848d1 | Confirmed — compilation errors (entity/service missing) |
| GREEN | 69d3798 | Confirmed — 7/7 tests pass |
| REFACTOR | N/A | No refactoring needed |

## Known Stubs

None — all plan artifacts are fully implemented.

`test/features/qr_digital/services/qr_widget_service_test.dart` remains a wave-0 sentinel — it is out of scope for this plan (plan 06-04 will replace it).

## Threat Surface Scan

All STRIDE threats from the plan's threat model were addressed:

| Threat ID | Mitigation | File |
|-----------|-----------|------|
| T-06-08 | Prompt truncated at 200 chars before Edge Function call | `qr_ai_style_service.dart:58` |
| T-06-09 | Domain whitelist: `_isAllowedImageUrl()` checks `replicate.delivery` / `pbxt.replicate.delivery` | `qr_ai_style_service.dart:38-46` |
| T-06-10 | 429 response → `monthly_limit_reached` exception → SnackBar upgrade prompt in UI | `qr_ai_style_service.dart`, `qr_ai_style_page.dart` |
| T-06-11 | Double-layer: `wrong_profile` exception in service + amber banner + disabled controls in UI | `qr_ai_style_service.dart:62`, `qr_ai_style_page.dart` |
| T-06-12 | Save button disabled in Flutter when `scanOk=false`; server does not store — client controls share | `qr_ai_style_page.dart` |

No new threat surface introduced beyond what the plan's threat model covers.

## Self-Check: PASSED

- `lib/features/qr_digital/domain/entities/qr_ai_style_result.dart` — contains `QrAiStyleResult`: FOUND
- `lib/features/qr_digital/domain/services/qr_ai_style_service.dart` — contains `ai-stylize`: FOUND
- `lib/features/qr_digital/presentation/pages/qr_ai_style_page.dart` — contains `QrAiStylePage`: FOUND
- `test/features/qr_digital/services/qr_ai_style_service_test.dart` — contains `scanOk`: FOUND
- Commit d7848d1: FOUND in git log (RED phase)
- Commit 69d3798: FOUND in git log (GREEN phase)
- Commit f877e31: FOUND in git log (Task 2)
- `flutter analyze --no-fatal-warnings`: 0 issues
- `flutter test test/features/qr_digital/services/qr_ai_style_service_test.dart`: 7/7 passed
