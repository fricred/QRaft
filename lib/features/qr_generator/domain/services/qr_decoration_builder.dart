import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../entities/qr_code_entity.dart';
import '../value_objects/qr_profile.dart';

/// Assembles [PrettyQrDecoration] and [QrImage] from a [QRCustomization]
/// instance — the single wiring layer between the domain entity and the
/// pretty_qr_code rendering API.
///
/// Plans 03 and 04 extend [buildDecoration] to add gradient shapes and eye
/// presets. All call sites should go through this class so that those future
/// additions are automatically picked up.
class QrDecorationBuilder {
  // Static-only class — no instantiation.
  QrDecorationBuilder._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Builds a [PrettyQrDecoration] wired with:
  ///  - Always white background (dark-on-light constraint, T-02-04)
  ///  - Always [PrettyQrQuietZone.standard] (ISO/IEC 18004 §7.3.1)
  ///  - Optional logo image clamped to the profile's [QrProfileConstraints.maxLogoScale]
  ///
  /// The `shape` field is `null` here — plans 03/04 extend this method to add
  /// module/eye shape presets.
  static PrettyQrDecoration buildDecoration(QRCustomization c) {
    return PrettyQrDecoration(
      quietZone: PrettyQrQuietZone.standard,
      background: Colors.white,
      image: _buildImage(c),
      // shape: null — plans 03/04 will extend this to add module/eye presets
    );
  }

  /// Builds a brush (color or gradient) for QR module fill from [QRCustomization].
  ///
  /// Returns a plain [Color] for solid fills, or a [PrettyQrBrush.gradient]
  /// for linear/radial gradient fills. Falls back to [Color] when gradient
  /// colors are missing (null safety guard).
  ///
  /// The return type is [dynamic] because [PrettyQrBrush] extends [Color] but
  /// the gradient factory produces a [PrettyQrGradientBrush] that is not
  /// usable as a plain [Color] in shape constructors — callers cast to
  /// [PrettyQrBrush] when wiring into [PrettyQrSmoothSymbol.color] (Plan 05-04).
  static dynamic buildBrush(QRCustomization c) {
    if (!c.hasGradient || c.gradientStart == null || c.gradientEnd == null) {
      return Color(c.foregroundColor);
    }
    final colors = [Color(c.gradientStart!), Color(c.gradientEnd!)];
    return switch (c.gradientType) {
      GradientType.linear => PrettyQrBrush.gradient(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
      GradientType.radial => PrettyQrBrush.gradient(
          gradient: RadialGradient(center: Alignment.center, colors: colors),
        ),
      GradientType.solid => Color(c.foregroundColor),
    };
  }

  /// Builds a [QrImage] with the correct error-correction level.
  ///
  /// When [QRCustomization.hasLogo] is true, EC level H is forced regardless
  /// of [QRCustomization.errorCorrectionLevel] to ensure sufficient damage
  /// tolerance for logo-embedded codes.
  ///
  /// EC level mapping:
  ///   0 → L (~7% recovery)
  ///   1 → M (~15% recovery)
  ///   2 → Q (~25% recovery)
  ///   3 → H (~30% recovery)  ← forced when hasLogo=true
  static QrImage buildQrImage(String data, QRCustomization c) {
    final ecLevel =
        c.hasLogo ? QrErrorCorrectLevel.H : _mapEcLevel(c.errorCorrectionLevel);
    final qrCode = QrCode.fromData(
      data: data.isEmpty ? ' ' : data, // prevent crash on empty input
      errorCorrectLevel: ecLevel,
    );
    return QrImage(qrCode);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static PrettyQrDecorationImage? _buildImage(QRCustomization c) {
    if (!c.hasLogo || c.logoPath == null) return null;

    final profile = QrProfile.values[c.profile];
    final scale = c.logoCoverage.clamp(0.0, profile.maxLogoScale);

    return PrettyQrDecorationImage(
      image: FileImage(File(c.logoPath!)),
      scale: scale,
      padding: const EdgeInsets.all(4),
      position: PrettyQrDecorationImagePosition.embedded,
    );
  }

  /// Maps [QRCustomization.errorCorrectionLevel] int to a
  /// [QrErrorCorrectLevel] constant.
  static int _mapEcLevel(int level) => switch (level) {
        0 => QrErrorCorrectLevel.L,
        1 => QrErrorCorrectLevel.M,
        2 => QrErrorCorrectLevel.Q,
        _ => QrErrorCorrectLevel.H,
      };
}
