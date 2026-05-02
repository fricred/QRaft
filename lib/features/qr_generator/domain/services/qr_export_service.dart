import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Exception thrown when [QrExportService.exportPrintSafe] fails to produce
/// image bytes (e.g., invalid QrImage input).
class QrExportException implements Exception {
  /// Machine-readable error code.
  final String code;

  const QrExportException(this.code);

  @override
  String toString() => 'QrExportException($code)';
}

/// Service for exporting QR codes to print-safe PNG byte streams.
///
/// All exports are forced to a white background regardless of the in-app
/// customization theme (T-05-03-04 mitigation). The export size is fixed at
/// 2160 px — suitable for the XTool F1 Ultra laser engraver input (Phase 7).
///
/// Uses [QrImage.toImageAsBytes] directly (NOT [RepaintBoundary]) so the
/// export is independent of the Flutter widget tree and can be triggered from
/// any isolate-friendly context.
class QrExportService {
  // Static-only service — no instantiation.
  QrExportService._();

  /// Exports [qrImage] as a print-safe PNG at 2160 × 2160 px.
  ///
  /// Forces [decoration.background] to [Colors.white] before rendering to
  /// satisfy the dark-on-light constraint. Any other decoration fields
  /// (shape, quietZone, image) are preserved from the caller's [decoration].
  ///
  /// Throws [QrExportException] with code `'export_failed'` if
  /// [QrImage.toImageAsBytes] returns null (should not occur for valid QR data).
  static Future<Uint8List> exportPrintSafe(
    QrImage qrImage,
    PrettyQrDecoration decoration,
  ) async {
    // Force white background — T-05-03-04: theme cannot override this.
    final exportDecoration = decoration.copyWith(background: Colors.white);

    final byteData = await qrImage.toImageAsBytes(
      size: 2160,
      format: ui.ImageByteFormat.png,
      decoration: exportDecoration,
    );

    if (byteData == null) throw const QrExportException('export_failed');
    return byteData.buffer.asUint8List();
  }
}
