import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/cart_repository_impl.dart';

/// Handles upload of pre-rasterized QR PNGs to Supabase Storage bucket
/// 'order-assets/' (private bucket — access via signed URL).
///
/// Storage path convention: '{userId}/{qrCodeId}/{variantId}.png'
///
/// Security (T-08-03-02):
/// - Bucket is private; access via signed URLs that expire in 1 hour.
/// - RLS INSERT policy requires path prefix == auth.uid() so users can only
///   write to their own namespace.
/// - Phase 9 regenerates fresh signed URLs at order creation time.
class OrderAssetsStorageDataSource {
  static const _bucket = 'order-assets';

  final SupabaseClient _client;

  const OrderAssetsStorageDataSource(this._client);

  /// Returns the storage path for a given (userId, qrCodeId, variantId).
  ///
  /// No leading slash; no bucket name prefix — matches Supabase Storage API
  /// expectations (T-08-03-04).
  static String storagePath(
    String userId,
    String qrCodeId,
    String variantId,
  ) =>
      '$userId/$qrCodeId/$variantId.png';

  /// Uploads [pngBytes] to the order-assets/ bucket and returns a signed URL
  /// valid for 3600 seconds (1 hour).
  ///
  /// Uses upsert so that a retry after a network failure does not produce a
  /// duplicate-key conflict.
  ///
  /// Throws [CartException('png_upload_failed', message)] on [StorageException].
  Future<String> upload({
    required String userId,
    required String qrCodeId,
    required String variantId,
    required Uint8List pngBytes,
  }) async {
    final path = storagePath(userId, qrCodeId, variantId);
    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            pngBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true, // safe re-upload on retry
            ),
          );
      // Signed URL valid 1h — Phase 9 regenerates at order creation.
      final signedUrl =
          await _client.storage.from(_bucket).createSignedUrl(path, 3600);
      return signedUrl;
    } on StorageException catch (e) {
      throw CartException('png_upload_failed', e.message);
    }
  }

  /// Writes the [pngStorageUrl] back to the cart_items row identified by
  /// [cartItemId].
  ///
  /// Called after a successful upload to patch the URL without a full re-add.
  /// RLS UPDATE policy on cart_items enforces user_id = auth.uid()
  /// (T-08-03-04).
  Future<void> patchPngUrl(String cartItemId, String pngStorageUrl) async {
    await _client
        .from('cart_items')
        .update({'png_storage_url': pngStorageUrl}).eq('id', cartItemId);
  }
}
