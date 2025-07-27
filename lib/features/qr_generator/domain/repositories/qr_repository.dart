import '../entities/qr_code_entity.dart';

abstract class QRRepository {
  Future<QRCodeEntity> saveQRCode(QRCodeEntity qrCode);
  Future<List<QRCodeEntity>> getUserQRCodes(String userId);
  Future<QRCodeEntity?> getQRCodeById(String id);
  Future<QRCodeEntity> updateQRCode(QRCodeEntity qrCode);
  Future<void> deleteQRCode(String id);
  Future<List<QRCodeEntity>> getQRCodesByType(String userId, String type);
}