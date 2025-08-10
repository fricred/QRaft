import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qr_code_model.dart';
import 'qr_remote_data_source.dart';

class QRSupabaseDataSource implements QRRemoteDataSource {
  final SupabaseClient client;

  QRSupabaseDataSource({required this.client});

  @override
  Future<QRCodeModel> saveQRCode(QRCodeModel qrCode) async {
    try {
      final response = await client
          .from('qr_codes')
          .insert(qrCode.toJson())
          .select()
          .single();

      return QRCodeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save QR code to remote: $e');
    }
  }

  @override
  Future<List<QRCodeModel>> getUserQRCodes(String userId) async {
    try {
      final response = await client
          .from('qr_codes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => QRCodeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user QR codes: $e');
    }
  }

  @override
  Future<QRCodeModel?> getQRCodeById(String id) async {
    try {
      final response = await client
          .from('qr_codes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return QRCodeModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch QR code by ID: $e');
    }
  }

  @override
  Future<QRCodeModel> updateQRCode(QRCodeModel qrCode) async {
    try {
      final response = await client
          .from('qr_codes')
          .update(qrCode.toJson())
          .eq('id', qrCode.id)
          .select()
          .single();

      return QRCodeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update QR code: $e');
    }
  }

  @override
  Future<void> deleteQRCode(String id) async {
    try {
      await client
          .from('qr_codes')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }

  @override
  Future<List<QRCodeModel>> getQRCodesByType(String userId, String type) async {
    try {
      final response = await client
          .from('qr_codes')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => QRCodeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch QR codes by type: $e');
    }
  }

  @override
  Future<QRCodeModel> toggleFavorite(String qrCodeId, bool isFavorite) async {
    try {
      final response = await client
          .from('qr_codes')
          .update({
            'is_favorite': isFavorite,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', qrCodeId)
          .select()
          .single();

      return QRCodeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle favorite status: $e');
    }
  }

  @override
  Future<List<QRCodeModel>> getFavoriteQRCodes(String userId) async {
    try {
      final response = await client
          .from('qr_codes')
          .select()
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => QRCodeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch favorite QR codes: $e');
    }
  }
}