import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/marketplace/data/models/product_image_index.dart';
import 'package:qraft/features/marketplace/domain/entities/product_image_entity.dart';

/// Deterministic stand-in for Supabase Storage's getPublicUrl.
String _resolver(String bucket, String path) =>
    'https://cdn.example.com/storage/v1/object/public/$bucket/$path';

Map<String, dynamic> _row({
  required String id,
  required String storagePath,
  String productId = 'p1',
  String? materialId,
  String? variantId,
  String? thumbPath,
  int position = 0,
  bool isPrimary = false,
  String? updatedAt,
}) =>
    {
      'id': id,
      'product_id': productId,
      'material_id': materialId,
      'product_variant_id': variantId,
      'bucket_id': 'product-images',
      'storage_path': storagePath,
      'thumb_path': thumbPath,
      'alt_text_es': '',
      'alt_text_en': '',
      'position': position,
      'is_primary': isPrimary,
      'scope': variantId != null
          ? 'variant'
          : materialId != null
              ? 'material'
              : 'product',
      'updated_at': updatedAt,
    };

void main() {
  group('ProductImageIndex precedence', () {
    test('orders variant, then material, then product', () {
      final index = ProductImageIndex.fromRows([
        _row(id: 'prod', storagePath: 'placa/_all/01.webp'),
        _row(id: 'var', storagePath: 'placa/v/01.webp', variantId: 'v1'),
        _row(id: 'mat', storagePath: 'placa/wood/01.webp', materialId: 'wood'),
      ], _resolver);

      final resolved = index.resolveFor(
        productId: 'p1',
        materialId: 'wood',
        variantId: 'v1',
      );

      expect(resolved.map((i) => i.id).toList(), ['var', 'mat', 'prod']);
      expect(resolved.first.scope, ProductImageScope.variant);
    });

    test('excludes photos of a different material', () {
      final index = ProductImageIndex.fromRows([
        _row(id: 'wood', storagePath: 'placa/wood/01.webp', materialId: 'wood'),
        _row(id: 'metal', storagePath: 'placa/metal/01.webp', materialId: 'metal'),
      ], _resolver);

      final resolved = index.resolveFor(
        productId: 'p1',
        materialId: 'wood',
        variantId: 'v1',
      );

      expect(resolved.map((i) => i.id).toList(), ['wood']);
    });

    test('excludes photos of a different product', () {
      final index = ProductImageIndex.fromRows([
        _row(id: 'other', storagePath: 'llavero/_all/01.webp', productId: 'p2'),
      ], _resolver);

      expect(
        index.resolveFor(productId: 'p1', materialId: 'wood', variantId: 'v1'),
        isEmpty,
      );
    });

    test('within a scope, primary wins over position', () {
      final index = ProductImageIndex.fromRows([
        _row(
          id: 'second',
          storagePath: 'placa/wood/02.webp',
          materialId: 'wood',
          position: 0,
        ),
        _row(
          id: 'hero',
          storagePath: 'placa/wood/01.webp',
          materialId: 'wood',
          position: 5,
          isPrimary: true,
        ),
      ], _resolver);

      final resolved = index.resolveFor(
        productId: 'p1',
        materialId: 'wood',
        variantId: 'v1',
      );

      expect(resolved.first.id, 'hero');
    });
  });

  group('ProductImageIndex safety', () {
    test('drops rows whose storage path is absolute or traverses', () {
      final index = ProductImageIndex.fromRows([
        _row(id: 'abs', storagePath: 'https://evil.example.com/x.webp'),
        _row(id: 'root', storagePath: '/etc/passwd'),
        _row(id: 'up', storagePath: '../../secret.webp'),
        _row(id: 'ok', storagePath: 'placa/_all/01.webp'),
      ], _resolver);

      final resolved = index.resolveFor(
        productId: 'p1',
        materialId: 'wood',
        variantId: 'v1',
      );

      expect(resolved.map((i) => i.id).toList(), ['ok']);
    });

    test('drops rows whose resolved URL is not https', () {
      final index = ProductImageIndex.fromRows(
        [_row(id: 'insecure', storagePath: 'placa/_all/01.webp')],
        (bucket, path) => 'http://cdn.example.com/$bucket/$path',
      );

      expect(
        index.resolveFor(productId: 'p1', materialId: 'wood', variantId: 'v1'),
        isEmpty,
      );
    });

    test('appends a cache-busting stamp derived from updated_at', () {
      final index = ProductImageIndex.fromRows([
        _row(
          id: 'ok',
          storagePath: 'placa/_all/01.webp',
          updatedAt: '2026-08-13T10:00:00Z',
        ),
      ], _resolver);

      final image = index
          .resolveFor(productId: 'p1', materialId: 'wood', variantId: 'v1')
          .single;

      expect(image.url, contains('?v='));
    });

    test('falls back to the full image when there is no thumbnail', () {
      final index = ProductImageIndex.fromRows([
        _row(id: 'ok', storagePath: 'placa/_all/01.webp'),
      ], _resolver);

      final image = index
          .resolveFor(productId: 'p1', materialId: 'wood', variantId: 'v1')
          .single;

      expect(image.thumbUrl, isNull);
      expect(image.gridUrl, image.url);
    });
  });
}
