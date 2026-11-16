import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/cart/domain/entities/cart_item_entity.dart';
import 'package:qraft/features/cart/domain/entities/cart_totals_entity.dart';
import 'package:qraft/features/cart/data/models/cart_item_model.dart';
import 'package:qraft/features/qr_generator/domain/entities/qr_code_entity.dart';
import 'package:qraft/features/qr_generator/domain/value_objects/qr_profile.dart';

void main() {
  group('CartItemEntity', () {
    final sampleSnapshot = <String, dynamic>{
      'foreground_color': 0xFF000000,
      'background_color': 0xFFFFFFFF,
      'has_logo': false,
      'quantity': 1,
    };

    final sampleAddedAt = DateTime.utc(2026, 5, 4, 10, 0, 0);

    final sampleJson = <String, dynamic>{
      'id': 'item-uuid-001',
      'user_id': 'user-uuid-001',
      'product_variant_id': 'variant-uuid-001',
      'qr_code_id': 'qr-uuid-001',
      'customization_snapshot': sampleSnapshot,
      'png_storage_url': null,
      'quantity': 2,
      'added_at': '2026-05-04T10:00:00.000Z',
    };

    // Test 1: CartItemEntity.fromJson round-trips all fields
    test('fromJson round-trips all fields including customizationSnapshot', () {
      final entity = CartItemEntity.fromJson(sampleJson);

      expect(entity.id, equals('item-uuid-001'));
      expect(entity.userId, equals('user-uuid-001'));
      expect(entity.productVariantId, equals('variant-uuid-001'));
      expect(entity.qrCodeId, equals('qr-uuid-001'));
      expect(entity.customizationSnapshot, equals(sampleSnapshot));
      expect(entity.pngStorageUrl, isNull);
      expect(entity.quantity, equals(2));
      // Timestamps are read back in local time; compare the instant, not the zone.
      expect(entity.addedAt.isAtSameMomentAs(sampleAddedAt), isTrue);

      // Round-trip: toJson → fromJson should produce equal entity
      final roundTripped = CartItemEntity.fromJson(entity.toJson());
      expect(roundTripped, equals(entity));
    });

    test('toJson produces snake_case keys matching Supabase schema', () {
      final entity = CartItemEntity(
        id: 'item-1',
        userId: 'user-1',
        productVariantId: 'variant-1',
        qrCodeId: 'qr-1',
        customizationSnapshot: sampleSnapshot,
        pngStorageUrl: 'https://example.com/qr.png',
        quantity: 3,
        addedAt: sampleAddedAt,
      );

      final json = entity.toJson();
      expect(json['id'], equals('item-1'));
      expect(json['user_id'], equals('user-1'));
      expect(json['product_variant_id'], equals('variant-1'));
      expect(json['qr_code_id'], equals('qr-1'));
      expect(json['png_storage_url'], equals('https://example.com/qr.png'));
      expect(json['quantity'], equals(3));
    });
  });

  group('CartItemModel', () {
    // Test 2: CartItemModel.fromSupabaseRow parses Supabase row correctly
    test(
        'fromSupabaseRow parses Supabase snake_case row into CartItemEntity correctly',
        () {
      final supabaseRow = <String, dynamic>{
        'id': 'item-uuid-002',
        'user_id': 'user-uuid-002',
        'product_variant_id': 'variant-uuid-002',
        'qr_code_id': 'qr-uuid-002',
        'customization_snapshot': <String, dynamic>{
          'foreground_color': 0xFF112233,
          'has_logo': true,
        },
        'png_storage_url': 'https://cdn.example.com/qr.png',
        'quantity': 1,
        'added_at': '2026-05-04T12:00:00.000Z',
      };

      final model = CartItemModel.fromSupabaseRow(supabaseRow);

      // Should be a CartItemEntity (via inheritance)
      expect(model, isA<CartItemEntity>());
      expect(model.id, equals('item-uuid-002'));
      expect(model.userId, equals('user-uuid-002'));
      expect(model.productVariantId, equals('variant-uuid-002'));
      expect(model.qrCodeId, equals('qr-uuid-002'));
      expect(
          model.customizationSnapshot['foreground_color'], equals(0xFF112233));
      expect(model.customizationSnapshot['has_logo'], isTrue);
      expect(model.pngStorageUrl, equals('https://cdn.example.com/qr.png'));
      expect(model.quantity, equals(1));
    });
  });

  group('CartTotalsEntity', () {
    // Test 3: CartTotalsEntity arithmetic
    test(
        'subtotalCop=100000, ivaCop=19000, envioCop=15000 → totalCop=134000',
        () {
      const totals = CartTotalsEntity(
        subtotalCop: 100000,
        ivaCop: 19000,
        envioCop: 15000,
        totalCop: 134000,
      );

      expect(totals.totalCop,
          equals(totals.subtotalCop + totals.ivaCop + totals.envioCop));
      expect(totals.totalCop, equals(134000));
    });

    test('CartTotalsEntity.zero has 15000 envio and 15000 total', () {
      const zero = CartTotalsEntity.zero;
      expect(zero.subtotalCop, equals(0));
      expect(zero.ivaCop, equals(0));
      expect(zero.envioCop, equals(15000));
      expect(zero.totalCop, equals(15000));
    });

    test('fromRpcRow deserializes all fields from snake_case map', () {
      final row = <String, dynamic>{
        'subtotal_cop': 89000,
        'iva_cop': 16910,
        'envio_cop': 15000,
        'total_cop': 120910,
      };

      final totals = CartTotalsEntity.fromRpcRow(row);
      expect(totals.subtotalCop, equals(89000));
      expect(totals.ivaCop, equals(16910));
      expect(totals.envioCop, equals(15000));
      expect(totals.totalCop, equals(120910));
    });
  });

  group('QRCustomization serialization', () {
    // Test 4: QRCustomization.toJson/fromJson round-trip
    test('toJson serializes all fields; fromJson deserializes back to equal value',
        () {
      const original = QRCustomization(
        foregroundColor: 0xFF123456,
        backgroundColor: 0xFFABCDEF,
        eyeColor: 0xFF000000,
        size: 300.0,
        errorCorrectionLevel: 3,
        logoPath: '/path/to/logo.png',
        hasLogo: true,
        eyeShape: 1,
        dataShape: 1,
        roundedCorners: true,
        logoSize: 60.0,
        hasGradient: true,
        gradientStart: 0xFF00FF88,
        gradientEnd: 0xFF00CC6A,
        gradientType: GradientType.linear,
        modulePreset: 3,
        eyePreset: 2,
        profile: 1,
        frameText: 'Scan me!',
        logoCoverage: 0.15,
      );

      final json = original.toJson();

      // Verify key fields are present in JSON
      expect(json['foreground_color'], equals(0xFF123456));
      expect(json['has_logo'], isTrue);
      expect(json['gradient_type'], equals('linear'));
      expect(json['frame_text'], equals('Scan me!'));
      expect(json['logo_coverage'], equals(0.15));

      // Deserialize and verify equality via Equatable props
      final restored = QRCustomization.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson falls back to GradientType.solid for unknown gradient_type',
        () {
      final json = <String, dynamic>{
        'gradient_type': 'unknown_future_type',
      };

      final c = QRCustomization.fromJson(json);
      expect(c.gradientType, equals(GradientType.solid));
    });

    test('fromJson handles null/missing fields with defaults', () {
      final json = <String, dynamic>{};
      final c = QRCustomization.fromJson(json);

      expect(c.foregroundColor, equals(0xFF000000));
      expect(c.backgroundColor, equals(0xFFFFFFFF));
      expect(c.hasLogo, isFalse);
      expect(c.gradientType, equals(GradientType.solid));
      expect(c.logoCoverage, equals(0.0));
    });
  });
}
