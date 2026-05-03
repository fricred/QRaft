import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_variant_model.dart';

class ProductSupabaseDataSource {
  final SupabaseClient _supabase;
  const ProductSupabaseDataSource(this._supabase);

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
}
