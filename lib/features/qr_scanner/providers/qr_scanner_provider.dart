import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scan_result.dart';
import '../../../core/services/supabase_service.dart';

/// QR Scanner state
class QRScannerState {
  final bool isScanning;
  final bool isFlashOn;
  final ScanResult? lastScanResult;
  final List<ScanResult> scanHistory;
  final String? error;
  final bool isLoading;

  const QRScannerState({
    this.isScanning = false,
    this.isFlashOn = false,
    this.lastScanResult,
    this.scanHistory = const [],
    this.error,
    this.isLoading = false,
  });

  QRScannerState copyWith({
    bool? isScanning,
    bool? isFlashOn,
    ScanResult? lastScanResult,
    List<ScanResult>? scanHistory,
    String? error,
    bool? isLoading,
  }) {
    return QRScannerState(
      isScanning: isScanning ?? this.isScanning,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      lastScanResult: lastScanResult ?? this.lastScanResult,
      scanHistory: scanHistory ?? this.scanHistory,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// QR Scanner Controller
class QRScannerController extends StateNotifier<QRScannerState> {
  QRScannerController() : super(const QRScannerState()) {
    _loadScanHistory();
  }

  /// Helper method to get enum from string name
  static QRCodeType _getTypeFromName(String typeName) {
    switch (typeName) {
      case 'url':
        return QRCodeType.url;
      case 'text':
        return QRCodeType.text;
      case 'wifi':
        return QRCodeType.wifi;
      case 'email':
        return QRCodeType.email;
      case 'sms':
        return QRCodeType.sms;
      case 'phone':
        return QRCodeType.phone;
      case 'vcard':
        return QRCodeType.vcard;
      case 'location':
        return QRCodeType.location;
      case 'unknown':
      default:
        return QRCodeType.unknown;
    }
  }

  /// Load scan history from Supabase
  /// [limit] controls how many items to fetch (-1 for unlimited)
  Future<void> _loadScanHistory({int limit = 100}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final historyData = await SupabaseService.getScanHistory(limit: limit);
      
      // Convert data to ScanResult objects
      final history = historyData.map((data) {
        return ScanResult(
          id: data['id'],
          rawValue: data['rawValue'],
          type: _getTypeFromName(data['type']),
          displayValue: data['displayValue'],
          parsedData: data['parsedData'] as Map<String, dynamic>?,
          scannedAt: DateTime.parse(data['scannedAt']).toLocal(),
        );
      }).toList();
      
      state = state.copyWith(
        scanHistory: history,
        isLoading: false,
      );
      
      debugPrint('✅ Loaded ${history.length} scan history items');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load scan history: $e');
      logDetailedError('Load Scan History', e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
      );
    }
  }

  /// Start scanning
  void startScanning() {
    state = state.copyWith(isScanning: true, error: null);
    debugPrint('🔍 QR Scanner started');
  }

  /// Stop scanning
  void stopScanning() {
    state = state.copyWith(isScanning: false);
    debugPrint('⏹️ QR Scanner stopped');
  }

  /// Toggle flash
  void toggleFlash() {
    state = state.copyWith(isFlashOn: !state.isFlashOn);
    debugPrint('💡 Flash ${state.isFlashOn ? "ON" : "OFF"}');
  }

  /// Process scanned QR code
  Future<void> processScanResult(BarcodeCapture capture) async {
    try {
      // Prevent duplicate processing if already processing
      if (state.isLoading) return;
      
      // Get the first barcode from capture
      final barcode = capture.barcodes.first;
      final rawValue = barcode.rawValue;
      
      if (rawValue == null || rawValue.isEmpty) {
        debugPrint('❌ Empty QR code scanned');
        return;
      }

      // Check for duplicate scan (within last 2 seconds)
      if (state.lastScanResult?.rawValue == rawValue && 
          state.lastScanResult != null &&
          DateTime.now().difference(state.lastScanResult!.scannedAt).inSeconds < 2) {
        debugPrint('🔄 Duplicate scan ignored');
        return;
      }

      debugPrint('📱 QR Code scanned: $rawValue');

      // Set loading state
      state = state.copyWith(isLoading: true, error: null);

      // Create scan result
      final scanResult = ScanResult.fromRawValue(rawValue);
      
      // Save to database
      await SupabaseService.saveScanResult(scanResult);
      
      // Update state
      final updatedHistory = [scanResult, ...state.scanHistory];
      state = state.copyWith(
        lastScanResult: scanResult,
        scanHistory: updatedHistory,
        isScanning: false, // Stop scanning after successful scan
        isLoading: false,
        error: null,
      );

      debugPrint('✅ Scan result processed: ${scanResult.type} - ${scanResult.displayValue}');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to process scan result: $e');
      logDetailedError('Camera QR Scan', e, stackTrace: stackTrace);
      state = state.copyWith(
        isScanning: false,
        isLoading: false,
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh scan history
  /// [limit] controls how many items to fetch (-1 for unlimited)
  Future<void> refreshHistory({int limit = 100}) async {
    await _loadScanHistory(limit: limit);
  }

  /// Delete scan result from history
  Future<void> deleteScanResult(String scanId) async {
    try {
      await SupabaseService.deleteScanResult(scanId);
      
      final updatedHistory = state.scanHistory
          .where((scan) => scan.id != scanId)
          .toList();
      
      state = state.copyWith(scanHistory: updatedHistory);
      debugPrint('✅ Deleted scan result: $scanId');
      
    } catch (e) {
      debugPrint('❌ Failed to delete scan result: $e');
      state = state.copyWith(error: 'Failed to delete scan result: $e');
    }
  }

  /// Clear all scan history
  Future<void> clearAllHistory() async {
    try {
      await SupabaseService.clearScanHistory();
      state = state.copyWith(scanHistory: []);
      debugPrint('✅ Cleared all scan history');
      
    } catch (e) {
      debugPrint('❌ Failed to clear scan history: $e');
      state = state.copyWith(error: 'Failed to clear scan history: $e');
    }
  }

  /// Scan QR code from gallery image using real analyzeImage API
  Future<void> scanFromGallery(MobileScannerController controller) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      debugPrint('📷 Opening gallery for QR scan...');

      // No runtime permission is requested here on purpose. Picking a single
      // image goes through a system picker (Android Photo Picker, or
      // PHPickerViewController on iOS) which hands back a scoped grant for the
      // chosen file only — READ_MEDIA_IMAGES / Permission.photos are never
      // needed. Asking anyway used to break this flow outright below API 33,
      // where permission_handler resolves Photos to "denied" because
      // READ_MEDIA_IMAGES does not exist on those versions.
      final ImagePicker picker = ImagePicker();
      // The image is handed straight to the barcode analyzer, so it must not be
      // downscaled or re-encoded: doing so blurs module edges and makes dense
      // QR codes undecodable. requestFullMetadata:false skips reading EXIF/GPS
      // we have no use for.
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (image == null) {
        debugPrint('❌ No image selected from gallery');
        state = state.copyWith(isLoading: false);
        return;
      }

      debugPrint('📷 Image selected: ${image.path}');

      // Stop live camera stream before calling analyzeImage (avoids undefined behavior)
      await controller.stop();

      try {
        final BarcodeCapture? capture = await controller.analyzeImage(image.path);

        if (capture != null && capture.barcodes.isNotEmpty) {
          final rawValue = capture.barcodes.first.rawValue;
          if (rawValue != null && rawValue.isNotEmpty) {
            final scanResult = ScanResult.fromRawValue(rawValue);
            // The decoded QR is what the user came for: a failed history save (offline,
            // server error) must not throw it away or leave the spinner running.
            try {
              await SupabaseService.saveScanResult(scanResult);
            } catch (e) {
              logDetailedError('Gallery scan history save', e);
            }
            final updatedHistory = [scanResult, ...state.scanHistory];
            state = state.copyWith(
              lastScanResult: scanResult,
              scanHistory: updatedHistory,
              isLoading: false,
              error: null,
            );
            debugPrint('✅ Gallery scan result: ${scanResult.type} - ${scanResult.displayValue}');
          } else {
            state = state.copyWith(isLoading: false, error: 'noQRFoundInImage');
          }
        } else {
          state = state.copyWith(isLoading: false, error: 'noQRFoundInImage');
        }
      } on MobileScannerBarcodeException catch (e) {
        logDetailedError('Gallery analyzeImage', e);
        state = state.copyWith(isLoading: false, error: 'galleryScanFailed');
      } finally {
        // Resume live camera stream regardless of outcome. A restart failure must not be
        // reported as "couldn't read the image" on top of a successful scan.
        try {
          await controller.start();
        } catch (e) {
          logDetailedError('Gallery camera restart', e);
        }
      }

    } catch (e) {
      debugPrint('❌ Failed to scan QR from gallery: $e');
      logDetailedError('Gallery QR Scan', e);
      // Never leave the screen stuck loading; report a localized key to the UI.
      state = state.copyWith(isLoading: false, error: 'galleryScanFailed');
    }
  }


  /// Enhanced error logging for debugging
  void logDetailedError(String context, dynamic error, {StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final errorDetails = {
      'timestamp': timestamp,
      'context': context,
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'state': {
        'isScanning': state.isScanning,
        'isLoading': state.isLoading,
        'historyCount': state.scanHistory.length,
      }
    };
    
    debugPrint('🚨 DETAILED ERROR LOG:');
    debugPrint('   Context: $context');
    debugPrint('   Error: $error');
    debugPrint('   Timestamp: $timestamp');
    if (stackTrace != null) {
      debugPrint('   Stack Trace: ${stackTrace.toString()}');
    }
    debugPrint('   Current State: ${errorDetails['state']}');
    
    // Store error for potential reporting
    state = state.copyWith(error: '$context: $error');
  }
}

/// QR Scanner Provider
final qrScannerProvider = StateNotifierProvider<QRScannerController, QRScannerState>((ref) {
  return QRScannerController();
});

/// Individual state providers for easier access
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(qrScannerProvider).isScanning;
});

final isFlashOnProvider = Provider<bool>((ref) {
  return ref.watch(qrScannerProvider).isFlashOn;
});

final lastScanResultProvider = Provider<ScanResult?>((ref) {
  return ref.watch(qrScannerProvider).lastScanResult;
});

final scanHistoryProvider = Provider<List<ScanResult>>((ref) {
  return ref.watch(qrScannerProvider).scanHistory;
});

final scannerErrorProvider = Provider<String?>((ref) {
  return ref.watch(qrScannerProvider).error;
});

final scannerLoadingProvider = Provider<bool>((ref) {
  return ref.watch(qrScannerProvider).isLoading;
});