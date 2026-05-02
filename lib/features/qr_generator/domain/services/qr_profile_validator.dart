import 'package:flutter/material.dart';
import '../entities/qr_code_entity.dart';
import '../value_objects/qr_profile.dart';

/// Result of a profile validation check.
class QrValidationResult {
  /// List of error codes for any constraint violations.
  final List<String> errors;

  const QrValidationResult({required this.errors});

  /// True when no constraint violations were found.
  bool get isValid => errors.isEmpty;
}

/// Validates [QRCustomization] against per-profile constraints.
///
/// Enforces:
/// - Logo coverage cap (logo_too_large)
/// - Dark-on-light color requirement for print/tattoo profiles
///   (inverted_colors_not_allowed_for_print)
class QrProfileValidator {
  /// Validate [customization] against the given [profile] constraints.
  ///
  /// Returns a [QrValidationResult] with all violations found.
  /// Call [QrValidationResult.isValid] to check for a clean result.
  static QrValidationResult validate(
    QRCustomization customization,
    QrProfile profile,
  ) {
    final errors = <String>[];

    // --- Logo coverage cap ---
    // Only checked when a logo is present; uses logoCoverage field.
    if (customization.hasLogo &&
        customization.logoCoverage > profile.maxLogoScale) {
      errors.add('logo_too_large');
    }

    // --- Dark-on-light enforcement ---
    // Foreground must be darker than background for print/tattoo profiles.
    // Luminance: 0.0 = absolute black, 1.0 = absolute white.
    // Valid dark-on-light: foreground luminance < background luminance.
    if (profile.requiresDarkOnLight) {
      final fgLuminance = Color(customization.foregroundColor).computeLuminance();
      final bgLuminance = Color(customization.backgroundColor).computeLuminance();
      if (fgLuminance >= bgLuminance) {
        errors.add('inverted_colors_not_allowed_for_print');
      }
    }

    return QrValidationResult(errors: errors);
  }
}
