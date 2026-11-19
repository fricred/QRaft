import '../../domain/entities/product_variant_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_supabase_data_source.dart';
import '../models/product_image_index.dart';
import '../models/product_variant_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductSupabaseDataSource _dataSource;
  const ProductRepositoryImpl(this._dataSource);

  @override
  Future<List<ProductVariantEntity>> getActiveCatalog() async {
    // Both queries are issued together; the images one already degrades to an
    // empty index on failure, so a photo problem never costs us the catalog.
    final results = await Future.wait([
      _dataSource.getActiveCatalog(),
      _dataSource.getProductImages(),
    ]);

    final models = results[0] as List<ProductVariantModel>;
    final images = results[1] as ProductImageIndex;

    return models.map((m) {
      final entity = m.toEntity();
      return entity.withImages(
        images.resolveFor(
          productId: entity.productId,
          materialId: entity.material.id,
          variantId: entity.id,
        ),
      );
    }).toList();
  }
}
