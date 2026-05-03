import 'dart:typed_data';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../../../qr_generator/domain/services/qr_export_service.dart';

/// Result of a snapshot capture operation.
class SnapshotResult {
  /// Serialized [QRCustomization] + QR data payload for storage in
  /// cart_items.customization_snapshot (Supabase JSONB).
  ///
  /// Merges all customization fields with the raw QR payload so the engraver
  /// always has the complete reproduction specification without a secondary
  /// lookup (MKT-12).
  final Map<String, dynamic> customizationJson;

  /// 2160x2160 print-safe PNG bytes for upload to order-assets/ Storage bucket.
  ///
  /// Non-null after a successful [CustomizationSnapshotService.captureSnapshot]
  /// call. Upload failure does NOT prevent the cart item from being created —
  /// [customizationJson] is the source of truth for the engraver.
  final Uint8List pngBytes;

  const SnapshotResult({
    required this.customizationJson,
    required this.pngBytes,
  });
}

/// Freezes a [QRCodeEntity] into an immutable snapshot for cart / order storage.
///
/// The snapshot is a two-part artifact:
///   1. [customizationJson] — JSONB stored in cart_items.customization_snapshot;
///      contains all QRCustomization fields + the raw QR data string.
///   2. [pngBytes] — 2160x2160 print-safe PNG rasterized via
///      [QrExportService.exportPrintSafe]; uploaded to Supabase Storage
///      order-assets/ bucket.
///
/// Subsequent edits to the source QR in the library are irrelevant — this
/// snapshot is the single source of truth for the laser engraver (MKT-12).
class CustomizationSnapshotService {
  // Static-only service — no instantiation.
  CustomizationSnapshotService._();

  /// Builds a [SnapshotResult] from [qrCode].
  ///
  /// The JSON snapshot merges all [QRCustomization] fields with
  /// {'data': qrCode.data} so the engraver always has the raw QR content.
  ///
  /// The PNG is always rasterized at EC-H (print-safe for laser engraving).
  static Future<SnapshotResult> captureSnapshot(QRCodeEntity qrCode) async {
    final customizationJson = buildSnapshotJson(qrCode);

    // Build QrImage at EC-H — appropriate for all print-safe snapshots
    // (T-MKT-12-01). We force hasLogo=true equivalent by building a temporary
    // customization with hasLogo=true to trigger EC-H in buildQrImage.
    // This guarantees sufficient damage tolerance for any logo-free QR too.
    final ecHCustomization = qrCode.customization.copyWith(hasLogo: true);
    final qrImage = QrDecorationBuilder.buildQrImage(
      qrCode.data,
      ecHCustomization,
    );

    final decoration =
        QrDecorationBuilder.buildDecoration(qrCode.customization);

    final pngBytes = await QrExportService.exportPrintSafe(qrImage, decoration);

    return SnapshotResult(
      customizationJson: customizationJson,
      pngBytes: pngBytes,
    );
  }

  /// Builds only the JSON snapshot without rasterizing the PNG.
  ///
  /// Pure function — safe for unit tests and offline fallback scenarios.
  /// Merges [QRCustomization.toJson()] with the raw QR payload fields.
  static Map<String, dynamic> buildSnapshotJson(QRCodeEntity qrCode) => {
        ...qrCode.customization.toJson(),
        'data': qrCode.data,
        'display_data': qrCode.displayData,
        'qr_type': qrCode.type.name,
      };
}
