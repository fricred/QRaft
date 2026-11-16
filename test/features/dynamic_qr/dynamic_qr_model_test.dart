import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/dynamic_qr/data/dynamic_qr_repository.dart';
import 'package:qraft/features/qr_generator/data/models/qr_code_model.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_type.dart';

Map<String, dynamic> qrJson({Map<String, dynamic>? customization, Object? redirects}) => {
      'id': 'q1',
      'name': 'Menú',
      'type': 'url',
      'data': 'https://scanqraft.app/abcd2345',
      'display_data': 'menu.cafe.co',
      'customization': customization ?? <String, dynamic>{},
      'created_at': '2026-11-16T10:00:00Z',
      'updated_at': '2026-11-16T10:00:00Z',
      'user_id': 'u1',
      'redirects': redirects,
    };

void main() {
  test('DynamicQr.fromJson reads status, content and the embedded QR', () {
    final c = DynamicQr.fromJson({
      'id': 'r1',
      'slug': 'abcd2345',
      'status': 'paused',
      'content_type': 'vevent',
      'content': {'payload': 'BEGIN:VEVENT\nSUMMARY:x\nEND:VEVENT'},
      'scan_count': 12,
      'last_scanned_at': '2026-11-16T11:00:00Z',
      'content_updated_at': null,
      'created_at': '2026-11-16T10:00:00Z',
      'qr_codes': qrJson(),
    });
    expect(c.status, DynamicQrStatus.paused);
    expect(c.contentType, QRType.event);
    expect(c.payload, contains('SUMMARY:x'));
    expect(c.scanCount, 12);
    expect(c.url, 'https://scanqraft.app/abcd2345');
    expect(c.name, 'Menú');
  });

  test('unknown status falls back to pending_payment, unknown type to null', () {
    final c = DynamicQr.fromJson({
      'id': 'r1', 'slug': 's', 'status': 'weird', 'content_type': 'nope', 'content': null,
      'created_at': '2026-11-16T10:00:00Z',
    });
    expect(c.status, DynamicQrStatus.pendingPayment);
    expect(c.contentType, isNull);
    expect(c.payload, '');
  });

  test('QRCodeModel keeps the full customization and the redirect state', () {
    const custom = QRCustomization(hasGradient: true, gradientStart: 0xFF112233, gradientEnd: 0xFF445566, modulePreset: 3, eyePreset: 2, frameText: 'SCAN ME');
    final m = QRCodeModel.fromJson(qrJson(
      customization: custom.toJson(),
      redirects: [
        {'id': 'r1', 'slug': 'abcd2345', 'status': 'active', 'scan_count': 4, 'last_scanned_at': null},
      ],
    ));
    expect(m.customization.hasGradient, isTrue);
    expect(m.customization.modulePreset, 3);
    expect(m.customization.frameText, 'SCAN ME');
    expect(m.isDynamic, isTrue);
    expect(m.redirectId, 'r1');
    expect(m.dynamicStatus, 'active');
    expect(QRCodeModel.fromEntity(m).toJson()['customization']['module_preset'], 3);
  });
}
