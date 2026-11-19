import '../../domain/entities/product_variant_entity.dart';
import 'material_model.dart';

class ProductVariantModel {
  final String id;
  final String productId;
  final String productSlug;
  final String productNameEs;
  final String productNameEn;
  final String? productDescriptionEs;
  final MaterialModel material;
  final String sizeLabel;
  final int widthMm;
  final int heightMm;
  final int priceCop; // INT from DB — whole pesos
  final String? sku;
  final bool isActive;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.productSlug,
    required this.productNameEs,
    required this.productNameEn,
    this.productDescriptionEs,
    required this.material,
    required this.sizeLabel,
    required this.widthMm,
    required this.heightMm,
    required this.priceCop,
    this.sku,
    this.isActive = true,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    final material =
        MaterialModel.fromJson(json['material'] as Map<String, dynamic>);
    return ProductVariantModel(
      id: json['id'] as String,
      productId: product['id'] as String,
      productSlug: product['slug'] as String,
      productNameEs: product['name_es'] as String,
      productNameEn: product['name_en'] as String,
      productDescriptionEs: product['description_es'] as String?,
      material: material,
      sizeLabel: json['size_label'] as String,
      widthMm: json['width_mm'] as int,
      heightMm: json['height_mm'] as int,
      priceCop: json['price_cop'] as int,
      sku: json['sku'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  ProductVariantEntity toEntity() => ProductVariantEntity(
        id: id,
        productId: productId,
        productSlug: productSlug,
        productNameEs: productNameEs,
        productNameEn: productNameEn,
        productDescriptionEs: productDescriptionEs,
        material: material.toEntity(),
        sizeLabel: sizeLabel,
        widthMm: widthMm,
        heightMm: heightMm,
        priceCop: priceCop,
        sku: sku,
        isActive: isActive,
      );
}
