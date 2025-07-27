import 'package:uuid/uuid.dart';
import '../entities/qr_code_entity.dart';
import '../entities/qr_data_models.dart';
import '../entities/qr_type.dart';
import '../repositories/qr_repository.dart';

class GenerateQRUseCase {
  final QRRepository repository;
  final Uuid uuid = const Uuid();

  GenerateQRUseCase({required this.repository});

  Future<QRCodeEntity> execute({
    required String name,
    required QRType type,
    required QRDataModel data,
    required String userId,
    QRCustomization? customization,
  }) async {
    final qrCode = QRCodeEntity(
      id: uuid.v4(),
      name: name,
      type: type,
      data: data.qrData,
      displayData: data.displayText,
      customization: customization ?? const QRCustomization(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
    );

    return await repository.saveQRCode(qrCode);
  }
}

class GetUserQRCodesUseCase {
  final QRRepository repository;

  GetUserQRCodesUseCase({required this.repository});

  Future<List<QRCodeEntity>> execute(String userId) async {
    return await repository.getUserQRCodes(userId);
  }
}

class UpdateQRCodeUseCase {
  final QRRepository repository;

  UpdateQRCodeUseCase({required this.repository});

  Future<QRCodeEntity> execute(QRCodeEntity qrCode) async {
    final updatedQRCode = qrCode.copyWith(updatedAt: DateTime.now());
    return await repository.updateQRCode(updatedQRCode);
  }
}

class DeleteQRCodeUseCase {
  final QRRepository repository;

  DeleteQRCodeUseCase({required this.repository});

  Future<void> execute(String id) async {
    await repository.deleteQRCode(id);
  }
}