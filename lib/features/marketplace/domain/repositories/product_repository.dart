import '../entities/product_variant_entity.dart';

abstract class ProductRepository {
  Future<List<ProductVariantEntity>> getActiveCatalog();
}
