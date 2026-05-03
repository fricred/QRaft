---
phase: 06-qr-digital-features
plan: 01
subsystem: qr-export, edge-functions, test-infrastructure
tags: [export, replicate, ai-stylize, mobile-scanner, supabase-edge-function, wave-0-scaffolds]
dependency_graph:
  requires: []
  provides:
    - exportDigitalOnly() on QrExportService
    - supabase/functions/ai-stylize Edge Function
    - QrAnimationService stub with analyzeImage API docs
    - Wave-0 test sentinels for plans 06-02, 06-03, 06-04
  affects:
    - lib/features/qr_generator/domain/services/qr_export_service.dart
    - lib/features/qr_digital/domain/services/qr_animation_service.dart
    - supabase/functions/ai-stylize/index.ts
    - test/features/qr_digital/services/
tech_stack:
  added:
    - Supabase Edge Function (Deno runtime) — ai-stylize
    - Replicate REST API proxy pattern (zylim0702/qr_code_controlnet)
  patterns:
    - Static-only service pattern (QrExportService)
    - TDD wave-0 sentinel pattern (intentionally failing placeholders)
    - Edge Function: JWT decode for user_id, upsert usage counter, forward to upstream
key_files:
  created:
    - supabase/functions/ai-stylize/index.ts
    - lib/features/qr_digital/domain/services/qr_animation_service.dart
    - test/features/qr_digital/services/qr_animation_service_test.dart
    - test/features/qr_digital/services/qr_ai_style_service_test.dart
    - test/features/qr_digital/services/qr_widget_service_test.dart
  modified:
    - lib/features/qr_generator/domain/services/qr_export_service.dart
decisions:
  - "exportDigitalOnly passes decoration through as-is (no white background override) per QrProfile.digitalOnly constraint"
  - "Edge Function uses JWT sub claim (user_id) for usage counter without additional signature check — T-06-04 accepted for MVP"
  - "Sentinel tests use expect(true, isFalse) pattern so they fail deterministically and Wave 2 plans replace them"
  - "QrAnimationService stub documents mobile_scanner 7.2.0 analyzeImage(path) API as code comment to prevent re-research"
metrics:
  duration: "3m 10s"
  completed: "2026-05-03T13:18:34Z"
  tasks_completed: 2
  files_created: 5
  files_modified: 1
---

# Phase 6 Plan 1: Shared Digital QR Infrastructure Summary

One-liner: Replicate Edge Function proxy with API-key-in-env security, exportDigitalOnly() bypassing white-background enforcement, and three wave-0 test sentinels unblocking Wave 2 plans.

## What Was Built

### Task 1 — exportDigitalOnly() + Test Scaffolds (commit 8c0cda2)

Extended `QrExportService` with `exportDigitalOnly()`: identical flow to `exportPrintSafe` but omits `decoration.copyWith(background: Colors.white)`. Accepts `size` parameter defaulting to 400 px (GIF frames) vs the print export's fixed 2160 px.

Three sentinel test files created under `test/features/qr_digital/services/`:
- `qr_animation_service_test.dart` — fails with "Wave 0 placeholder — implement in plan 06-02"
- `qr_ai_style_service_test.dart` — fails with "Wave 0 placeholder — implement in plan 06-02"
- `qr_widget_service_test.dart` — fails with "Wave 0 placeholder — implement in plan 06-03"

### Task 2 — ai-stylize Edge Function + QrAnimationService Stub (commit 52c9ce4)

`supabase/functions/ai-stylize/index.ts` implements:
- **T-06-01**: `REPLICATE_API_KEY` read exclusively from `Deno.env.get()` — never reaches client
- **T-06-02**: Prompt sanitization — strips `[^\w\s.,!?-]`, truncates at 200 chars before forwarding
- **T-06-03**: 5 calls/month free gate via `ai_style_usage` table upsert; returns 429 with `{"error":"monthly_limit_reached"}` on breach
- **T-06-04**: JWT Bearer token validated; user_id extracted from `sub` claim for usage counter
- CORS headers for Flutter web: `Access-Control-Allow-Origin: *`
- Poll route: accepts `{"prediction_id":"..."}` to forward to Replicate status endpoint
- Includes SQL DDL comment for `ai_style_usage` table (developer applies via Dashboard)

`lib/features/qr_digital/domain/services/qr_animation_service.dart`:
- Stub class with `captureFrames()` returning `Uint8List(0)`
- Documents `mobile_scanner 7.2.0 MobileScannerController.analyzeImage(String imagePath) → Future<BarcodeCapture?>` API signature to unblock plan 06-03

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

| File | Stub | Reason |
|------|------|--------|
| `lib/features/qr_digital/domain/services/qr_animation_service.dart` | `captureFrames()` returns `Uint8List(0)` | Intentional Wave-0 stub; plan 06-02 implements full GIF frame capture |
| `test/features/qr_digital/services/qr_animation_service_test.dart` | `expect(true, isFalse)` placeholder | Intentional sentinel; plan 06-02 replaces with real tests |
| `test/features/qr_digital/services/qr_ai_style_service_test.dart` | `expect(true, isFalse)` placeholder | Intentional sentinel; plan 06-02 replaces with real tests |
| `test/features/qr_digital/services/qr_widget_service_test.dart` | `expect(true, isFalse)` placeholder | Intentional sentinel; plan 06-03 replaces with real tests |

Stubs are intentional infrastructure contracts for Wave 2 plans, not unfinished work.

## Threat Surface Scan

All STRIDE threats from the plan's threat model were mitigated:

| Threat ID | Mitigation | File |
|-----------|-----------|------|
| T-06-01 | `Deno.env.get('REPLICATE_API_KEY')` — key never in response/logs | `supabase/functions/ai-stylize/index.ts` |
| T-06-02 | `replace(/[^\w\s.,!?-]/g, "").slice(0, 200)` before Replicate call | `supabase/functions/ai-stylize/index.ts` |
| T-06-03 | `ai_style_usage` upsert counter; 429 on `count >= 5` | `supabase/functions/ai-stylize/index.ts` |
| T-06-04 | Accepted — Supabase runtime validates JWT signature | — |

No new threat surface introduced beyond what the plan's threat model covers.

## Self-Check: PASSED

- `lib/features/qr_generator/domain/services/qr_export_service.dart` — contains `exportDigitalOnly`: FOUND
- `supabase/functions/ai-stylize/index.ts` — contains `REPLICATE_API_KEY`: FOUND
- `test/features/qr_digital/services/qr_animation_service_test.dart`: FOUND
- `test/features/qr_digital/services/qr_ai_style_service_test.dart`: FOUND
- `test/features/qr_digital/services/qr_widget_service_test.dart`: FOUND
- `lib/features/qr_digital/domain/services/qr_animation_service.dart`: FOUND
- Commits 8c0cda2 and 52c9ce4: FOUND in git log
- `flutter analyze`: 0 issues
- `flutter test test/features/qr_digital/`: 3 failures (expected wave-0 sentinels)
