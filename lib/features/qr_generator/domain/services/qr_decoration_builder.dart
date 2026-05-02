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
