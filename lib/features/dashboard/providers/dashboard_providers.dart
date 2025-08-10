import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/data/providers/supabase_auth_provider.dart';

/// Dashboard statistics data model
class DashboardStats {
  final int qrCodesCount;
  final int scanHistoryCount;
  final List<Map<String, dynamic>> recentQRCodes;
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
    List<Map<String, dynamic>>? recentQRCodes,
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

/// Provider for QR codes count for current user
final qrCodesCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  if (authState == null) {
    return 0;
  }

  try {
    final qrCodes = await SupabaseService.getCurrentUserQRCodes();
    return qrCodes.length;
  } catch (e) {
    // If there's an error (like table doesn't exist), return 0
    return 0;
  }
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
    // If there's an error (like table doesn't exist), return 0
    return 0;
  }
});

/// Provider for recent QR codes (last 5) for current user
final recentQRCodesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  if (authState == null) {
    return [];
  }

  try {
    final qrCodes = await SupabaseService.getCurrentUserQRCodes();
    return qrCodes.take(5).toList(); // Get last 5 QR codes
  } catch (e) {
    return [];
  }
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
    return [];
  }
});

/// Comprehensive dashboard statistics provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  if (authState == null) {
    return const DashboardStats(
      qrCodesCount: 0,
      scanHistoryCount: 0,
      recentQRCodes: [],
      recentScans: [],
    );
  }

  try {
    // Fetch all dashboard data concurrently
    final results = await Future.wait([
      SupabaseService.getCurrentUserQRCodes(),
      SupabaseService.getCurrentUserScanHistory(),
    ]);

    final qrCodes = List<Map<String, dynamic>>.from(results[0]);
    final scanHistory = List<Map<String, dynamic>>.from(results[1]);

    return DashboardStats(
      qrCodesCount: qrCodes.length,
      scanHistoryCount: scanHistory.length,
      recentQRCodes: qrCodes.take(5).toList(),
      recentScans: scanHistory.take(5).toList(),
    );
  } catch (e) {
    // If there's an error, return empty stats
    return const DashboardStats(
      qrCodesCount: 0,
      scanHistoryCount: 0,
      recentQRCodes: [],
      recentScans: [],
    );
  }
});

/// Provider to refresh dashboard data
final dashboardRefreshProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Auto-refresh dashboard data every 30 seconds when app is active
final autoRefreshDashboardProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (count) => DateTime.now());
});