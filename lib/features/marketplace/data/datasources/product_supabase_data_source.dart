import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_image_index.dart';
import '../models/product_variant_model.dart';

class ProductSupabaseDataSource {
  final SupabaseClient _supabase;
  final PublicUrlResolver? _resolveUrl;

  const ProductSupabaseDataSource(this._supabase, {PublicUrlResolver? resolveUrl})
      : _resolveUrl = resolveUrl;

  /// Storage URLs are built from the configured project host, so a poisoned row
  /// cannot point the app at another origin. Injectable for tests.
  PublicUrlResolver get _urlResolver =>
      _resolveUrl ??
      (bucket, path) => _supabase.storage.from(bucket).getPublicUrl(path);

  Future<List<ProductVariantModel>> getActiveCatalog() async {
    final rows = await _supabase
        .from('product_variants')
        .select('''
          id, size_label, width_mm, height_mm, price_cop, sku, is_active,
          product:products(id, slug, name_es, name_en, description_es),
          material:materials(id, display_name_es, display_name_en, texture_url, laser_compatible)
        ''')
        .eq('is_active', true)
        .order('material_id')
        .order('price_cop');

    return (rows as List<dynamic>)
        .map((r) => ProductVariantModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Product photography, indexed for per-variant resolution.
  ///
  /// Queried separately rather than embedded under the variant select: PostgREST
  /// would repeat every image of a product once per variant, growing the payload
  /// as O(variants × images). `catalogProvider` is autoDispose and refetches on
  /// each tab visit, so that cost would be paid repeatedly.
  ///
  /// Failures degrade to an empty index instead of propagating. Without this, an
  /// app build shipped ahead of the migration would show an empty marketplace
  /// rather than the material-texture fallback.
  Future<ProductImageIndex> getProductImages() async {
    try {
      final rows = await _supabase
          .from('product_images')
          .select(
            'id, product_id, material_id, product_variant_id, bucket_id, '
            'storage_path, thumb_path, alt_text_es, alt_text_en, position, '
            'is_primary, scope, updated_at',
          )
          .eq('is_active', true)
          .order('position');

      return ProductImageIndex.fromRows(rows as List<dynamic>, _urlResolver);
    } catch (_) {
      return ProductImageIndex.empty;
    }
  }
}
