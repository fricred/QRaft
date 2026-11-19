import 'dart:typed_data';

/// Result of an AI stylization request via the Supabase Edge Function proxy.
///
/// [imageBytes] contains the raw PNG bytes of the AI-generated QR code.
/// [scanOk] is `true` when the scannability gate passed — i.e., the
/// [MobileScannerController.analyzeImage] call found at least one barcode in
/// the generated image. The Save/Share UI action is gated on [scanOk].
class QrAiStyleResult {
  /// Raw PNG bytes of the AI-generated QR code image.
  final Uint8List imageBytes;

  /// Whether the scannability gate passed.
  ///
  /// `true`  = at least one barcode was detected by mobile_scanner
  /// `false` = no barcode detected; the image is too heavily stylized.
  final bool scanOk;

  const QrAiStyleResult({
    required this.imageBytes,
    required this.scanOk,
  });
}
