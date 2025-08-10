import '../../domain/entities/qr_code_entity.dart';
import '../../domain/repositories/qr_repository.dart';
import '../datasources/qr_local_data_source.dart';
import '../datasources/qr_remote_data_source.dart';
import '../models/qr_code_model.dart';

class QRRepositoryImpl implements QRRepository {
  final QRRemoteDataSource remoteDataSource;
  final QRLocalDataSource localDataSource;

  QRRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<QRCodeEntity> saveQRCode(QRCodeEntity qrCode) async {
    try {
      final model = QRCodeModel.fromEntity(qrCode);
      final savedModel = await remoteDataSource.saveQRCode(model);
      await localDataSource.cacheQRCode(savedModel);
      return savedModel;
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }

  @override
  Future<List<QRCodeEntity>> getUserQRCodes(String userId) async {
    try {
      final remoteQRCodes = await remoteDataSource.getUserQRCodes(userId);
      
      await localDataSource.cacheMultipleQRCodes(remoteQRCodes);
      
      return remoteQRCodes;
    } catch (e) {
      final cachedQRCodes = await localDataSource.getCachedQRCodes(userId);
      return cachedQRCodes;
    }
  }

  @override
  Future<QRCodeEntity?> getQRCodeById(String id) async {
    try {
      final cachedQRCode = await localDataSource.getCachedQRCodeById(id);
      if (cachedQRCode != null) {
        return cachedQRCode;
      }
      
      final remoteQRCode = await remoteDataSource.getQRCodeById(id);
      if (remoteQRCode != null) {
        await localDataSource.cacheQRCode(remoteQRCode);
      }
      
      return remoteQRCode;
    } catch (e) {
      return await localDataSource.getCachedQRCodeById(id);
    }
  }

  @override
  Future<QRCodeEntity> updateQRCode(QRCodeEntity qrCode) async {
    try {
      final model = QRCodeModel.fromEntity(qrCode);
      final updatedModel = await remoteDataSource.updateQRCode(model);
      await localDataSource.cacheQRCode(updatedModel);
      return updatedModel;
    } catch (e) {
      throw Exception('Failed to update QR code: $e');
    }
  }

  @override
  Future<void> deleteQRCode(String id) async {
    try {
      await remoteDataSource.deleteQRCode(id);
      await localDataSource.deleteCachedQRCode(id);
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }

  @override
  Future<List<QRCodeEntity>> getQRCodesByType(String userId, String type) async {
    try {
      final remoteQRCodes = await remoteDataSource.getQRCodesByType(userId, type);
      return remoteQRCodes;
    } catch (e) {
      final cachedQRCodes = await localDataSource.getCachedQRCodes(userId);
      return cachedQRCodes.where((qr) => qr.type.identifier == type).toList();
    }
  }

  @override
  Future<QRCodeEntity> toggleFavorite(String qrCodeId, bool isFavorite) async {
    try {
      final updatedQRCode = await remoteDataSource.toggleFavorite(qrCodeId, isFavorite);
      await localDataSource.cacheQRCode(updatedQRCode);
      return updatedQRCode;
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  @override
  Future<List<QRCodeEntity>> getFavoriteQRCodes(String userId) async {
    try {
      final favoriteQRCodes = await remoteDataSource.getFavoriteQRCodes(userId);
      await localDataSource.cacheMultipleQRCodes(favoriteQRCodes);
      return favoriteQRCodes;
    } catch (e) {
      final cachedQRCodes = await localDataSource.getCachedQRCodes(userId);
      return cachedQRCodes.where((qr) => qr.isFavorite).toList();
    }
  }
}