import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/qr_code_entity.dart';
import '../../domain/value_objects/qr_profile.dart';

class QRCustomizationState {
  final QRCustomization customization;
  final bool isPreviewMode;

  const QRCustomizationState({
    this.customization = const QRCustomization(),
    this.isPreviewMode = false,
  });

  QRCustomizationState copyWith({
    QRCustomization? customization,
    bool? isPreviewMode,
  }) {
    return QRCustomizationState(
      customization: customization ?? this.customization,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
    );
  }
}

class QRCustomizationController extends StateNotifier<QRCustomizationState> {
  QRCustomizationController() : super(const QRCustomizationState());

  // --------------------------------------------------------------------------
  // Existing methods — preserved for backward compatibility
  // --------------------------------------------------------------------------

  void updateForegroundColor(Color color) {
    final customization = state.customization.copyWith(
      foregroundColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }

  void updateBackgroundColor(Color color) {
    final customization = state.customization.copyWith(
      backgroundColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }

  void updateEyeColor(Color color) {
    final customization = state.customization.copyWith(
      eyeColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }

  void updateSize(double size) {
    final customization = state.customization.copyWith(size: size);
    state = state.copyWith(customization: customization);
  }

  void updateEyeShape(int shape) {
    final customization = state.customization.copyWith(eyeShape: shape);
    state = state.copyWith(customization: customization);
  }

  void updateDataShape(int shape) {
    final customization = state.customization.copyWith(dataShape: shape);
    state = state.copyWith(customization: customization);
  }

  void updateRoundedCorners(bool rounded) {
    final customization = state.customization.copyWith(roundedCorners: rounded);
    state = state.copyWith(customization: customization);
  }

  void updateErrorCorrection(int level) {
    final customization = state.customization.copyWith(
      errorCorrectionLevel: level,
    );
    state = state.copyWith(customization: customization);
  }

  /// Set or remove logo. Also initialises logoCoverage to 0.15 when a logo is
  /// set for the first time (safe default within all profile caps).
  void updateLogo(String? logoPath, double? logoSize) {
    final isAddingLogo = logoPath != null;
    final currentCoverage = state.customization.logoCoverage;
    final newCoverage =
        (isAddingLogo && currentCoverage == 0.0) ? 0.15 : currentCoverage;

    final customization = state.customization.copyWith(
      logoPath: logoPath,
      hasLogo: isAddingLogo,
      logoSize: logoSize ?? state.customization.logoSize,
      logoCoverage: newCoverage,
    );
    state = state.copyWith(customization: customization);
  }

  void removeLogo() {
    final customization = state.customization.copyWith(
      logoPath: null,
      hasLogo: false,
    );
    state = state.copyWith(customization: customization);
  }

  void togglePreviewMode() {
    state = state.copyWith(isPreviewMode: !state.isPreviewMode);
  }

  void applyTemplate(QRTemplate template) {
    QRCustomization customization;

    switch (template) {
      case QRTemplate.classic:
        customization = const QRCustomization(
          foregroundColor: 0xFF000000,
          backgroundColor: 0xFFFFFFFF,
          eyeColor: 0xFF000000,
        );
        break;
      case QRTemplate.modern:
        customization = const QRCustomization(
          foregroundColor: 0xFF1A73E8,
          backgroundColor: 0xFFF5F7FA,
          eyeColor: 0xFF1A73E8,
          eyeShape: 1, // circle
          roundedCorners: true,
        );
        break;
      case QRTemplate.vibrant:
        customization = const QRCustomization(
          foregroundColor: 0xFF00FF88,
          backgroundColor: 0xFF1A1A1A,
          eyeColor: 0xFF00FF88,
          roundedCorners: true,
        );
        break;
      case QRTemplate.elegant:
        customization = const QRCustomization(
          foregroundColor: 0xFF2E2E2E,
          backgroundColor: 0xFFFAFAFA,
          eyeColor: 0xFF6366F1,
          eyeShape: 1, // circle
          dataShape: 1, // circle
          roundedCorners: true,
        );
        break;
    }

    state = state.copyWith(customization: customization);
  }

  void reset() {
    state = const QRCustomizationState();
  }

  /// Load customization from an existing QR code entity (for edit mode).
  void loadFromEntity(QRCodeEntity qrEntity) {
    state = QRCustomizationState(
      customization: qrEntity.customization,
      isPreviewMode: false,
    );
  }

  // --------------------------------------------------------------------------
  // Phase 5 new methods
  // --------------------------------------------------------------------------

  /// Set the output profile. Automatically enforces EC-H when the profile
  /// requires it and the current level is below H (3).
  void updateProfile(QrProfile profile) {
    var customization = state.customization.copyWith(
      profile: profile.index,
    );
    if (profile.requiresEcH &&
        customization.errorCorrectionLevel < 3) {
      customization = customization.copyWith(errorCorrectionLevel: 3);
    }
    state = state.copyWith(customization: customization);
  }

  /// Set the module (data dots) shape preset (0-7).
  void updateModulePreset(int preset) {
    final customization = state.customization.copyWith(modulePreset: preset);
    state = state.copyWith(customization: customization);
  }

  /// Set the finder-pattern (eye) shape preset (0-7).
  void updateEyePreset(int preset) {
    final customization = state.customization.copyWith(eyePreset: preset);
    state = state.copyWith(customization: customization);
  }

  /// Configure gradient fill for QR modules.
  ///
  /// Pass [hasGradient] = false and [type] = GradientType.solid to disable.
  /// [gradientStart] and [gradientEnd] are ARGB color ints; pass null to clear.
  void updateGradient({
    required bool hasGradient,
    int? gradientStart,
    int? gradientEnd,
    required GradientType type,
  }) {
    // Build the customization. When disabling gradient, pass explicit nulls
    // to clear the color fields via the sentinel pattern.
    QRCustomization customization;
    if (hasGradient) {
      customization = state.customization.copyWith(
        hasGradient: true,
        gradientStart: gradientStart,
        gradientEnd: gradientEnd,
        gradientType: type,
      );
    } else {
      // Explicitly clear nullable fields using the sentinel Object() trick
      customization = QRCustomization(
        foregroundColor: state.customization.foregroundColor,
        backgroundColor: state.customization.backgroundColor,
        eyeColor: state.customization.eyeColor,
        size: state.customization.size,
        errorCorrectionLevel: state.customization.errorCorrectionLevel,
        logoPath: state.customization.logoPath,
        hasLogo: state.customization.hasLogo,
        eyeShape: state.customization.eyeShape,
        dataShape: state.customization.dataShape,
        roundedCorners: state.customization.roundedCorners,
        logoSize: state.customization.logoSize,
        hasGradient: false,
        gradientStart: null,
        gradientEnd: null,
        gradientType: GradientType.solid,
        modulePreset: state.customization.modulePreset,
        eyePreset: state.customization.eyePreset,
        profile: state.customization.profile,
        frameText: state.customization.frameText,
        logoCoverage: state.customization.logoCoverage,
      );
    }
    state = state.copyWith(customization: customization);
  }

  /// Set or clear the CTA frame text below the QR code.
  /// Pass null to remove the frame.
  void updateFrameText(String? text) {
    // Use full constructor to allow explicit null clearing
    final c = state.customization;
    final customization = QRCustomization(
      foregroundColor: c.foregroundColor,
      backgroundColor: c.backgroundColor,
      eyeColor: c.eyeColor,
      size: c.size,
      errorCorrectionLevel: c.errorCorrectionLevel,
      logoPath: c.logoPath,
      hasLogo: c.hasLogo,
      eyeShape: c.eyeShape,
      dataShape: c.dataShape,
      roundedCorners: c.roundedCorners,
      logoSize: c.logoSize,
      hasGradient: c.hasGradient,
      gradientStart: c.gradientStart,
      gradientEnd: c.gradientEnd,
      gradientType: c.gradientType,
      modulePreset: c.modulePreset,
      eyePreset: c.eyePreset,
      profile: c.profile,
      frameText: text,
      logoCoverage: c.logoCoverage,
    );
    state = state.copyWith(customization: customization);
  }

  /// Set logo coverage scale (0.0–1.0). Clamped to the current profile's
  /// maximum allowed scale to enforce scannability constraints (T-05-01-01).
  void updateLogoCoverage(double coverage) {
    final currentProfile = QrProfile.values[state.customization.profile];
    final clamped = coverage.clamp(0.0, currentProfile.maxLogoScale);
    final customization = state.customization.copyWith(logoCoverage: clamped);
    state = state.copyWith(customization: customization);
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Convert a [Color] to an ARGB int without using the deprecated `.value`.
  int _colorToInt(Color color) {
    return (color.a * 255).round() << 24 |
        (color.r * 255).round() << 16 |
        (color.g * 255).round() << 8 |
        (color.b * 255).round();
  }
}

enum QRTemplate {
  classic,
  modern,
  vibrant,
  elegant,
}

extension QRTemplateExtension on QRTemplate {
  String get name {
    switch (this) {
      case QRTemplate.classic:
        return 'Classic';
      case QRTemplate.modern:
        return 'Modern';
      case QRTemplate.vibrant:
        return 'Vibrant';
      case QRTemplate.elegant:
        return 'Elegant';
    }
  }

  String get description {
    switch (this) {
      case QRTemplate.classic:
        return 'Black on white, traditional style';
      case QRTemplate.modern:
        return 'Blue theme with rounded corners';
      case QRTemplate.vibrant:
        return 'Gradient colors on dark background';
      case QRTemplate.elegant:
        return 'Sophisticated circular design';
    }
  }

  List<int> get previewColors {
    switch (this) {
      case QRTemplate.classic:
        return [0xFF000000, 0xFFFFFFFF];
      case QRTemplate.modern:
        return [0xFF1A73E8, 0xFFF5F7FA];
      case QRTemplate.vibrant:
        return [0xFF00FF88, 0xFF1A73E8];
      case QRTemplate.elegant:
        return [0xFF6366F1, 0xFFFAFAFA];
    }
  }
}

final qrCustomizationControllerProvider =
    StateNotifierProvider<QRCustomizationController, QRCustomizationState>(
        (ref) {
  return QRCustomizationController();
});
