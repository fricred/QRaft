import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/redirect_entity.dart';
import '../../domain/repositories/redirect_repository.dart';
import '../../domain/utils/slug_generator.dart';
import '../datasources/redirect_supabase_data_source.dart';

/// Concrete implementation of [RedirectRepository] backed by Supabase.
///
/// Slug uniqueness is guaranteed by [SlugGenerator.generateUntilUnique]
/// which calls [isSlugAvailable] before committing a new redirect.
class RedirectRepositoryImpl implements RedirectRepository {
  final RedirectSupabaseDataSource _dataSource;
  final SupabaseClient _client;

  const RedirectRepositoryImpl(this._dataSource, this._client);

  @override
  Future<RedirectEntity> createRedirect(RedirectEntity entity) async {
    // Assign a unique slug if one was not provided.
    final slug = entity.slug.isEmpty
        ? await SlugGenerator.generateUntilUnique(
            isUnique: (s) => _dataSource.isSlugAvailable(s),
          )
        : entity.slug;

    final payload = {
      'slug': slug,
      'destination_url': entity.destinationUrl,
      'owner_id': entity.ownerId,
    };

    return _dataSource.insert(payload);
  }

  @override
  Future<RedirectEntity?> getRedirectBySlug(String slug) {
    return _dataSource.fetchBySlug(slug);
  }

  @override
  Future<RedirectEntity> updateDestinationUrl({
    required String id,
    required String destinationUrl,
  }) {
    return _dataSource.updateDestinationUrl(id, destinationUrl);
  }

  @override
  Future<List<RedirectEntity>> getUserRedirects() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    return _dataSource.fetchByOwner(userId);
  }

  @override
  Future<void> incrementScanCount({
    required String id,
    String? countryCode,
  }) async {
    // Read current count then write incremented value.
    // Atomic RPC will replace this in plan 04-02.
    final current = await _dataSource.fetchBySlug(id);
    final newCount = (current?.scanCount ?? 0) + 1;
    await _dataSource.updateScanAnalytics(
      id,
      newScanCount: newCount,
      countryCode: countryCode,
    );
  }

  @override
  Future<bool> isSlugAvailable(String slug) {
    return _dataSource.isSlugAvailable(slug);
  }
}
