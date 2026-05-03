---
phase: 06-qr-digital-features
plan: 02
subsystem: qr-digital, animation, gif-export
tags: [gif, animation, flutter_animate, compute-isolate, share_plus, riverpod]
dependency_graph:
  requires:
    - 06-01 (exportDigitalOnly on QrExportService, QrAnimationService stub)
  provides:
    - QrAnimationService.captureFrames() + buildGif() (compute() isolate GIF encoding)
    - QrDigitalController StateNotifier with exportGif() and profile guard
    - QrAnimatePage with flutter_animate opacity-pulse preview and GIF export
    - Real unit tests replacing wave-0 sentinels
  affects:
    - lib/features/qr_digital/domain/services/qr_animation_service.dart
    - lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart
    - lib/features/qr_digital/presentation/pages/qr_animate_page.dart
    - test/features/qr_digital/services/qr_animation_service_test.dart
tech_stack:
  added:
    - flutter_animate opacity-pulse animation pattern (fadeIn.then.fadeOut repeat)
    - image 4.5.4 animated GIF via Image.addFrame() + encodeGif()
    - compute() isolate encoding pattern (_encodeGifIsolate top-level function)
    - Share.shareXFiles (share_plus v10 API)
  patterns:
    - Static-only service with compute() isolate for CPU-intensive work
    - StateNotifier + immutable state (QrDigitalState)
    - AutoDispose family provider scoped to QRCodeEntity
    - Double-layer profile guard (controller throws, UI disables)
key_files:
  created:
    - lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart
    - lib/features/qr_digital/presentation/pages/qr_animate_page.dart
  modified:
    - lib/features/qr_digital/domain/services/qr_animation_service.dart
    - test/features/qr_digital/services/qr_animation_service_test.dart
decisions:
  - "Used image 4.5.4 Image.addFrame() API instead of Animation class (removed in v4)"
  - "Background-alpha modulation for pulse (foreground color lives inside shape symbols — not exposed on PrettyQrDecoration)"
  - "GIF delay stored as centiseconds (GIF standard unit): delayMs ~/ 10"
  - "share_plus v10 uses Share.shareXFiles() not SharePlus.instance.share(ShareParams())"
  - "_encodeGifIsolate is top-level function — satisfies compute() isolate boundary constraint"
metrics:
  duration: "6m 27s"
  completed: "2026-05-03T13:34:36Z"
  tasks_completed: 2
  files_created: 2
  files_modified: 2
---

# Phase 6 Plan 2: QR Animated GIF Export Summary

One-liner: Opacity-pulse QR animation with 12-frame GIF encoding in a compute() isolate and system share sheet delivery via share_plus v10.

## What Was Built

### Task 1 — QrAnimationService: captureFrames + buildGif (commits 32b3398)

Replaced the wave-0 stub with a full implementation:

**`captureFrames(QrImage, PrettyQrDecoration, {frameCount, size})`**: Loops 0..frameCount-1, computes `t = i/(frameCount-1)`, applies a `sin(t*π)` sine curve to modulate background alpha (1.0 full → 0.6 midpoint → 1.0 full), calls `QrExportService.exportDigitalOnly()` per frame at 400px. Returns `List<Uint8List>` PNG frames.

**`buildGif(frames, {delayMs})`**: Guards against empty frames with `ArgumentError`. Calls `compute(_encodeGifIsolate, _GifEncodeParams(...))` where `_encodeGifIsolate` is a top-level function (isolate boundary constraint). Inside the isolate: uses image 4.5.4 `Image.addFrame()` pattern (not the removed `Animation` class), sets `loopCount=0` (infinite), `frameType=FrameType.animation`, stores delay as centiseconds (`delayMs ~/ 10`), returns `img.encodeGif(animation)`.

**Unit tests (5 passing):**
- GIF magic bytes (0x47 0x49 0x46 0x38 0x39 0x61) verified with 12 real 4×4 PNG frames
- ArgumentError on empty frames list
- Non-empty bytes returned for valid input
- Custom delayMs parameter accepted
- captureFrames static method signature check

### Task 2 — QrDigitalController + QrAnimatePage (commit 6286f54)

