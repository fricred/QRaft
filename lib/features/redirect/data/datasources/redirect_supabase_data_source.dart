import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/redirect_entity.dart';

/// Low-level Supabase data access for the `redirects` table.
///
/// Each method maps to a single PostgREST call.  No retry logic here —
/// that lives in the repository layer.
class RedirectSupabaseDataSource {
  final SupabaseClient _client;
  static const String _table = 'redirects';

  const RedirectSupabaseDataSource(this._client);

  /// Insert a new redirect row and return the server-assigned record.
  Future<RedirectEntity> insert(Map<String, dynamic> data) async {
    final response = await _client
        .from(_table)
        .insert(data)
        .select()
        .single();
    return RedirectEntity.fromJson(response);
  }

  /// Fetch one redirect by slug. Returns null if not found.
  Future<RedirectEntity?> fetchBySlug(String slug) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (response == null) return null;
    return RedirectEntity.fromJson(response);
  }

  /// Update destination_url for the row identified by [id].
  Future<RedirectEntity> updateDestinationUrl(
      String id, String destinationUrl) async {
    final response = await _client
        .from(_table)
        .update({'destination_url': destinationUrl})
        .eq('id', id)
        .select()
        .single();
    return RedirectEntity.fromJson(response);
  }

  /// Fetch all redirects owned by the currently-authenticated user,
  /// ordered newest first.
  Future<List<RedirectEntity>> fetchByOwner(String ownerId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((row) => RedirectEntity.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Update scan analytics columns (last_scanned_at and last_country).
  ///
  /// Atomic scan_count increment is deferred to plan 04-02 where a
  /// Postgres RPC `increment_redirect_scan(id UUID)` will be introduced.
  /// For v1 the count is incremented in a two-step read-modify-write
  /// performed by the repository layer using the current entity value.
  Future<void> updateScanAnalytics(
    String id, {
    required int newScanCount,
    String? countryCode,
  }) async {
    await _client
        .from(_table)
        .update({
          'scan_count': newScanCount,
          'last_scanned_at': DateTime.now().toUtc().toIso8601String(),
          if (countryCode != null) 'last_country': countryCode,
        })
        .eq('id', id);
  }

  /// Check if a slug is available (no existing row).
  Future<bool> isSlugAvailable(String slug) async {
    final response = await _client
        .from(_table)
        .select('id')
        .eq('slug', slug)
        .maybeSingle();
    return response == null;
  }
}
