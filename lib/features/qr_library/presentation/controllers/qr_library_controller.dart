import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/repositories/qr_repository.dart';

// QR Library State
class QRLibraryState {
  final List<QRCodeEntity> qrCodes;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedType;

  const QRLibraryState({
    this.qrCodes = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedType,
  });

  QRLibraryState copyWith({
    List<QRCodeEntity>? qrCodes,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedType,
  }) {
    return QRLibraryState(
      qrCodes: qrCodes ?? this.qrCodes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class QRLibraryController extends StateNotifier<QRLibraryState> {
  final QRRepository repository;

  QRLibraryController({required this.repository}) : super(const QRLibraryState());

  // Load user's QR codes
  Future<void> loadUserQRCodes(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final qrCodes = await repository.getUserQRCodes(userId);
      state = state.copyWith(
        qrCodes: qrCodes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Delete a QR code
  Future<void> deleteQRCode(String qrId) async {
    try {
      await repository.deleteQRCode(qrId);
      
      // Remove from current state optimistically
      final updatedQRCodes = state.qrCodes.where((qr) => qr.id != qrId).toList();
      state = state.copyWith(qrCodes: updatedQRCodes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Update selected type filter
  void updateTypeFilter(String? type) {
    state = state.copyWith(selectedType: type);
  }

  // Get filtered QR codes based on search and type
  List<QRCodeEntity> getFilteredQRCodes() {
    var filtered = List<QRCodeEntity>.from(state.qrCodes);

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((qr) =>
        qr.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
        qr.displayData.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
        qr.type.name.toLowerCase().contains(state.searchQuery.toLowerCase())
      ).toList();
    }

    // Apply type filter
    if (state.selectedType != null && state.selectedType!.isNotEmpty) {
      filtered = filtered.where((qr) => qr.type.identifier == state.selectedType).toList();
    }

    return filtered;
  }

  // Get recent QR codes (last 10)
  List<QRCodeEntity> getRecentQRCodes() {
    final sorted = List<QRCodeEntity>.from(state.qrCodes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(10).toList();
  }

  // Get QR codes by type
  List<QRCodeEntity> getQRCodesByType(String type) {
    return state.qrCodes.where((qr) => qr.type.identifier == type).toList();
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final thisMonth = state.qrCodes.where((qr) => 
      qr.createdAt.year == now.year && 
      qr.createdAt.month == now.month
    ).length;
    
    // Group by type for analytics
    final typeCount = <String, int>{};
    for (final qr in state.qrCodes) {
      typeCount[qr.type.name] = (typeCount[qr.type.name] ?? 0) + 1;
    }
    
    return {
      'total': state.qrCodes.length,
      'thisMonth': thisMonth,
      'typeCount': typeCount,
      'mostUsedType': typeCount.entries.isNotEmpty 
        ? typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : '',
    };
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String qrCodeId) async {
    try {
      // Find the QR code in current state
      final qrCodeIndex = state.qrCodes.indexWhere((qr) => qr.id == qrCodeId);
      if (qrCodeIndex == -1) {
        throw Exception('QR code not found');
      }
      
      final currentQRCode = state.qrCodes[qrCodeIndex];
      final newFavoriteStatus = !currentQRCode.isFavorite;
      
      // Update optimistically in UI
      final updatedQRCodes = List<QRCodeEntity>.from(state.qrCodes);
      updatedQRCodes[qrCodeIndex] = currentQRCode.copyWith(isFavorite: newFavoriteStatus);
      state = state.copyWith(qrCodes: updatedQRCodes);
      
      // Update in database
      await repository.toggleFavorite(qrCodeId, newFavoriteStatus);
    } catch (e) {
      // Revert on error
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // Get favorite QR codes
  List<QRCodeEntity> getFavoriteQRCodes() {
    return state.qrCodes.where((qr) => qr.isFavorite).toList();
  }

  // Refresh QR codes
  Future<void> refresh(String userId) async {
    await loadUserQRCodes(userId);
  }
}