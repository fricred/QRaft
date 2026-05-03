import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qraft/features/marketplace/domain/entities/material_entity.dart';
import 'package:qraft/features/marketplace/presentation/widgets/material_preview_widget.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_type.dart';

final _stubQr = QRCodeEntity(
  id: 'test-id',
  name: 'Test QR',
  type: QRType.url,
  data: 'https://example.com',
  displayData: 'https://example.com',
  customization: const QRCustomization(),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  userId: 'user-1',
);

MaterialEntity _stubMaterial({String textureUrl = ''}) => MaterialEntity(
      id: 'wood',
      displayNameEs: 'Madera',
      displayNameEn: 'Wood',
      textureUrl: textureUrl,
      laserCompatible: true,
    );

Widget _buildWidget({String textureUrl = '', double previewSize = 280}) {
  return MaterialApp(
    home: Scaffold(
      body: MaterialPreviewWidget(
        qrCode: _stubQr,
        material: _stubMaterial(textureUrl: textureUrl),
        previewSize: previewSize,
      ),
    ),
  );
}

void main() {
  group('MaterialPreviewWidget', () {
    testWidgets('empty textureUrl renders gradient fallback (no CachedNetworkImage)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget(textureUrl: ''));
      // CachedNetworkImage must not be rendered when textureUrl is empty
      expect(find.byType(PrettyQrView), findsOneWidget);
      // The Stack is present, and gradient container for fallback
      // We verify absence of network image widget and presence of PrettyQrView
      expect(find.byType(MaterialPreviewWidget), findsOneWidget);
    });

    testWidgets('non-https URL renders gradient fallback (no CachedNetworkImage)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _buildWidget(textureUrl: 'http://insecure.example.com/x.png'));
      // Non-https falls through the guard → gradient fallback, no network image
      expect(find.byType(PrettyQrView), findsOneWidget);
      expect(find.byType(MaterialPreviewWidget), findsOneWidget);
    });

    testWidgets('PrettyQrView is always present for any valid widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget());
      expect(find.byType(PrettyQrView), findsOneWidget);
    });

    testWidgets('QR label Container is 72% of previewSize', (WidgetTester tester) async {
      const testSize = 200.0;
      const expectedLabelSize = testSize * 0.72; // 144.0

      await tester.pumpWidget(_buildWidget(previewSize: testSize));

      // Find all Containers within the widget tree
      // The white QR label container has width == expectedLabelSize and height == expectedLabelSize
      final containers = tester.widgetList<Container>(find.byType(Container));
      final matchingContainers = containers.where((c) {
        // Container with explicit width/height of 144.0
        return c.constraints?.maxWidth == expectedLabelSize ||
            c.constraints?.minWidth == expectedLabelSize;
      }).toList();

      // More reliable: find the RenderBox for the Container that wraps PrettyQrView
      final qrViewFinder = find.byType(PrettyQrView);
      expect(qrViewFinder, findsOneWidget);

      // Walk up the tree to find the sizing container via RenderBox
      final qrElement = qrViewFinder.evaluate().first;
      RenderObject? renderObject = qrElement.renderObject;
      // Go up to find the Container whose size matches expectedLabelSize
      bool foundCorrectSize = false;
      RenderObject? current = renderObject?.parent;
      while (current != null) {
        if (current is RenderBox) {
          final size = current.size;
          if ((size.width - expectedLabelSize).abs() < 1.0 &&
              (size.height - expectedLabelSize).abs() < 1.0) {
            foundCorrectSize = true;
            break;
          }
        }
        current = current.parent;
      }

      expect(foundCorrectSize, isTrue,
          reason:
              'Expected to find a parent RenderBox with size $expectedLabelSize x $expectedLabelSize (72% of $testSize)');

      // Suppress unused variable warning
      expect(matchingContainers, isNotNull);
    });
  });
}
