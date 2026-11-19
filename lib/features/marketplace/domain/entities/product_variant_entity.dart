import 'package:equatable/equatable.dart';
import 'material_entity.dart';
import 'product_image_entity.dart';

class ProductVariantEntity extends Equatable {
  final String id;
  final String productId;
  final String productSlug;
  final String productNameEs;
  final String productNameEn;
  final String? productDescriptionEs;
  final MaterialEntity material;
  final String sizeLabel; // '5x5cm','10x10cm','llavero','placa-grande'
  final int widthMm;
  final int heightMm;
  final int priceCop; // WHOLE COP PESOS — never double — e.g. 89000
  final String? sku;
  final bool isActive;

  /// Real product photos for this variant, already ordered most-specific-first.
  ///
  /// Defaults to empty so every existing call site keeps compiling and the UI
  /// degrades to the material texture / gradient it uses today.
  final List<ProductImageEntity> images;

  const ProductVariantEntity({
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
    this.images = const [],
  });

  /// The photo to lead with, or null when this variant has none yet.
  ProductImageEntity? get primaryImage => images.isEmpty ? null : images.first;

  /// True when a real photograph is available, as opposed to the simulated
  /// material preview. Callers use this to drop the fake engraved-QR plate.
  bool get hasRealPhoto =>
      (primaryImage?.gridUrl ?? '').startsWith('https://');

  /// Returns a copy carrying [images]; photos are attached after the variant is
  /// parsed, since they come from a separate query.
  ProductVariantEntity withImages(List<ProductImageEntity> images) =>
      ProductVariantEntity(
        id: id,
        productId: productId,
        productSlug: productSlug,
        productNameEs: productNameEs,
        productNameEn: productNameEn,
        productDescriptionEs: productDescriptionEs,
        material: material,
        sizeLabel: sizeLabel,
        widthMm: widthMm,
        heightMm: heightMm,
        priceCop: priceCop,
        sku: sku,
        isActive: isActive,
        images: images,
      );

  /// Returns true when this variant's material is `tattoo_transfer`.
  ///
  /// Used by [ProductDetailScreen] to conditionally show the
  /// [TattooProfileEnforcementWidget] banner (TAT-02).
  bool get isTattooCategory => material.id == 'tattoo_transfer';

  @override
  List<Object?> get props =>
      [id, productId, material.id, sizeLabel, priceCop];
}
