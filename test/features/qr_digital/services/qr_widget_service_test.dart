import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qraft/features/qr_digital/domain/services/qr_widget_service.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_type.dart';

// ---------------------------------------------------------------------------
// Mock / Fake
// ---------------------------------------------------------------------------

class MockHomeWidgetAdapter extends Mock implements HomeWidgetAdapter {}

/// Fake Widget used by registerFallbackValue — mocktail requires a fallback
/// for abstract types used in any() matchers.
class _FakeWidget extends Fake implements Widget {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeWidget';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QRCodeEntity _makeEntity({String data = 'https://example.com'}) {
  return QRCodeEntity(
    id: 'test-id',
    name: 'Test QR',
    type: QRType.url,
    data: data,
    displayData: data,
    customization: const QRCustomization(),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    userId: 'user-1',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // mocktail requires fallback values for abstract types used with any().
    registerFallbackValue(_FakeWidget());
    registerFallbackValue(const Size(300, 300));
  });

  late MockHomeWidgetAdapter adapter;

  setUp(() {
    adapter = MockHomeWidgetAdapter();

    // Default stubs — setAppGroupId returns Future<bool?>
    when(() => adapter.setAppGroupId(any())).thenAnswer((_) async => true);

    // renderFlutterWidget returns Future<String> (the saved file path)
    when(
      () => adapter.renderFlutterWidget(
        any(),
        key: any(named: 'key'),
        logicalSize: any(named: 'logicalSize'),
      ),
    ).thenAnswer((_) async => '/tmp/home_widget/qr_widget_image.png');

    // saveWidgetData is generic — stub String and int variants separately
    when(
      () => adapter.saveWidgetData<String>(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => adapter.saveWidgetData<int>(any(), any()),
    ).thenAnswer((_) async => true);

    // updateWidget returns Future<bool?>
    when(
      () => adapter.updateWidget(
        iOSName: any(named: 'iOSName'),
        androidName: any(named: 'androidName'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('QrWidgetService.pinQrToWidget', () {
    testWidgets('calls setAppGroupId with the app group constant',
        (tester) async {
      await tester.runAsync(() async {
        await QrWidgetService.pinQrToWidget(_makeEntity(), adapter: adapter);
      });

      verify(() => adapter.setAppGroupId('group.io.gothcorp.qraft')).called(1);
    });

    testWidgets(
        'calls renderFlutterWidget with key qr_widget_image and Size(300,300)',
        (tester) async {
      await tester.runAsync(() async {
        await QrWidgetService.pinQrToWidget(_makeEntity(), adapter: adapter);
      });

      verify(
        () => adapter.renderFlutterWidget(
          any(),
          key: 'qr_widget_image',
          logicalSize: const Size(300, 300),
        ),
      ).called(1);
    });

    testWidgets('calls updateWidget with correct iOS and Android names',
        (tester) async {
      await tester.runAsync(() async {
        await QrWidgetService.pinQrToWidget(_makeEntity(), adapter: adapter);
      });

      verify(
        () => adapter.updateWidget(
          iOSName: 'QRaftWidget',
          androidName: 'QrWidgetReceiver',
        ),
      ).called(1);
    });

    testWidgets('saves qr_label before calling updateWidget', (tester) async {
      final callOrder = <String>[];

      when(() => adapter.saveWidgetData<String>(any(), any())).thenAnswer((
        inv,
      ) async {
        callOrder.add('save:${inv.positionalArguments[0]}');
        return true;
      });
      when(
        () => adapter.updateWidget(
          iOSName: any(named: 'iOSName'),
          androidName: any(named: 'androidName'),
        ),
      ).thenAnswer((_) async {
        callOrder.add('update');
        return true;
      });

      await tester.runAsync(() async {
        await QrWidgetService.pinQrToWidget(_makeEntity(), adapter: adapter);
      });

      final labelIdx = callOrder.indexOf('save:qr_label');
      final updateIdx = callOrder.indexOf('update');

      expect(labelIdx, greaterThanOrEqualTo(0), reason: 'qr_label was saved');
      expect(updateIdx, greaterThanOrEqualTo(0), reason: 'update was called');
      expect(
        labelIdx,
        lessThan(updateIdx),
        reason: 'qr_label save must happen before updateWidget',
      );
    });

    testWidgets('truncates data longer than 40 chars in qr_label',
        (tester) async {
      final longData = 'https://example.com/very/long/url?param=1234567890';
      expect(longData.length, greaterThan(40));

      final capturedLabels = <String>[];

      when(() => adapter.saveWidgetData<String>(any(), any())).thenAnswer((
        inv,
      ) async {
        final key = inv.positionalArguments[0] as String;
        final value = inv.positionalArguments[1] as String?;
        if (key == 'qr_label' && value != null) {
          capturedLabels.add(value);
        }
        return true;
      });

      await tester.runAsync(() async {
        await QrWidgetService.pinQrToWidget(
          _makeEntity(data: longData),
          adapter: adapter,
        );
      });

      expect(capturedLabels, isNotEmpty, reason: 'qr_label must be saved');
      final label = capturedLabels.first;
      // 40 chars + 1 ellipsis char = 41 max
      expect(
        label.length,
        lessThanOrEqualTo(41),
        reason: 'label must be truncated with ellipsis',
      );
    });
  });
}
