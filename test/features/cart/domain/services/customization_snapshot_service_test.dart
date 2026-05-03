import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:qraft/features/cart/domain/services/customization_snapshot_service.dart';
import 'package:qraft/features/cart/data/datasources/order_assets_storage_data_source.dart';
import 'package:qraft/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_type.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

QRCodeEntity _buildQrCode() => QRCodeEntity(
      id: 'qr-001',
      name: 'Test QR',
      type: QRType.url,
      data: 'https://example.com',
      displayData: 'https://example.com',
      customization: const QRCustomization(
        foregroundColor: 0xFF112233,
        backgroundColor: 0xFFFFFFFF,
        eyeColor: 0xFF000000,
        modulePreset: 2,
        eyePreset: 1,
        profile: 0,
      ),
      createdAt: DateTime.utc(2026, 5, 3),
      updatedAt: DateTime.utc(2026, 5, 3),
      userId: 'user-001',
    );

void main() {
  // -------------------------------------------------------------------------
  // Group 1: CustomizationSnapshotService.buildSnapshotJson
  // -------------------------------------------------------------------------
  group('CustomizationSnapshotService.buildSnapshotJson', () {
    test(
      'Test 1: returns a Map containing foregroundColor, backgroundColor, '
      'modulePreset, eyePreset, profile, data keys',
      () {
        final qrCode = _buildQrCode();
        final json = CustomizationSnapshotService.buildSnapshotJson(qrCode);

        expect(json.containsKey('foreground_color'), isTrue,
            reason: 'Missing foreground_color key');
        expect(json.containsKey('background_color'), isTrue,
            reason: 'Missing background_color key');
        expect(json.containsKey('module_preset'), isTrue,
            reason: 'Missing module_preset key');
        expect(json.containsKey('eye_preset'), isTrue,
            reason: 'Missing eye_preset key');
        expect(json.containsKey('profile'), isTrue,
            reason: 'Missing profile key');
        expect(json.containsKey('data'), isTrue, reason: 'Missing data key');
      },
    );

    test(
      'Test 2: customizationJson matches qrCode.customization.toJson() '
      'merged with {data: qrCode.data, display_data, qr_type}',
      () {
        final qrCode = _buildQrCode();
        final json = CustomizationSnapshotService.buildSnapshotJson(qrCode);

        final expected = {
          ...qrCode.customization.toJson(),
          'data': qrCode.data,
          'display_data': qrCode.displayData,
          'qr_type': qrCode.type.name,
        };

        expect(json, equals(expected));
      },
    );
  });

  // -------------------------------------------------------------------------
  // Group 2: OrderAssetsStorageDataSource
  // -------------------------------------------------------------------------
  group('OrderAssetsStorageDataSource', () {
    test(
      'Test 3: storagePath(userId, qrCodeId, variantId) returns '
      '"userId/qrCodeId/variantId.png" (no leading slash, no bucket prefix)',
      () {
        const path = OrderAssetsStorageDataSource.storagePath(
          'user-abc',
          'qr-xyz',
          'variant-123',
        );

        expect(path, equals('user-abc/qr-xyz/variant-123.png'));
        expect(path.startsWith('/'), isFalse,
            reason: 'Path must NOT have a leading slash');
        expect(path.startsWith('order-assets'), isFalse,
            reason: 'Path must NOT include the bucket prefix');
      },
    );

    test(
      'Test 4: If Supabase upload throws StorageException, '
      'upload() rethrows as CartException("png_upload_failed", ...)',
      () async {
        final mockClient = MockSupabaseClient();
        final mockStorage = MockSupabaseStorageClient();
        final mockFileApi = MockStorageFileApi();

        when(() => mockClient.storage).thenReturn(mockStorage);
        when(() => mockStorage.from('order-assets')).thenReturn(mockFileApi);
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenThrow(
          const StorageException('Bucket not found'),
        );

        final ds = OrderAssetsStorageDataSource(mockClient);

        await expectLater(
          () => ds.upload(
            userId: 'user-001',
            qrCodeId: 'qr-001',
            variantId: 'variant-001',
            pngBytes: Uint8List.fromList([1, 2, 3]),
          ),
          throwsA(
            isA<CartException>()
                .having((e) => e.code, 'code', 'png_upload_failed'),
          ),
        );
      },
    );
  });
}
