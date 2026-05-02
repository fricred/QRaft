import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/domain/value_objects/qr_profile.dart';
import 'package:qraft/features/qr_generator/presentation/controllers/qr_customization_controller.dart';

void main() {
  group('QRCustomizationController Phase 5 extensions', () {
    late QRCustomizationController controller;

    setUp(() {
      controller = QRCustomizationController();
    });

    // --- updateProfile ---

    test('updateProfile(printSafe) sets profile index 0', () {
      controller.updateProfile(QrProfile.printSafe);
      expect(controller.state.customization.profile, 0);
    });

    test('updateProfile(digitalOnly) sets profile index 1', () {
      controller.updateProfile(QrProfile.digitalOnly);
      expect(controller.state.customization.profile, 1);
    });

    test('updateProfile(tattooSafe) sets profile index 2', () {
      controller.updateProfile(QrProfile.tattooSafe);
      expect(controller.state.customization.profile, 2);
    });

    test('updateProfile(printSafe) forces EC to H (3) when requiresEcH', () {
      // Start with EC level 1 (M)
      controller.updateErrorCorrection(1);
      controller.updateProfile(QrProfile.printSafe);
      expect(controller.state.customization.errorCorrectionLevel, 3);
    });

    test('updateProfile(digitalOnly) does NOT force EC to H', () {
      // Start with EC level 1 (M)
      controller.updateErrorCorrection(1);
      controller.updateProfile(QrProfile.digitalOnly);
      // digitalOnly does not require EC-H, so stays as set
      expect(controller.state.customization.errorCorrectionLevel, 1);
    });

    // --- updateModulePreset ---

    test('updateModulePreset(3) sets modulePreset to 3', () {
      controller.updateModulePreset(3);
      expect(controller.state.customization.modulePreset, 3);
    });

    test('updateModulePreset(7) sets modulePreset to 7', () {
      controller.updateModulePreset(7);
      expect(controller.state.customization.modulePreset, 7);
    });

    // --- updateEyePreset ---

    test('updateEyePreset(2) sets eyePreset to 2', () {
      controller.updateEyePreset(2);
      expect(controller.state.customization.eyePreset, 2);
    });

    // --- updateGradient ---

    test('updateGradient enables gradient with linear type', () {
      controller.updateGradient(
        hasGradient: true,
        gradientStart: 0xFF1A73E8,
        gradientEnd: 0xFF00FF88,
        type: GradientType.linear,
      );
      final c = controller.state.customization;
      expect(c.hasGradient, isTrue);
      expect(c.gradientStart, 0xFF1A73E8);
      expect(c.gradientEnd, 0xFF00FF88);
      expect(c.gradientType, GradientType.linear);
    });

    test('updateGradient(hasGradient: false) clears gradient colors', () {
      // First set a gradient
      controller.updateGradient(
        hasGradient: true,
        gradientStart: 0xFF1A73E8,
        gradientEnd: 0xFF00FF88,
        type: GradientType.linear,
      );
      // Then disable
      controller.updateGradient(
        hasGradient: false,
        type: GradientType.solid,
      );
      final c = controller.state.customization;
      expect(c.hasGradient, isFalse);
      expect(c.gradientType, GradientType.solid);
    });

    // --- updateFrameText ---

    test('updateFrameText("Scan me") sets frameText', () {
      controller.updateFrameText('Scan me');
      expect(controller.state.customization.frameText, 'Scan me');
    });

    test('updateFrameText(null) clears frameText', () {
      controller.updateFrameText('Scan me');
      controller.updateFrameText(null);
      expect(controller.state.customization.frameText, isNull);
    });

    // --- updateLogoCoverage ---

    test('updateLogoCoverage(0.15) sets logoCoverage to 0.15', () {
      controller.updateLogoCoverage(0.15);
      expect(controller.state.customization.logoCoverage, 0.15);
    });

    test('updateLogoCoverage clamps to profile maxLogoScale', () {
      // Profile is printSafe (index 0) by default; max = 0.20
      controller.updateLogoCoverage(0.30);
      expect(controller.state.customization.logoCoverage, 0.20);
    });

    test('updateLogoCoverage clamps to 0.15 for tattooSafe profile', () {
      controller.updateProfile(QrProfile.tattooSafe);
      controller.updateLogoCoverage(0.25);
      expect(controller.state.customization.logoCoverage, 0.15);
    });

    // --- Backward compat: existing methods still work ---

    test('updateForegroundColor still works after Phase 5 extension', () {
      controller.updateForegroundColor(const Color(0xFF1A73E8));
      expect(controller.state.customization.foregroundColor, 0xFF1A73E8);
    });
  });
}
