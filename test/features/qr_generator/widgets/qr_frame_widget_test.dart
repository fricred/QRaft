import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/services/qr_decoration_builder.dart';
import 'package:qraft/features/qr_generator/presentation/widgets/qr_frame_widget.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test fixtures
  // ---------------------------------------------------------------------------

  const defaultCustomization = QRCustomization();

  QrImage buildSampleQrImage() {
    return QrDecorationBuilder.buildQrImage('https://qraft.co', defaultCustomization);
  }

  PrettyQrDecoration buildSampleDecoration() {
    return QrDecorationBuilder.buildDecoration(defaultCustomization);
  }

  // ---------------------------------------------------------------------------
  // QrFrameWidget widget tests
  // ---------------------------------------------------------------------------

  group('QrFrameWidget', () {
    testWidgets('renders ctaText in a Text widget below the QR', (tester) async {
      const ctaText = 'Scan me for a surprise!';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrFrameWidget(
              qrImage: buildSampleQrImage(),
              decoration: buildSampleDecoration(),
              ctaText: ctaText,
              qrSize: 100,
            ),
          ),
        ),
      );

      // CTA text is present in the widget tree
      expect(find.text(ctaText), findsOneWidget);

      // The Text widget should be BELOW the SizedBox containing PrettyQrView —
      // verify order in the Column children.
      final column = tester.widget<Column>(find.byType(Column).first);
      final children = column.children;
      // Column has: SizedBox (QR), SizedBox (spacer), Text (CTA)
      expect(children.length, greaterThanOrEqualTo(2));
      expect(children.last, isA<Text>());
      expect((children.last as Text).data, ctaText);
    });

    testWidgets('container has at least 8px padding (outside quiet zone)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrFrameWidget(
              qrImage: buildSampleQrImage(),
              decoration: buildSampleDecoration(),
              ctaText: 'Scan me',
              qrSize: 100,
            ),
          ),
        ),
      );

      // Find the outermost Container with the frame border
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);

      // Padding must be at least 8px on all sides
      final padding = container.padding;
      if (padding != null) {
        final resolved = padding.resolve(TextDirection.ltr);
        expect(resolved.top, greaterThanOrEqualTo(8.0));
        expect(resolved.bottom, greaterThanOrEqualTo(8.0));
        expect(resolved.left, greaterThanOrEqualTo(8.0));
        expect(resolved.right, greaterThanOrEqualTo(8.0));
      } else {
        // If padding is null, EdgeInsets.all(8) is not set — fail the test
        fail('QrFrameWidget container padding must be at least 8px; got null');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Quiet zone invariant unit test
  // ---------------------------------------------------------------------------

  group('QrDecorationBuilder quiet zone invariant', () {
    test(
        'buildDecoration(defaultCustomization).quietZone == PrettyQrQuietZone.standard',
        () {
      final decoration = QrDecorationBuilder.buildDecoration(defaultCustomization);
      expect(decoration.quietZone, PrettyQrQuietZone.standard);
    });
  });
}
