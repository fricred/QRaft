import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/marketplace/domain/entities/material_entity.dart';
import 'package:qraft/features/marketplace/domain/entities/product_image_entity.dart';
import 'package:qraft/features/marketplace/domain/entities/product_variant_entity.dart';
import 'package:qraft/features/marketplace/presentation/widgets/product_variant_card.dart';

/// The white plate with a QR glyph the card paints over the material — a
/// simulation, valid only while there is no photo of the real article.
final _simulatedPlate = find.byIcon(Icons.qr_code_2_rounded);

ProductVariantEntity _variant({
  String textureUrl = '',
  List<ProductImageEntity> images = const [],
}) =>
    ProductVariantEntity(
      id: 'v1',
      productId: 'p1',
      productSlug: 'placa',
      productNameEs: 'Placa QR',
      productNameEn: 'QR Plate',
      material: MaterialEntity(
        id: 'wood',
        displayNameEs: 'Madera',
        displayNameEn: 'Wood',
        textureUrl: textureUrl,
        laserCompatible: true,
      ),
      sizeLabel: '10x10cm',
      widthMm: 100,
      heightMm: 100,
      priceCop: 89000,
      images: images,
    );

ProductImageEntity _photo({String url = 'https://cdn.example.com/a.webp'}) =>
    ProductImageEntity(
      id: 'img-1',
      url: url,
      thumbUrl: null,
      scope: ProductImageScope.material,
    );

Future<void> _pumpCard(WidgetTester tester, ProductVariantEntity variant) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SizedBox(
          width: 180,
          height: 260,
          child: ProductVariantCard(variant: variant, onTap: () {}),
        ),
      ),
    ),
  );
  // flutter_animate's staggered entrance schedules a timer (delay + 350ms);
  // pump past it so the test doesn't end with it still pending.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('ProductVariantCard thumbnail', () {
    testWidgets('shows the simulated QR plate when there is no photo',
        (tester) async {
      await _pumpCard(tester, _variant());

      expect(_simulatedPlate, findsOneWidget);
    });

    testWidgets('drops the simulated plate once a real photo exists',
        (tester) async {
      await _pumpCard(tester, _variant(images: [_photo()]));

      // Painting a fake engraved plate over a photo of the physical product
      // would stack a false representation on top of a true one.
      expect(_simulatedPlate, findsNothing);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('a non-https photo url is not treated as a photo',
        (tester) async {
      await _pumpCard(
        tester,
        _variant(images: [_photo(url: 'http://cdn.example.com/a.webp')]),
      );

      // T-07-02: the guard must fail closed — back to the simulation, never to
      // an insecure request.
      expect(_simulatedPlate, findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('no photo and no texture falls through to the gradient',
        (tester) async {
      await _pumpCard(tester, _variant());

      // Neither layer issues a request: the card is pure Dart paint.
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('no photo but a texture still renders the texture',
        (tester) async {
      await _pumpCard(
        tester,
        _variant(textureUrl: 'https://cdn.example.com/wood.jpg'),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      // Texture is not a product photo, so the simulation stays.
      expect(_simulatedPlate, findsOneWidget);
    });
  });
}
