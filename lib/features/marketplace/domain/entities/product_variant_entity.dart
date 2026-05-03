import 'package:equatable/equatable.dart';
import 'material_entity.dart';

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
  });

  @override
  List<Object?> get props =>
      [id, productId, material.id, sizeLabel, priceCop];
}
