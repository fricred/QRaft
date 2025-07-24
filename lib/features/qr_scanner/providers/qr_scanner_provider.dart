import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
    } catch (e) {
      debugPrint('❌ Failed to load scan history: $e');
      state = state.copyWith(
        error: 'Failed to load scan history: $e',
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
      
    } catch (e) {
      debugPrint('❌ Failed to process scan result: $e');
      state = state.copyWith(
        error: 'Failed to process scan result: $e',
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