**`QrDigitalController`** — `StateNotifier<QrDigitalState>`:
- `QrDigitalState`: `isExporting`, `exportError`, `gifBytes` (all immutable)
- `exportGif()`: profile guard (T-06-06 — throws `StateError` for non-digitalOnly), sets `isExporting=true`, builds decoration + QrImage via `QrDecorationBuilder`, calls `captureFrames` + `buildGif`, shares via `Share.shareXFiles([XFile.fromData(..., mimeType:'image/gif')])`
- `qrDigitalControllerProvider`: `StateNotifierProvider.autoDispose.family`

**`QrAnimatePage`** — `ConsumerStatefulWidget`:
- Dark Carden Pro theme (#1A1A1A background, #2E2E2E card)
- Preview: 280×280 `PrettyQrView.data` wrapped in `.animate(onPlay: c.repeat()).fadeIn(800ms).then().fadeOut(800ms)`
- Export button: `GlassButton` disabled during export (loading spinner), disabled + grey gradients for non-digitalOnly
- Profile guard banner: red container with explanatory text when `profile != 1`
- Error display: `SnackBar` via `ref.listen`
- Semantics: `qr_animate_preview`, `qr_animate_export_button`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] image package v4.5.4 has no `Animation` class**

- **Found during:** Task 1 GREEN phase (compilation error)
- **Issue:** The plan's interface snippet used `img.Animation()..loopCount = 0` which was the API in image v3.x. In v4.x the `Animation` class was replaced by using `Image` itself as the animation container via `Image.addFrame()`.
- **Fix:** Used `img.Image` as animation root, `animation.addFrame(frame)`, `animation.loopCount = 0`, `animation.frameType = img.FrameType.animation`.
- **Files modified:** `lib/features/qr_digital/domain/services/qr_animation_service.dart`
- **Commit:** 32b3398

**2. [Rule 1 - Bug] share_plus v10 uses `Share.shareXFiles()` not `SharePlus.instance.share(ShareParams(...))`**

- **Found during:** Task 2 implementation
- **Issue:** The plan's interface snippet referenced `SharePlus.instance.share(ShareParams(files: [...]))`, which is a v9.x API. share_plus v10.1.4 uses `Share.shareXFiles(List<XFile>)`.
- **Fix:** Used `Share.shareXFiles([xFile])` per the actual v10 API.
- **Files modified:** `lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart`
- **Commit:** 6286f54

**3. [Rule 1 - Bug] Opacity pulse modulates background alpha, not foreground color**

- **Found during:** Task 1 implementation
- **Issue:** `PrettyQrDecoration` does not expose a top-level foreground color — color lives inside the shape symbol classes (`PrettyQrSquaresSymbol`, etc.) which have no `copyWith` for alpha extraction. Mutating shape internals would require switching shape class per frame.
- **Fix:** Modulated background alpha using `decoration.copyWith(background: bg.withValues(alpha: ...))`. For digital-only dark themes, fading the background creates the same visual opacity-pulse effect without requiring shape introspection.
- **Files modified:** `lib/features/qr_digital/domain/services/qr_animation_service.dart`
- **Commit:** 32b3398

## Known Stubs

None — all plan artifacts are fully implemented.

## Threat Surface Scan

All STRIDE threats from the plan's threat model were addressed:

| Threat ID | Mitigation | File |
|-----------|-----------|------|
| T-06-05 | GIF capped at 400px × 12 frames; `isExporting` spinner prevents double-tap; compute() prevents ANR | `qr_animation_service.dart`, `qr_animate_page.dart` |
| T-06-06 | Double-layer guard: `StateError` in controller + disabled button + red banner in UI | `qr_digital_controller.dart`, `qr_animate_page.dart` |
| T-06-07 | Accepted — GIF contains only QR data; user initiates share explicitly | — |

No new threat surface introduced beyond what the plan's threat model covers.

## Self-Check: PASSED

- `lib/features/qr_digital/domain/services/qr_animation_service.dart` — contains `encodeGif`: FOUND
- `lib/features/qr_digital/presentation/pages/qr_animate_page.dart` — contains `QrAnimatePage`: FOUND
- `lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart` — contains `QrDigitalController`: FOUND
- `test/features/qr_digital/services/qr_animation_service_test.dart` — contains `encodeGif`: FOUND
- Commit 32b3398: FOUND in git log
- Commit 6286f54: FOUND in git log
- `flutter analyze`: 0 issues
- `flutter test test/features/qr_digital/services/qr_animation_service_test.dart`: 5/5 passed
