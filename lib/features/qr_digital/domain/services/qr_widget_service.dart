import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';

// ---------------------------------------------------------------------------
// HomeWidgetAdapter — thin interface for testability
// ---------------------------------------------------------------------------

/// Abstract interface around the [HomeWidget] static API.
///
/// The default production implementation calls the real [HomeWidget] statics.
/// Tests inject a [MockHomeWidgetAdapter] (via mocktail) so that no real
/// platform channel is invoked.
///
/// Return types match the real HomeWidget API exactly:
/// - [renderFlutterWidget] returns `Future<String>` (the saved file path)
/// - [saveWidgetData]      returns `Future<bool?>`
/// - [updateWidget]        returns `Future<bool?>`
/// - [setAppGroupId]       returns `Future<bool?>`
abstract class HomeWidgetAdapter {
  Future<bool?> setAppGroupId(String appGroupId);

  Future<String> renderFlutterWidget(
    Widget widget, {
    required String key,
    required Size logicalSize,
  });

  Future<bool?> saveWidgetData<T>(String id, T? data);

  Future<bool?> updateWidget({
    String? iOSName,
    String? androidName,
  });
}

// ---------------------------------------------------------------------------
// Default production adapter — calls real HomeWidget statics
// ---------------------------------------------------------------------------

class _DefaultHomeWidgetAdapter implements HomeWidgetAdapter {
  const _DefaultHomeWidgetAdapter();

  @override
  Future<bool?> setAppGroupId(String appGroupId) =>
      HomeWidget.setAppGroupId(appGroupId);

  @override
  Future<String> renderFlutterWidget(
    Widget widget, {
    required String key,
    required Size logicalSize,
  }) =>
      HomeWidget.renderFlutterWidget(
        widget,
        key: key,
        logicalSize: logicalSize,
      );

  @override
  Future<bool?> saveWidgetData<T>(String id, T? data) =>
      HomeWidget.saveWidgetData<T>(id, data);

  @override
  Future<bool?> updateWidget({
    String? iOSName,
    String? androidName,
  }) =>
      HomeWidget.updateWidget(
        iOSName: iOSName,
        androidName: androidName,
      );
}

// ---------------------------------------------------------------------------
// QrWidgetService
// ---------------------------------------------------------------------------

/// Service that pins a [QRCodeEntity] to the device home-screen widget.
///
/// Uses [home_widget 0.9.1] to:
/// 1. Set the iOS App Group so the widget extension can read shared storage.
/// 2. Render [PrettyQrView] to a 300×300 PNG (within iOS widget memory limits).
/// 3. Save the QR label and a timestamp for native-side display.
/// 4. Trigger native widget refresh on both iOS and Android.
///
/// Static-only service — never instantiated directly.
///
/// The optional [adapter] parameter accepts a [HomeWidgetAdapter] for testing.
/// Production callers omit it and the default real adapter is used.
class QrWidgetService {
  static const String _appGroupId = 'group.io.gothcorp.qraft';
  static const String _iOSWidgetName = 'QRaftWidget';
  static const String _androidWidgetName = 'QrWidgetReceiver';
  static const String _widgetImageKey = 'qr_widget_image';

  // Static-only service — no instantiation.
  QrWidgetService._();

  /// Renders [entity] as a 300×300 PNG and pins it to the home-screen widget.
  ///
  /// Accepts an optional [adapter] for test injection; defaults to the real
  /// [HomeWidget] static methods in production.
  ///
  /// Throws whatever [HomeWidget] throws on platform errors (e.g. missing App
  /// Group entitlement on iOS — will surface as PlatformException).
  static Future<void> pinQrToWidget(
    QRCodeEntity entity, {
    HomeWidgetAdapter? adapter,
  }) async {
    final hw = adapter ?? const _DefaultHomeWidgetAdapter();

    // Build QR decoration and image from entity customization.
    final decoration = QrDecorationBuilder.buildDecoration(entity.customization);
    final qrImage = QrDecorationBuilder.buildQrImage(
      entity.data,
      entity.customization,
    );

    // Step 1: Set iOS App Group so the Widget Extension can read the PNG.
    await hw.setAppGroupId(_appGroupId);

    // Step 2: Render Flutter widget to PNG at 300×300 (T-06-14 memory guard).
    await hw.renderFlutterWidget(
      PrettyQrView(qrImage: qrImage, decoration: decoration),
      key: _widgetImageKey,
      logicalSize: const Size(300, 300),
    );

    // Step 3: Save human-readable label (truncated to 40 chars + ellipsis).
    final rawData = entity.data;
    final label = rawData.length > 40
        ? '${rawData.substring(0, 40)}…'
        : rawData;

    await hw.saveWidgetData<String>('qr_label', label);
    await hw.saveWidgetData<int>(
      'updated_at',
      DateTime.now().millisecondsSinceEpoch,
    );

    // Step 4: Trigger native widget refresh on both platforms.
    await hw.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
