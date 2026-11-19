import 'package:equatable/equatable.dart';

/// How narrowly a photo is scoped, mirroring `product_images.scope`.
///
/// Ordering matters: [variant] is the most specific, [product] the least. See
/// [ProductImageScopeOrder.specificity].
enum ProductImageScope { variant, material, product }

extension ProductImageScopeOrder on ProductImageScope {
  /// Lower is more specific. Used to sort a variant's resolved gallery.
  int get specificity => switch (this) {
        ProductImageScope.variant => 0,
        ProductImageScope.material => 1,
        ProductImageScope.product => 2,
      };

  static ProductImageScope parse(String? raw) => switch (raw) {
        'variant' => ProductImageScope.variant,
        'material' => ProductImageScope.material,
        _ => ProductImageScope.product,
      };
}

/// A real photograph of a product, already resolved to an absolute https URL.
///
/// URL resolution happens in the data layer (via Storage `getPublicUrl`) so
/// widgets never see storage paths or build URLs themselves.
class ProductImageEntity extends Equatable {
  final String id;
  final String url;
  /// Smaller render of [url]; null when no thumbnail was generated.
  final String? thumbUrl;
  final String altTextEs;
  final String altTextEn;
  final ProductImageScope scope;
  final int position;
  final bool isPrimary;

  const ProductImageEntity({
    required this.id,
    required this.url,
    this.thumbUrl,
    this.altTextEs = '',
    this.altTextEn = '',
    this.scope = ProductImageScope.product,
    this.position = 0,
    this.isPrimary = false,
  });

  /// Cheapest URL that is still good enough for a grid cell or a thumbnail
  /// strip. Falls back to the full-size image when no thumbnail exists.
  String get gridUrl => thumbUrl ?? url;

  @override
  List<Object?> get props => [id, url];
}
