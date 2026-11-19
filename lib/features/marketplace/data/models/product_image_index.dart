import '../../domain/entities/product_image_entity.dart';
import 'marketplace_url_guards.dart';

/// Builds a public URL for a file inside a Storage bucket.
typedef PublicUrlResolver = String Function(String bucketId, String path);

/// In-memory index of `product_images` rows that resolves, for any variant, the
/// gallery it should show.
///
/// Kept as a pure class with no Supabase dependency so the precedence rules —
/// the part most likely to be wrong — are unit-testable without a network.
class ProductImageIndex {
  final List<_IndexedImage> _images;

  const ProductImageIndex._(this._images);

  static const ProductImageIndex empty = ProductImageIndex._([]);

  /// Parses raw `product_images` rows. Rows with an unsafe storage path or a
  /// non-https resolved URL are dropped rather than propagated: a bad row makes
  /// one photo missing, never a broken or attacker-controlled request.
  factory ProductImageIndex.fromRows(
    List<dynamic> rows,
    PublicUrlResolver resolveUrl,
  ) {
    final indexed = <_IndexedImage>[];

    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;

      final storagePath = raw['storage_path'] as String? ?? '';
      if (!isSafeStoragePath(storagePath)) continue;

      final bucketId = raw['bucket_id'] as String? ?? 'product-images';
      final url = sanitizeHttpsUrl(
        _withCacheBust(resolveUrl(bucketId, storagePath), raw['updated_at']),
      );
      if (url.isEmpty) continue;

      final thumbPath = raw['thumb_path'] as String?;
      String? thumbUrl;
      if (thumbPath != null && isSafeStoragePath(thumbPath)) {
        final resolved = sanitizeHttpsUrl(
          _withCacheBust(resolveUrl(bucketId, thumbPath), raw['updated_at']),
        );
        if (resolved.isNotEmpty) thumbUrl = resolved;
      }

      indexed.add(
        _IndexedImage(
          productId: raw['product_id'] as String? ?? '',
          materialId: raw['material_id'] as String?,
          variantId: raw['product_variant_id'] as String?,
          image: ProductImageEntity(
            id: raw['id'] as String? ?? storagePath,
            url: url,
            thumbUrl: thumbUrl,
            altTextEs: raw['alt_text_es'] as String? ?? '',
            altTextEn: raw['alt_text_en'] as String? ?? '',
            scope: ProductImageScopeOrder.parse(raw['scope'] as String?),
            position: (raw['position'] as num?)?.toInt() ?? 0,
            isPrimary: raw['is_primary'] as bool? ?? false,
          ),
        ),
      );
    }

    return ProductImageIndex._(indexed);
  }

  /// The gallery for one variant: variant-scoped photos first, then this
  /// product+material combination, then material-agnostic product shots.
  ///
  /// Within a scope the order is `is_primary` first, then `position`, then id —
  /// a total order, so the grid thumbnail is stable across rebuilds.
  List<ProductImageEntity> resolveFor({
    required String productId,
    required String materialId,
    required String variantId,
  }) {
    final matches = _images.where((entry) {
      if (entry.productId != productId) return false;
      return switch (entry.image.scope) {
        ProductImageScope.variant => entry.variantId == variantId,
        ProductImageScope.material => entry.materialId == materialId,
        ProductImageScope.product => true,
      };
    }).map((entry) => entry.image).toList();

    matches.sort((a, b) {
      final byScope = a.scope.specificity.compareTo(b.scope.specificity);
      if (byScope != 0) return byScope;
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      final byPosition = a.position.compareTo(b.position);
      if (byPosition != 0) return byPosition;
      return a.id.compareTo(b.id);
    });

    return matches;
  }

  /// Appends `?v={epoch}` so a re-shoot uploaded to the same path is not served
  /// stale by the CDN or by cached_network_image, both of which key by URL.
  static String _withCacheBust(String url, dynamic updatedAt) {
    if (url.isEmpty) return url;
    final stamp = DateTime.tryParse(updatedAt as String? ?? '');
    if (stamp == null) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${stamp.millisecondsSinceEpoch}';
  }
}

class _IndexedImage {
  final String productId;
  final String? materialId;
  final String? variantId;
  final ProductImageEntity image;

  const _IndexedImage({
    required this.productId,
    required this.materialId,
    required this.variantId,
    required this.image,
  });
}
