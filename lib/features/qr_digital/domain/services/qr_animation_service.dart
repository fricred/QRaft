import 'dart:typed_data';

/// Stub service for animated QR code GIF generation.
///
/// Full implementation is delivered in plan 06-02 (Wave 2).
///
/// mobile_scanner 7.2.0 analyzeImage API (confirmed in research — plan 06-03
/// will build against this signature without re-researching):
///
/// ```dart
/// // MobileScannerController.analyzeImage(String imagePath) → Future<BarcodeCapture?>
/// // Path must be a file path on disk (not in-memory bytes).
/// // Returns BarcodeCapture with .barcodes list; empty list means no QR detected.
/// ```
///
/// Usage in scannability gate (plan 06-03):
/// ```dart
/// final controller = MobileScannerController();
/// final capture = await controller.analyzeImage(tempFilePath);
/// final isReadable = capture != null && capture.barcodes.isNotEmpty;
/// ```
class QrAnimationService {
  /// Stub: captures animation frames for a QR code.
  ///
  /// Returns empty bytes. Replace with full implementation in plan 06-02.
  static Future<Uint8List> captureFrames() async {
    // TODO(06-02): Implement GIF frame capture loop using exportDigitalOnly().
    return Uint8List(0);
  }
}
