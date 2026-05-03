import '../../domain/entities/product_variant_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_supabase_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductSupabaseDataSource _dataSource;
  const ProductRepositoryImpl(this._dataSource);

  @override
  Future<List<ProductVariantEntity>> getActiveCatalog() async {
    final models = await _dataSource.getActiveCatalog();
    return models.map((m) => m.toEntity()).toList();
  }
}
