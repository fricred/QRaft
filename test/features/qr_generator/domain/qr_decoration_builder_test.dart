import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/services/qr_decoration_builder.dart';
import 'package:qraft/features/qr_generator/domain/value_objects/qr_profile.dart';

void main() {
  // ---------------------------------------------------------------------------
  // buildDecoration tests
  // ---------------------------------------------------------------------------

  group('QrDecorationBuilder.buildDecoration', () {
    test('returns white background regardless of customization', () {
      const customization = QRCustomization(
        backgroundColor: 0xFF000000, // black — must be overridden
      );
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      expect(decoration.background, Colors.white);
    });

    test('always uses PrettyQrQuietZone.standard', () {
      const customization = QRCustomization();
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      // PrettyQrQuietZone.standard has value == 4.0 (modules)
      expect(decoration.quietZone, PrettyQrQuietZone.standard);
    });

    test('image is null when hasLogo=false', () {
      const customization = QRCustomization(hasLogo: false);
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      expect(decoration.image, isNull);
    });

    test('image is null when hasLogo=true but logoPath=null', () {
      const customization = QRCustomization(hasLogo: true, logoPath: null);
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      expect(decoration.image, isNull);
    });

    test(
        'clamps logoCoverage=0.25 to 0.20 for printSafe profile (maxLogoScale=0.20)',
        () {
      // profile=0 is printSafe, maxLogoScale=0.20
      // logoCoverage=0.25 should be clamped to 0.20
      const customization = QRCustomization(
        hasLogo: true,
        logoPath: '/tmp/fake_logo.png',
        logoCoverage: 0.25,
        profile: 0, // printSafe
      );
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      expect(decoration.image, isNotNull);
      expect(decoration.image!.scale, closeTo(0.20, 0.001));
    });

    test(
        'clamps logoCoverage=0.16 to 0.15 for tattooSafe profile (maxLogoScale=0.15)',
        () {
      // profile=2 is tattooSafe, maxLogoScale=0.15
      // logoCoverage=0.16 should be clamped to 0.15
      const customization = QRCustomization(
        hasLogo: true,
        logoPath: '/tmp/fake_logo.png',
        logoCoverage: 0.16,
        profile: 2, // tattooSafe
      );
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      expect(decoration.image, isNotNull);
      expect(decoration.image!.scale, closeTo(0.15, 0.001));
    });

    test('keeps logoCoverage=0.10 unchanged when within profile cap', () {
      const customization = QRCustomization(
        hasLogo: true,
        logoPath: '/tmp/fake_logo.png',
        logoCoverage: 0.10,
        profile: 0, // printSafe — cap is 0.20
      );
      final decoration = QrDecorationBuilder.buildDecoration(customization);
      expect(decoration.image, isNotNull);
      expect(decoration.image!.scale, closeTo(0.10, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  // buildQrImage tests
  // ---------------------------------------------------------------------------

  group('QrDecorationBuilder.buildQrImage', () {
    test('forces EC level H when hasLogo=true regardless of errorCorrectionLevel',
        () {
      // errorCorrectionLevel=1 → M, but hasLogo=true forces H
      const customization = QRCustomization(
        hasLogo: true,
        errorCorrectionLevel: 1, // M — should be overridden
      );
      final qrImage =
          QrDecorationBuilder.buildQrImage('https://example.com', customization);
      expect(qrImage.errorCorrectLevel, QrErrorCorrectLevel.H);
    });

    test('uses errorCorrectionLevel=M when hasLogo=false', () {
      // errorCorrectionLevel=1 → M; hasLogo=false so no override
      const customization = QRCustomization(
        hasLogo: false,
        errorCorrectionLevel: 1, // M
      );
      final qrImage =
          QrDecorationBuilder.buildQrImage('https://example.com', customization);
      expect(qrImage.errorCorrectLevel, QrErrorCorrectLevel.M);
    });

    test('uses errorCorrectionLevel=L when hasLogo=false and level=0', () {
      const customization = QRCustomization(
        hasLogo: false,
        errorCorrectionLevel: 0, // L
      );
      final qrImage =
          QrDecorationBuilder.buildQrImage('https://example.com', customization);
      expect(qrImage.errorCorrectLevel, QrErrorCorrectLevel.L);
    });

    test('does not crash on empty data string', () {
      const customization = QRCustomization(hasLogo: false);
      expect(
        () => QrDecorationBuilder.buildQrImage('', customization),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // buildBrush tests (Task 1 — Plan 05-03)
  // ---------------------------------------------------------------------------

  group('QrDecorationBuilder.buildBrush', () {
    test('returns a plain Color (not PrettyQrBrush gradient) when hasGradient=false', () {
      const customization = QRCustomization(
        hasGradient: false,
        foregroundColor: 0xFF000000,
      );
      final brush = QrDecorationBuilder.buildBrush(customization);
      expect(brush, isA<Color>());
      expect(brush, isNot(isA<PrettyQrGradientBrush>()));
      expect((brush as Color).value, 0xFF000000);
    });

    test('returns PrettyQrGradientBrush (not plain Color) for linear gradient with valid colors', () {
      const customization = QRCustomization(
        hasGradient: true,
        gradientType: GradientType.linear,
        gradientStart: 0xFF1A73E8,
        gradientEnd: 0xFF00FF88,
      );
      final brush = QrDecorationBuilder.buildBrush(customization);
      expect(brush, isA<PrettyQrGradientBrush>());
      final gradientBrush = brush as PrettyQrGradientBrush;
      expect(gradientBrush.gradient, isA<LinearGradient>());
    });

    test('returns PrettyQrGradientBrush for radial gradient with valid colors', () {
      const customization = QRCustomization(
        hasGradient: true,
        gradientType: GradientType.radial,
        gradientStart: 0xFF6366F1,
        gradientEnd: 0xFFFF6B6B,
      );
      final brush = QrDecorationBuilder.buildBrush(customization);
      expect(brush, isA<PrettyQrGradientBrush>());
      final gradientBrush = brush as PrettyQrGradientBrush;
      expect(gradientBrush.gradient, isA<RadialGradient>());
    });

    test('falls back to plain Color when hasGradient=true but gradientStart is null', () {
      const customization = QRCustomization(
        hasGradient: true,
        gradientType: GradientType.linear,
        gradientStart: null,
        gradientEnd: 0xFF00FF88,
        foregroundColor: 0xFF000000,
      );
      final brush = QrDecorationBuilder.buildBrush(customization);
      expect(brush, isA<Color>());
      expect(brush, isNot(isA<PrettyQrGradientBrush>()));
    });
  });
}
