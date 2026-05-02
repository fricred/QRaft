import '../entities/redirect_entity.dart';

/// Abstract contract for redirect persistence operations.
///
/// Implemented in the data layer by [RedirectRepositoryImpl].
/// Methods map to the five RDR-01..05 capabilities:
///   - createRedirect   → RDR-01 (assign slug when QR is ordered)
///   - getRedirectBySlug → RDR-02 (resolver hot path)
///   - updateDestinationUrl → RDR-03 (free editing in v1)
///   - getUserRedirects  → RDR-04 (owner list view)
///   - incrementScanCount → RDR-05 (scan analytics)
abstract class RedirectRepository {
  /// Create a new redirect record.
  ///
  /// Generates a unique slug via [SlugGenerator.generateUntilUnique] if
  /// [entity.slug] is empty; otherwise uses the provided slug.
  /// Returns the persisted [RedirectEntity] with server-assigned id + timestamps.
  Future<RedirectEntity> createRedirect(RedirectEntity entity);

  /// Fetch a redirect by its slug.
  ///
  /// Returns `null` if no record with [slug] exists (graceful 404).
  Future<RedirectEntity?> getRedirectBySlug(String slug);

  /// Update the destination URL for a redirect owned by the current user.
  ///
  /// Returns the updated [RedirectEntity].
  /// Throws if the caller does not own the record (RLS enforcement).
  Future<RedirectEntity> updateDestinationUrl({
    required String id,
    required String destinationUrl,
  });

  /// Fetch all redirects belonging to the authenticated user, newest first.
  Future<List<RedirectEntity>> getUserRedirects();

  /// Atomically increment scan_count and update last_scanned_at / last_country.
  ///
  /// Designed to be called by the Edge Function (or unauthenticated service
  /// role) after a successful slug resolution. No return value required.
  Future<void> incrementScanCount({
    required String id,
    String? countryCode,
  });

  /// Returns true if no redirect record exists for [slug].
  ///
  /// Used by [SlugGenerator.generateUntilUnique] to confirm uniqueness
  /// before committing a new slug.
  Future<bool> isSlugAvailable(String slug);
}
