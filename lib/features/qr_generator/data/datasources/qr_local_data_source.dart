import '../models/qr_code_model.dart';

abstract class QRLocalDataSource {
  Future<void> cacheQRCode(QRCodeModel qrCode);
  Future<void> cacheMultipleQRCodes(List<QRCodeModel> qrCodes);
  Future<List<QRCodeModel>> getCachedQRCodes(String userId);
  Future<QRCodeModel?> getCachedQRCodeById(String id);
  Future<void> deleteCachedQRCode(String id);
  Future<void> clearCache();
}