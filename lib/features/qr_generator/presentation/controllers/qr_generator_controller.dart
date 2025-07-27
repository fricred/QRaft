import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_data_models.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/use_cases/generate_qr_use_case.dart';
import '../providers/qr_providers.dart';

class QRGeneratorState {
  final bool isLoading;
  final String? error;
  final QRCodeEntity? generatedQR;
  final List<QRCodeEntity> userQRCodes;

  const QRGeneratorState({
    this.isLoading = false,
    this.error,
    this.generatedQR,
    this.userQRCodes = const [],
  });

  QRGeneratorState copyWith({
    bool? isLoading,
    String? error,
    QRCodeEntity? generatedQR,
    List<QRCodeEntity>? userQRCodes,
  }) {
    return QRGeneratorState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      generatedQR: generatedQR ?? this.generatedQR,
      userQRCodes: userQRCodes ?? this.userQRCodes,
    );
  }
}

class QRGeneratorController extends StateNotifier<QRGeneratorState> {
  final GenerateQRUseCase _generateQRUseCase;
  final GetUserQRCodesUseCase _getUserQRCodesUseCase;
  final UpdateQRCodeUseCase _updateQRCodeUseCase;
  final DeleteQRCodeUseCase _deleteQRCodeUseCase;

  QRGeneratorController({
    required GenerateQRUseCase generateQRUseCase,
    required GetUserQRCodesUseCase getUserQRCodesUseCase,
    required UpdateQRCodeUseCase updateQRCodeUseCase,
    required DeleteQRCodeUseCase deleteQRCodeUseCase,
  })  : _generateQRUseCase = generateQRUseCase,
        _getUserQRCodesUseCase = getUserQRCodesUseCase,
        _updateQRCodeUseCase = updateQRCodeUseCase,
        _deleteQRCodeUseCase = deleteQRCodeUseCase,
        super(const QRGeneratorState());

  Future<void> generateQR({
    required String name,
    required QRType type,
    required QRDataModel data,
    required String userId,
    QRCustomization? customization,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final qrCode = await _generateQRUseCase.execute(
        name: name,
        type: type,
        data: data,
        userId: userId,
        customization: customization,
      );

      state = state.copyWith(
        isLoading: false,
        generatedQR: qrCode,
        userQRCodes: [qrCode, ...state.userQRCodes],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadUserQRCodes(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final qrCodes = await _getUserQRCodesUseCase.execute(userId);
      state = state.copyWith(
        isLoading: false,
        userQRCodes: qrCodes,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateQRCode(QRCodeEntity qrCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedQRCode = await _updateQRCodeUseCase.execute(qrCode);
      
      final updatedList = state.userQRCodes.map((qr) {
        return qr.id == updatedQRCode.id ? updatedQRCode : qr;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        userQRCodes: updatedList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteQRCode(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _deleteQRCodeUseCase.execute(id);
      
      final updatedList = state.userQRCodes.where((qr) => qr.id != id).toList();

      state = state.copyWith(
        isLoading: false,
        userQRCodes: updatedList,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearGeneratedQR() {
    state = state.copyWith(generatedQR: null);
  }
}

final qrGeneratorControllerProvider = StateNotifierProvider<QRGeneratorController, QRGeneratorState>((ref) {
  return QRGeneratorController(
    generateQRUseCase: ref.watch(generateQRUseCaseProvider),
    getUserQRCodesUseCase: ref.watch(getUserQRCodesUseCaseProvider),
    updateQRCodeUseCase: ref.watch(updateQRCodeUseCaseProvider),
    deleteQRCodeUseCase: ref.watch(deleteQRCodeUseCaseProvider),
  );
});