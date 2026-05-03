import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/orders/domain/entities/order_entity.dart';

void main() {
  group('OrderStatus.fromString', () {
    test('parses all 11 DB strings to correct enum values', () {
      const expectedMappings = {
        'payment_pending': OrderStatus.paymentPending,
        'payment_failed': OrderStatus.paymentFailed,
        'paid': OrderStatus.paid,
        'received_by_ops': OrderStatus.receivedByOps,
        'engraving': OrderStatus.engraving,
        'engraving_failed': OrderStatus.engravingFailed,
        'engraving_done': OrderStatus.engravingDone,
        'shipped': OrderStatus.shipped,
        'delivered': OrderStatus.delivered,
        'cancelled': OrderStatus.cancelled,
        'refunded': OrderStatus.refunded,
      };

      for (final entry in expectedMappings.entries) {
        expect(
          OrderStatusX.fromString(entry.key),
          equals(entry.value),
          reason: 'DB string "${entry.key}" should parse to ${entry.value}',
        );
      }
    });

    test('throws ArgumentError for unknown status string', () {
      expect(
        () => OrderStatusX.fromString('unknown_status'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => OrderStatusX.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => OrderStatusX.fromString('PAID'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('OrderStatus.isFinal', () {
    test('isFinal is true only for cancelled and refunded', () {
      expect(OrderStatus.cancelled.isFinal, isTrue);
      expect(OrderStatus.refunded.isFinal, isTrue);
    });

    test('isFinal is false for all non-terminal statuses', () {
      const nonFinalStatuses = [
        OrderStatus.paymentPending,
        OrderStatus.paymentFailed,
        OrderStatus.paid,
        OrderStatus.receivedByOps,
        OrderStatus.engraving,
        OrderStatus.engravingFailed,
        OrderStatus.engravingDone,
        OrderStatus.shipped,
        OrderStatus.delivered,
      ];
      for (final status in nonFinalStatuses) {
        expect(status.isFinal, isFalse, reason: '$status should not be final');
      }
    });
  });

  group('OrderStatus.stepIndex', () {
    test('stepIndex is 0 for paymentPending', () {
      expect(OrderStatus.paymentPending.stepIndex, equals(0));
    });

    test('stepIndex is 10 for refunded (last value)', () {
      expect(OrderStatus.refunded.stepIndex, equals(10));
    });

    test('stepIndex is monotonically increasing across all values', () {
      final values = OrderStatus.values;
      for (int i = 0; i < values.length - 1; i++) {
        expect(
          values[i].stepIndex < values[i + 1].stepIndex,
          isTrue,
          reason:
              '${values[i]}.stepIndex (${values[i].stepIndex}) should be < '
              '${values[i + 1]}.stepIndex (${values[i + 1].stepIndex})',
        );
      }
    });
  });

  group('OrderStatus.label', () {
    test('all statuses have non-empty Spanish labels', () {
      for (final status in OrderStatus.values) {
        expect(status.label.isNotEmpty, isTrue,
            reason: '$status should have a non-empty label');
      }
    });
  });

  group('OrderEntity.fromMap', () {
    test('correctly parses all required fields', () {
      final map = {
        'id': 'order-uuid-1',
        'order_number': 'QRA-2026-000001',
        'status': 'paid',
        'subtotal_cop': 89000,
        'tax_cop': 16910,
        'shipping_cop': 5000,
        'total_cop': 110910,
        'shipping_recipient_name': 'Juan Perez',
        'shipping_phone': '3001234567',
        'shipping_department': 'Cundinamarca',
        'shipping_city': 'Bogota',
        'shipping_address': 'Calle 100 # 20-30',
        'shipping_notes': null,
        'created_at': '2026-05-01T10:00:00.000Z',
        'paid_at': '2026-05-01T10:05:00.000Z',
        'received_at': null,
        'engraving_started_at': null,
        'engraving_done_at': null,
        'shipped_at': null,
        'delivered_at': null,
        'cancelled_at': null,
      };

      final entity = OrderEntity.fromMap(map);

      expect(entity.id, equals('order-uuid-1'));
      expect(entity.orderNumber, equals('QRA-2026-000001'));
      expect(entity.status, equals(OrderStatus.paid));
      expect(entity.subtotalCop, equals(89000));
      expect(entity.taxCop, equals(16910));
      expect(entity.shippingCop, equals(5000));
      expect(entity.totalCop, equals(110910));
      expect(entity.shippingRecipientName, equals('Juan Perez'));
      expect(entity.shippingNotes, isNull);
      expect(entity.paidAt, isNotNull);
      expect(entity.receivedAt, isNull);
    });

    test('nullable date fields parse as null when absent', () {
      final map = {
        'id': 'order-uuid-2',
        'order_number': 'QRA-2026-000002',
        'status': 'payment_pending',
        'subtotal_cop': 50000,
        'tax_cop': 9500,
        'shipping_cop': 5000,
        'total_cop': 64500,
        'shipping_recipient_name': 'Maria',
        'shipping_phone': '3109876543',
        'shipping_department': 'Antioquia',
        'shipping_city': 'Medellin',
        'shipping_address': 'Carrera 70 # 45-10',
        'shipping_notes': null,
        'created_at': '2026-05-01T08:00:00.000Z',
        'paid_at': null,
        'received_at': null,
        'engraving_started_at': null,
        'engraving_done_at': null,
        'shipped_at': null,
        'delivered_at': null,
        'cancelled_at': null,
      };

      final entity = OrderEntity.fromMap(map);
      expect(entity.paidAt, isNull);
      expect(entity.receivedAt, isNull);
      expect(entity.engravingStartedAt, isNull);
    });
  });
}
