import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_code_model.dart';
import 'qr_local_data_source.dart';

class QRSharedPrefsDataSource implements QRLocalDataSource {
  static const String _qrCodesKey = 'cached_qr_codes';

  @override
  Future<void> cacheQRCode(QRCodeModel qrCode) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedQRCodes = await getCachedQRCodes(qrCode.userId);
    
    final existingIndex = cachedQRCodes.indexWhere((qr) => qr.id == qrCode.id);
    
    if (existingIndex != -1) {
      cachedQRCodes[existingIndex] = qrCode;
    } else {
      cachedQRCodes.add(qrCode);
    }
    
    await _saveCachedQRCodes(prefs, cachedQRCodes);
  }

  @override
  Future<void> cacheMultipleQRCodes(List<QRCodeModel> qrCodes) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveCachedQRCodes(prefs, qrCodes);
  }

  @override
  Future<List<QRCodeModel>> getCachedQRCodes(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_qrCodesKey);
    
    if (cachedData == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(cachedData);
      final allQRCodes = jsonList
          .map((json) => QRCodeModel.fromJson(json))
          .toList();
      
      return allQRCodes
          .where((qr) => qr.userId == userId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<QRCodeModel?> getCachedQRCodeById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_qrCodesKey);
    
    if (cachedData == null) {
      return null;
    }
    
    try {
      final List<dynamic> jsonList = json.decode(cachedData);
      final allQRCodes = jsonList
          .map((json) => QRCodeModel.fromJson(json))
          .toList();
      
      for (final qr in allQRCodes) {
        if (qr.id == id) {
          return qr;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteCachedQRCode(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_qrCodesKey);
    
    if (cachedData == null) {
      return;
    }
    
    try {
      final List<dynamic> jsonList = json.decode(cachedData);
      final allQRCodes = jsonList
          .map((json) => QRCodeModel.fromJson(json))
          .toList();
      
      allQRCodes.removeWhere((qr) => qr.id == id);
      
      await _saveCachedQRCodes(prefs, allQRCodes);
    } catch (e) {
      // Failed to delete from cache
    }
  }

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_qrCodesKey);
  }

  Future<void> _saveCachedQRCodes(SharedPreferences prefs, List<QRCodeModel> qrCodes) async {
    final jsonList = qrCodes.map((qr) => qr.toJson()).toList();
    await prefs.setString(_qrCodesKey, json.encode(jsonList));
  }
}