import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/presentation/providers/qr_providers.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';
import '../controllers/qr_library_controller.dart';

// QR Library Controller Provider
final qrLibraryControllerProvider = StateNotifierProvider<QRLibraryController, QRLibraryState>((ref) {
  final repository = ref.watch(qrRepositoryProvider);
  return QRLibraryController(repository: repository);
});

// User QR Codes Provider
final userQRCodesProvider = FutureProvider<List<QRCodeEntity>>((ref) async {
  final user = ref.watch(authStateProvider);
  final repository = ref.watch(qrRepositoryProvider);
  
  if (user != null) {
    return repository.getUserQRCodes(user.id);
  }
  return <QRCodeEntity>[];
});

// QR Library Statistics Provider
final qrLibraryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  
  return qrCodesAsync.when(
    data: (qrCodes) {
      final now = DateTime.now();
      final thisMonth = qrCodes.where((qr) => 
        qr.createdAt.year == now.year && 
        qr.createdAt.month == now.month
      ).length;
      
      // Group by type for analytics
      final typeCount = <String, int>{};
      for (final qr in qrCodes) {
        typeCount[qr.type.name] = (typeCount[qr.type.name] ?? 0) + 1;
      }
      
      return {
        'total': qrCodes.length,
        'thisMonth': thisMonth,
        'typeCount': typeCount,
        'mostUsedType': typeCount.entries.isNotEmpty 
          ? typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : '',
      };
    },
    loading: () => {
      'total': 0,
      'thisMonth': 0,
      'typeCount': <String, int>{},
      'mostUsedType': '',
    },
    error: (error, stack) => {
      'total': 0,
      'thisMonth': 0,
      'typeCount': <String, int>{},
      'mostUsedType': '',
    },
  );
});

// Favorite QR Codes Provider
final favoriteQRCodesProvider = Provider<List<QRCodeEntity>>((ref) {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  
  return qrCodesAsync.when(
    data: (qrCodes) {
      return qrCodes.where((qr) => qr.isFavorite).toList();
    },
    loading: () => <QRCodeEntity>[],
    error: (error, stack) => <QRCodeEntity>[],
  );
});

// Recent QR Codes Provider (last 10 QR codes)
final recentQRCodesProvider = Provider<List<QRCodeEntity>>((ref) {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  
  return qrCodesAsync.when(
    data: (qrCodes) {
      final sortedByDate = List<QRCodeEntity>.from(qrCodes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sortedByDate.take(10).toList();
    },
    loading: () => <QRCodeEntity>[],
    error: (error, stack) => <QRCodeEntity>[],
  );
});

// Search QR Codes Provider
final searchQRCodesProvider = FutureProvider.family<List<QRCodeEntity>, String>((ref, searchQuery) async {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  
  return qrCodesAsync.when(
    data: (qrCodes) {
      if (searchQuery.isEmpty) return qrCodes;
      
      return qrCodes.where((qr) =>
        qr.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        qr.displayData.toLowerCase().contains(searchQuery.toLowerCase()) ||
        qr.type.name.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    },
    loading: () => <QRCodeEntity>[],
    error: (error, stack) => <QRCodeEntity>[],
  );
});

// QR Codes by Type Provider
final qrCodesByTypeProvider = FutureProvider.family<List<QRCodeEntity>, String>((ref, type) async {
  final user = ref.watch(authStateProvider);
  final repository = ref.watch(qrRepositoryProvider);
  
  if (user != null) {
    return repository.getQRCodesByType(user.id, type);
  }
  return <QRCodeEntity>[];
});

// Toggle Favorite Provider
final toggleFavoriteProvider = FutureProvider.family<QRCodeEntity, String>((ref, qrCodeId) async {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  
  return qrCodesAsync.when(
    data: (qrCodes) async {
      final qrCode = qrCodes.firstWhere((qr) => qr.id == qrCodeId);
      final repository = ref.read(qrRepositoryProvider);
      return repository.toggleFavorite(qrCodeId, !qrCode.isFavorite);
    },
    loading: () => throw Exception('QR codes are loading'),
    error: (error, stack) => throw error,
  );
});