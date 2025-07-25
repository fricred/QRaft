import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> _loadScanHistory() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final historyData = await SupabaseService.getScanHistory();
      
      // Convert data to ScanResult objects
      final history = historyData.map((data) {
        return ScanResult(
          id: data['id'],
          rawValue: data['rawValue'],
          type: _getTypeFromName(data['type']),
          displayValue: data['displayValue'],
          parsedData: data['parsedData'] as Map<String, dynamic>?,
          scannedAt: DateTime.parse(data['scannedAt']),
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
  Future<void> refreshHistory() async {
    await _loadScanHistory();
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

  /// Scan QR code from gallery image
  Future<void> scanFromGallery() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      debugPrint('📷 Opening gallery for QR scan...');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('❌ No image selected from gallery');
        state = state.copyWith(isLoading: false);
        return;
      }

      debugPrint('📷 Image selected: ${image.path}');
      
      try {
        debugPrint('🔍 Attempting to analyze image: ${image.path}');
        
        // Note: mobile_scanner's analyzeImage returns a bool indicating if QR codes were found
        // The actual QR data would be received through the controller's callback
        // For now, we'll create a mock implementation for testing error handling
        
        // This is a simplified mock implementation for testing purposes
        // In a production app, you would use a proper QR detection library
        debugPrint('📝 Note: Using mock implementation for gallery QR scanning');
        debugPrint('🧪 Creating mock result for testing error handling and logging...');
        
        final mockRawValue = 'https://example.com/gallery-test-qr-${DateTime.now().millisecondsSinceEpoch}';
        await _processGalleryMockResult(mockRawValue, 'Gallery Image: ${image.name}');
        
      } catch (analysisError) {
        debugPrint('❌ Error in gallery scan process: $analysisError');
        throw Exception('Gallery scan process failed: $analysisError');
      }
      
    } catch (e) {
      debugPrint('❌ Failed to scan QR from gallery: $e');
      logDetailedError('Gallery QR Scan', e);
    }
  }

  /// Process mock scan result from gallery for testing
  Future<void> _processGalleryMockResult(String rawValue, String source) async {
    try {
      debugPrint('📱 Gallery QR Code (mock): $rawValue');
      debugPrint('🖼️ Source: $source');

      // Create scan result with gallery source info
      final scanResult = ScanResult.fromRawValue(rawValue);
      
      // Add source information to parsed data
      final enhancedParsedData = Map<String, dynamic>.from(scanResult.parsedData ?? {});
      enhancedParsedData['source'] = 'gallery';
      enhancedParsedData['sourceInfo'] = source;
      enhancedParsedData['testMode'] = true; // Mark as test data

      final enhancedScanResult = ScanResult(
        id: scanResult.id,
        rawValue: scanResult.rawValue,
        type: scanResult.type,
        displayValue: scanResult.displayValue,
        parsedData: enhancedParsedData,
        scannedAt: scanResult.scannedAt,
      );
      
      // Save to database
      await SupabaseService.saveScanResult(enhancedScanResult);
      
      // Update state
      final updatedHistory = [enhancedScanResult, ...state.scanHistory];
      state = state.copyWith(
        lastScanResult: enhancedScanResult,
        scanHistory: updatedHistory,
        isLoading: false,
        error: null,
      );

      debugPrint('✅ Gallery mock scan result processed: ${enhancedScanResult.type} - ${enhancedScanResult.displayValue}');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to process gallery mock scan result: $e');
      logDetailedError('Gallery Mock Scan Processing', e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
      );
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