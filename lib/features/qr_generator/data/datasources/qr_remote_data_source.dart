import '../models/qr_code_model.dart';

abstract class QRRemoteDataSource {
  Future<QRCodeModel> saveQRCode(QRCodeModel qrCode);
  Future<List<QRCodeModel>> getUserQRCodes(String userId);
  Future<QRCodeModel?> getQRCodeById(String id);
  Future<QRCodeModel> updateQRCode(QRCodeModel qrCode);
  Future<void> deleteQRCode(String id);
  Future<List<QRCodeModel>> getQRCodesByType(String userId, String type);
  Future<QRCodeModel> toggleFavorite(String qrCodeId, bool isFavorite);
  Future<List<QRCodeModel>> getFavoriteQRCodes(String userId);
}