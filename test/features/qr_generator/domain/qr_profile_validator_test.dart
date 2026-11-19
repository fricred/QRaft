import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/services/qr_profile_validator.dart';
import 'package:qraft/features/qr_generator/domain/value_objects/qr_profile.dart';

void main() {
  group('QrProfileValidator', () {
    // Base customization: dark-on-light, no logo
    const baseCustomization = QRCustomization(
      foregroundColor: 0xFF000000, // black
      backgroundColor: 0xFFFFFFFF, // white
      logoCoverage: 0.0,
      hasLogo: false,
    );

    // --- Logo coverage tests ---

    test('logo_too_large: scale=0.25 printSafe → errors contains logo_too_large',
        () {
      final c = baseCustomization.copyWith(
        hasLogo: true,
        logoCoverage: 0.25,
      );
      final result = QrProfileValidator.validate(c, QrProfile.printSafe);
      expect(result.errors, contains('logo_too_large'));
    });

    test('logo_too_large: scale=0.25 digitalOnly → errors contains logo_too_large',
        () {
      final c = baseCustomization.copyWith(
        hasLogo: true,
        logoCoverage: 0.25,
      );
      final result = QrProfileValidator.validate(c, QrProfile.digitalOnly);
      expect(result.errors, contains('logo_too_large'));
    });

    test('logo_too_large: scale=0.16 tattooSafe → errors contains logo_too_large',
        () {
      final c = baseCustomization.copyWith(
        hasLogo: true,
        logoCoverage: 0.16,
      );
      final result = QrProfileValidator.validate(c, QrProfile.tattooSafe);
      expect(result.errors, contains('logo_too_large'));
    });

    test('boundary inclusive: scale=0.15 tattooSafe → isValid true', () {
      final c = baseCustomization.copyWith(
        hasLogo: true,
        logoCoverage: 0.15,
      );
      final result = QrProfileValidator.validate(c, QrProfile.tattooSafe);
      expect(result.isValid, isTrue);
    });

    // --- Inverted colors tests ---

    test('inverted colors printSafe → errors contains inverted_colors_not_allowed_for_print',
        () {
      // light-on-dark: white foreground on black background
      final c = baseCustomization.copyWith(
        foregroundColor: 0xFFFFFFFF, // white (bright)
        backgroundColor: 0xFF000000, // black (dark)
      );
      final result = QrProfileValidator.validate(c, QrProfile.printSafe);
      expect(
        result.errors,
        contains('inverted_colors_not_allowed_for_print'),
      );
    });

    test('inverted colors tattooSafe → errors contains inverted_colors_not_allowed_for_print',
        () {
      final c = baseCustomization.copyWith(
        foregroundColor: 0xFFFFFFFF,
        backgroundColor: 0xFF000000,
      );
      final result = QrProfileValidator.validate(c, QrProfile.tattooSafe);
      expect(
        result.errors,
        contains('inverted_colors_not_allowed_for_print'),
      );
    });

    test('inverted colors digitalOnly → isValid true (allowed)', () {
      final c = baseCustomization.copyWith(
        foregroundColor: 0xFFFFFFFF, // white on black
        backgroundColor: 0xFF000000,
      );
      final result = QrProfileValidator.validate(c, QrProfile.digitalOnly);
      expect(result.isValid, isTrue);
    });

    test('no logo printSafe → isValid true (no logo = no coverage error)', () {
      // baseCustomization already has hasLogo: false
      final result = QrProfileValidator.validate(
          baseCustomization, QrProfile.printSafe);
      expect(result.isValid, isTrue);
    });
  });
}
