import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qr_code_model.dart';
import 'qr_remote_data_source.dart';

class QRSupabaseDataSource implements QRRemoteDataSource {
  final SupabaseClient client;

  QRSupabaseDataSource({required this.client});

  /// Embedded select pulling each QR's redirect metadata (slug, scan stats).
  /// Requires the redirects.qr_code_id FK (migration 20260612000001).
  static const _selectWithRedirects =
      '*, redirects(id, slug, status, scan_count, last_scanned_at)';

  /// Flips to false the first time the embedded select fails (FK migration
  /// not applied yet) so subsequent fetches skip the doomed join.
  static bool _redirectJoinAvailable = true;

  @override
  Future<QRCodeModel> saveQRCode(QRCodeModel qrCode) async {
    try {
      final response = await client
          .from('qr_codes')
          .insert(qrCode.toJson())
          .select(_selectWithRedirects)
          .single();

      return QRCodeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save QR code to remote: $e');
    }
  }

  @override
  Future<List<QRCodeModel>> getUserQRCodes(String userId) async {
    if (_redirectJoinAvailable) {
      try {
        final response = await client
            .from('qr_codes')
            .select(_selectWithRedirects)
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => QRCodeModel.fromJson(json))
            // Revoked dynamic codes (refunded / deleted) are not part of the library.
            .where((q) => q.dynamicStatus != 'revoked')
            .toList();
      } on PostgrestException {
        // Relationship missing (migration 20260612000001 not applied yet) —
        // degrade to the plain select and stop attempting the join.
        _redirectJoinAvailable = false;
      }
    }

    try {
      final response = await client
          .from('qr_codes')
          .select(_selectWithRedirects)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => QRCodeModel.fromJson(json))
          // Revoked dynamic codes (refunded / deleted) are not part of the library.
          .where((q) => q.dynamicStatus != 'revoked')
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
          .select(_selectWithRedirects)
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
          .select(_selectWithRedirects)
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
          .select(_selectWithRedirects)
          .eq('user_id', userId)
          .eq('type', type)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => QRCodeModel.fromJson(json))
          // Revoked dynamic codes (refunded / deleted) are not part of the library.
          .where((q) => q.dynamicStatus != 'revoked')
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch QR codes by type: $e');
    }
  }

  @override
  Future<QRCodeModel> toggleFavorite(String qrCodeId, bool isFavorite) async {
    try {
      // First check if the QR code exists
      final existingQR = await getQRCodeById(qrCodeId);
      if (existingQR == null) {
        throw Exception('QR code with ID $qrCodeId not found in database');
      }
      
      final response = await client
          .from('qr_codes')
          .update({
            'is_favorite': isFavorite,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', qrCodeId)
          .select(_selectWithRedirects)
          .single();

      return QRCodeModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('not found')) {
        throw Exception('QR code not found in database. It may have been deleted.');
      }
      throw Exception('Failed to toggle favorite status: $e');
    }
  }

  @override
  Future<List<QRCodeModel>> getFavoriteQRCodes(String userId) async {
    try {
      final response = await client
          .from('qr_codes')
          .select(_selectWithRedirects)
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => QRCodeModel.fromJson(json))
          // Revoked dynamic codes (refunded / deleted) are not part of the library.
          .where((q) => q.dynamicStatus != 'revoked')
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch favorite QR codes: $e');
    }
  }

  @override
  Future<List<QRCodeModel>> getUserQRCodesPaginated(
    String userId,
    int page,
    int pageSize,
  ) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await client
          .from('qr_codes')
          .select(_selectWithRedirects)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return response
          .map((json) => QRCodeModel.fromJson(json))
          // Revoked dynamic codes (refunded / deleted) are not part of the library.
          .where((q) => q.dynamicStatus != 'revoked')
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated QR codes: $e');
    }
  }
}