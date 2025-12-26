import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/data/providers/supabase_auth_provider.dart';
import '../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../qr_library/presentation/providers/qr_library_providers.dart';

// Re-export shared QR providers for convenience
export '../../qr_library/presentation/providers/qr_library_providers.dart'
    show userQRCodesProvider, recentQRCodesLimitedProvider;

/// Dashboard statistics data model
class DashboardStats {
  final int qrCodesCount;
  final int scanHistoryCount;
  final List<QRCodeEntity> recentQRCodes;
  final List<Map<String, dynamic>> recentScans;

  const DashboardStats({
    required this.qrCodesCount,
    required this.scanHistoryCount,
    required this.recentQRCodes,
    required this.recentScans,
  });

  DashboardStats copyWith({
    int? qrCodesCount,
    int? scanHistoryCount,
    List<QRCodeEntity>? recentQRCodes,
    List<Map<String, dynamic>>? recentScans,
  }) {
    return DashboardStats(
      qrCodesCount: qrCodesCount ?? this.qrCodesCount,
      scanHistoryCount: scanHistoryCount ?? this.scanHistoryCount,
      recentQRCodes: recentQRCodes ?? this.recentQRCodes,
      recentScans: recentScans ?? this.recentScans,
    );
  }
}

/// Provider for QR codes count for current user (uses shared userQRCodesProvider)
final qrCodesCountProvider = Provider<int>((ref) {
  final qrCodesAsync = ref.watch(userQRCodesProvider);

  return qrCodesAsync.when(
    data: (qrCodes) => qrCodes.length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

/// Provider for scan history count for current user
final scanHistoryCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  if (authState == null) {
    return 0;
  }

  try {
    final scanHistory = await SupabaseService.getCurrentUserScanHistory();
    return scanHistory.length;
  } catch (e) {
    debugPrint('Error fetching scan history count: $e');
    return 0;
  }
});

/// Dashboard-specific: get last 5 QR codes (uses shared recentQRCodesLimitedProvider)
final dashboardRecentQRCodesProvider = Provider<List<QRCodeEntity>>((ref) {
  return ref.watch(recentQRCodesLimitedProvider(5));
});

/// Provider for recent scans (last 5) for current user
final recentScansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  if (authState == null) {
    return [];
  }

  try {
    final scanHistory = await SupabaseService.getCurrentUserScanHistory();
    return scanHistory.take(5).toList(); // Get last 5 scans
  } catch (e) {
    debugPrint('Error fetching recent scans: $e');
    return [];
  }
});

/// Comprehensive dashboard statistics provider (uses shared userQRCodesProvider)
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final recentQRCodes = ref.watch(dashboardRecentQRCodesProvider);
  final qrCodesCount = ref.watch(qrCodesCountProvider);
  final scanHistoryCountAsync = ref.watch(scanHistoryCountProvider);
  final recentScansAsync = ref.watch(recentScansProvider);

  final scanHistoryCount = scanHistoryCountAsync.when(
    data: (count) => count,
    loading: () => 0,
    error: (_, __) => 0,
  );

  final recentScans = recentScansAsync.when(
    data: (scans) => scans,
    loading: () => <Map<String, dynamic>>[],
    error: (_, __) => <Map<String, dynamic>>[],
  );

  return DashboardStats(
    qrCodesCount: qrCodesCount,
    scanHistoryCount: scanHistoryCount,
    recentQRCodes: recentQRCodes,
    recentScans: recentScans,
  );
});

/// Provider to refresh dashboard data
final dashboardRefreshProvider = StateProvider<DateTime>((ref) => DateTime.now());