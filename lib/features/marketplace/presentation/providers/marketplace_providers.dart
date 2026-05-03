import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/product_supabase_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../../domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final datasource = ProductSupabaseDataSource(Supabase.instance.client);
  return ProductRepositoryImpl(datasource);
});

/// Loads all active variants once; autoDispose clears cache when all listeners gone.
final catalogProvider =
    FutureProvider.autoDispose<List<ProductVariantEntity>>((ref) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getActiveCatalog();
});

/// Holds the QR code id selected in the QR library for marketplace preview.
/// Set to null when user navigates to marketplace without coming from library.
/// Used as a bridge so the two features remain loosely coupled.
final selectedQrForMarketplaceProvider = StateProvider<String?>((ref) => null);

/// Active material filter chip. Empty string = show all materials.
final activeMaterialFilterProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Derived: catalog filtered by active material (client-side, in-memory).
final filteredCatalogProvider =
    Provider.autoDispose<AsyncValue<List<ProductVariantEntity>>>((ref) {
  final catalog = ref.watch(catalogProvider);
  final filter = ref.watch(activeMaterialFilterProvider);
  if (filter.isEmpty) return catalog;
  return catalog.whenData(
    (variants) => variants.where((v) => v.material.id == filter).toList(),
  );
});
