import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/marketplace/domain/entities/product_image_entity.dart';
import 'package:qraft/features/marketplace/presentation/widgets/product_gallery.dart';

/// Stand-in for the live composite. Keyed so we can prove it is mounted without
/// depending on MaterialPreviewWidget (which needs a QR entity and a network
/// texture).
const _previewKey = Key('stub-preview');

ProductImageEntity _image(String id, {String altTextEs = ''}) =>
    ProductImageEntity(
      id: id,
      url: 'https://cdn.example.com/$id.webp',
      thumbUrl: 'https://cdn.example.com/${id}_thumb.webp',
      altTextEs: altTextEs,
      scope: ProductImageScope.material,
    );

Widget _wrap(List<ProductImageEntity> images, {String? previewCaption}) =>
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: ProductGallery(
            images: images,
            preview: Container(
              key: _previewKey,
              width: 280,
              height: 280,
              color: Colors.grey,
              // Stands in for the "pick a QR" CTA the purchase flow taps.
              child: const Center(child: Text('Elegir de mi biblioteca')),
            ),
            previewCaption: previewCaption ?? 'Vista previa · tu QR',
            photoSemanticsLabel: 'Placa en Madera',
          ),
        ),
      ),
    );

void main() {
  group('ProductGallery without photos', () {
    testWidgets('returns the preview untouched — no carousel, no chips',
        (tester) async {
      await tester.pumpWidget(_wrap(const []));

      expect(find.byKey(_previewKey), findsOneWidget);
      // No PageView means no swipe surface and no behaviour change at all for
      // a catalog that has no photography yet.
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Vista previa · tu QR'), findsNothing);
      expect(find.text('Foto real del producto'), findsNothing);
    });
  });

  group('ProductGallery with photos', () {
    testWidgets('builds the preview on slide 0 without any swipe',
        (tester) async {
      await tester.pumpWidget(_wrap([_image('a'), _image('b')]));

      expect(find.byType(PageView), findsOneWidget);
      // The purchase flow taps a button that lives inside the preview. If the
      // preview were not the initial page, PageView would not have built it.
      expect(find.byKey(_previewKey), findsOneWidget);
      expect(find.text('Elegir de mi biblioteca'), findsOneWidget);
    });

    testWidgets('labels slide 0 as a preview, not as the product',
        (tester) async {
      await tester.pumpWidget(_wrap([_image('a')]));

      expect(find.text('Vista previa · tu QR'), findsOneWidget);
      // The photo caption belongs to a slide that has not been reached yet.
      expect(find.text('Foto real del producto'), findsNothing);
    });

    testWidgets('honours a caller-supplied preview caption', (tester) async {
      await tester.pumpWidget(
        _wrap([_image('a')], previewCaption: 'Vista previa'),
      );

      // "tu QR" would be a lie before one is picked.
      expect(find.text('Vista previa'), findsOneWidget);
      expect(find.text('Vista previa · tu QR'), findsNothing);
    });

    testWidgets('rail carries one tile per slide, preview included',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap([_image('a'), _image('b')]));

      expect(find.bySemanticsLabel('Vista previa con tu QR'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Foto 2'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('tapping a rail tile moves to that photo', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap([_image('a'), _image('b')]));

      await tester.tap(find.bySemanticsLabel('Foto 1'));
      // animateToPage runs for 260ms; pump past it without settling (the
      // shimmer placeholders never stop animating).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Foto real del producto'), findsOneWidget);
      expect(find.text('Vista previa · tu QR'), findsNothing);

      handle.dispose();
    });

    testWidgets('shrinking the photo list clamps the current page',
        (tester) async {
      await tester.pumpWidget(_wrap([_image('a'), _image('b')]));

      await tester.tap(find.bySemanticsLabel('Foto 2'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Switching size swaps in a variant with fewer photos.
      await tester.pumpWidget(_wrap([_image('a')]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Page 2 no longer exists; the controller must not be left pointing at it.
      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
