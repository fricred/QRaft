import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../qr_generator/domain/services/qr_export_service.dart';

// ---------------------------------------------------------------------------
// Isolate data transfer object — must be a plain class with no Flutter objects
// so it can cross the compute() isolate boundary.
// ---------------------------------------------------------------------------

/// Parameters for GIF encoding inside a compute() isolate.
///
/// All fields are plain Dart types (no Flutter objects). This satisfies the
/// compute() constraint that arguments must be sendable across isolate ports.
class _GifEncodeParams {
  final List<Uint8List> frames;
  final int delayMs;

  const _GifEncodeParams({required this.frames, required this.delayMs});
}

// ---------------------------------------------------------------------------
// Top-level GIF encoder — MUST be top-level (not a closure or method)
// so that compute() can pass it across isolate boundaries.
// ---------------------------------------------------------------------------

/// Encodes a list of PNG frames into an animated GIF byte stream.
///
/// This is a top-level function (not a closure) so it can be passed to
/// [compute] — closures are not transferable across isolate boundaries.
///
/// Uses the image 4.x API: the first decoded frame is the animation root;
/// subsequent frames are added via [img.Image.addFrame]. The GIF delay is
/// measured in 1/100 s units (centiseconds), so [delayMs] is converted:
/// `delayCs = delayMs ~/ 10`.
Uint8List _encodeGifIsolate(_GifEncodeParams params) {
  if (params.frames.isEmpty) {
    throw ArgumentError('frames must not be empty');
  }

  // Delay in centiseconds (GIF standard unit).
  final delayCs = math.max(1, params.delayMs ~/ 10);

  img.Image? animation;

  for (final pngBytes in params.frames) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) continue;

    if (animation == null) {
      // First frame becomes the animation root. Set loop and frame duration.
      animation = decoded;
      animation.loopCount = 0; // 0 = infinite loop
      animation.frameType = img.FrameType.animation;
      animation.frameDuration = delayCs;
    } else {
      // Add subsequent frames. Each new frame must carry its own duration.
      final newFrame = animation.addFrame(decoded);
      newFrame.frameDuration = delayCs;
    }
  }

  if (animation == null) {
    throw ArgumentError('frames must not be empty after decoding');
  }

  return img.encodeGif(animation);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Service for animated QR code GIF generation.
///
/// All methods are static — the class is never instantiated.
///
/// Workflow:
/// 1. Call [captureFrames] to render 12 PNG frames with an opacity-pulse
///    decoration mutation over the supplied [QrImage] + [PrettyQrDecoration].
/// 2. Call [buildGif] to encode the frame list into an animated GIF byte
///    stream in a [compute] isolate (avoids UI jank).
///
/// mobile_scanner 7.2.0 analyzeImage API (confirmed in research — plan 06-03
/// will build against this signature without re-researching):
///
/// ```dart
/// // MobileScannerController.analyzeImage(String imagePath) → Future<BarcodeCapture?>
/// // Path must be a file path on disk (not in-memory bytes).
/// // Returns BarcodeCapture with .barcodes list; empty list means no QR detected.
/// ```
///
/// Usage in scannability gate (plan 06-03):
/// ```dart
/// final controller = MobileScannerController();
/// final capture = await controller.analyzeImage(tempFilePath);
/// final isReadable = capture != null && capture.barcodes.isNotEmpty;
/// ```
class QrAnimationService {
  // Static-only service — no instantiation.
  QrAnimationService._();

  /// Captures [frameCount] PNG frames of an opacity-pulse QR animation.
  ///
  /// At each frame index `i` (0 to [frameCount]-1), computes a normalised
  /// position `t = i / (frameCount - 1)` and applies a sine-based opacity
  /// curve: the background color alpha interpolates between its original value
  /// (full) and a dimmer value using `sin(t * π)` — fades out at t=0.5 and
  /// returns to full at t=1.0, creating a smooth pulse.
  ///
  /// Only the background color alpha is mutated; all other decoration fields
  /// are preserved via [PrettyQrDecoration.copyWith].
  ///
  /// Each frame is rendered at [size] × [size] px via
  /// [QrExportService.exportDigitalOnly] (no white-background override).
  ///
  /// Returns a [List] of [Uint8List] PNG byte arrays, one per frame.
  static Future<List<Uint8List>> captureFrames(
    QrImage qrImage,
    PrettyQrDecoration decoration, {
    int frameCount = 12,
    int size = 400,
  }) async {
    final frames = <Uint8List>[];

    for (var i = 0; i < frameCount; i++) {
      final t = frameCount > 1 ? i / (frameCount - 1) : 0.0;

      // Sine curve: 0 at edges, 1 in the middle → fades in then out.
      // Background alpha: full (1.0) at start/end, reduced at midpoint.
      final sineValue = math.sin(t * math.pi);
      final bgAlpha = (1.0 - 0.4 * sineValue).clamp(0.0, 1.0);

      final frameDeco = _withAlpha(decoration, bgAlpha);

      final pngBytes = await QrExportService.exportDigitalOnly(
        qrImage,
        frameDeco,
        size: size,
      );
      frames.add(pngBytes);
    }

    return frames;
  }

  /// Encodes a list of PNG [frames] into an animated GIF byte stream.
  ///
  /// The encoding is performed inside a [compute] isolate (top-level function
  /// [_encodeGifIsolate]) so the Flutter UI thread is never blocked during the
  /// 1–3 s encoding window.
  ///
  /// [delayMs] controls the inter-frame delay in milliseconds (default 100 ms
  /// → ~10 fps, stored as centiseconds in the GIF stream).
  ///
  /// Throws [ArgumentError] if [frames] is empty.
  static Future<Uint8List> buildGif(
    List<Uint8List> frames, {
    int delayMs = 100,
  }) async {
    if (frames.isEmpty) {
      throw ArgumentError('frames must not be empty');
    }

    return compute(
      _encodeGifIsolate,
      _GifEncodeParams(frames: frames, delayMs: delayMs),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns a new [PrettyQrDecoration] with the background color alpha
  /// set to [alpha] (0.0–1.0).
  ///
  /// The foreground (module) color is not mutated so QR modules remain crisp.
  /// Modulating background alpha creates the visible opacity-pulse effect.
  static PrettyQrDecoration _withAlpha(
    PrettyQrDecoration decoration,
    double alpha,
  ) {
    final bg = decoration.background ?? Colors.transparent;
    final fadedBg = bg.withValues(alpha: alpha);
    return decoration.copyWith(background: fadedBg);
  }
}
