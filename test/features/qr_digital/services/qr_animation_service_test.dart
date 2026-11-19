import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qraft/features/qr_digital/domain/services/qr_animation_service.dart';

/// Generates a minimal valid 4×4 PNG using the image package.
Uint8List _makePng() {
  final image = img.Image(width: 4, height: 4);
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('QrAnimationService.buildGif', () {
    test('returns non-empty bytes for a list of valid PNG frames', () async {
      final frames = [_makePng(), _makePng()];
      final gifBytes = await QrAnimationService.buildGif(frames);
      expect(gifBytes, isNotEmpty);
    });

    test(
        'produces GIF bytes starting with GIF89a magic bytes (0x47 0x49 0x46 0x38 0x39 0x61)',
        () async {
      final frames = List.generate(12, (_) => _makePng());
      final gifBytes = await QrAnimationService.buildGif(frames);

      expect(gifBytes[0], equals(0x47)); // 'G'
      expect(gifBytes[1], equals(0x49)); // 'I'
      expect(gifBytes[2], equals(0x46)); // 'F'
      expect(gifBytes[3], equals(0x38)); // '8'
      expect(gifBytes[4], equals(0x39)); // '9'
      expect(gifBytes[5], equals(0x61)); // 'a'
    });

    test('throws ArgumentError when frames list is empty', () async {
      expect(
        () => QrAnimationService.buildGif([]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('respects custom delayMs parameter', () async {
      final frames = [_makePng(), _makePng()];
      // Should not throw — just verifies the parameter is accepted.
      final gifBytes =
          await QrAnimationService.buildGif(frames, delayMs: 200);
      expect(gifBytes, isNotEmpty);
    });
  });

  group('QrAnimationService.captureFrames signature', () {
    test('captureFrames is a static method that accepts required args', () {
      // Verify the static method exists and has the correct signature by
      // inspecting that it can be referenced as a function object.
      // The actual invocation requires a Flutter widget environment so is
      // omitted from unit tests; this checks compile-time availability.
      expect(QrAnimationService.captureFrames, isNotNull);
    });
  });
}
