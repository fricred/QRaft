import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:qraft/features/operator/data/datasources/operator_supabase_datasource.dart';
import 'package:qraft/features/operator/data/repositories/operator_repository_impl.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockOperatorSupabaseDatasource extends Mock
    implements OperatorSupabaseDatasource {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _orderMap({
  String id = 'order-1',
  String orderNumber = 'ORD-0001',
  String status = 'paid',
  String createdAt = '2026-01-01T00:00:00.000Z',
  int totalCop = 100000,
  String recipientName = 'Juan Perez',
  String city = 'Bogota',
  int itemCount = 1,
  String? qrPngUrl,
}) =>
    {
      'id': id,
      'order_number': orderNumber,
      'status': status,
      'created_at': createdAt,
      'total_cop': totalCop,
      'shipping_recipient_name': recipientName,
      'shipping_city': city,
      'item_count': itemCount,
      'qr_png_url': qrPngUrl,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockOperatorSupabaseDatasource mockDatasource;
  late OperatorRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockOperatorSupabaseDatasource();
    repository = OperatorRepositoryImpl(mockDatasource);
  });

  group('OperatorRepository.fetchOrdersByStatuses', () {
    test('returns mapped OperatorOrderRow list sorted by createdAt ASC', () async {
      // Arrange — datasource returns two rows
      final rawRows = [
        _orderMap(
          id: 'order-1',
          orderNumber: 'ORD-0001',
          status: 'paid',
          // 2 hours ago — stale (paid SLA = 1h)
          createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          totalCop: 100000,
          recipientName: 'Juan',
          city: 'Bogota',
          itemCount: 1,
        ),
        _orderMap(
          id: 'order-2',
          orderNumber: 'ORD-0002',
          status: 'paid',
          // 10 minutes ago — not stale
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          totalCop: 200000,
          recipientName: 'Maria',
          city: 'Medellin',
          itemCount: 2,
        ),
      ];
      when(() => mockDatasource.fetchOrdersByStatuses(['paid']))
          .thenAnswer((_) async => rawRows);

      // Act
      final result = await repository.fetchOrdersByStatuses(['paid']);

      // Assert — list returned with correct mapping
      expect(result, hasLength(2));
      expect(result.first.id, equals('order-1'));
      expect(result.first.orderNumber, equals('ORD-0001'));
      expect(result.first.totalCop, equals(100000));
      expect(result.first.shippingCity, equals('Bogota'));
    });

    test('marks order as stale when paid and older than 1 hour', () async {
      // A "paid" order created 90 minutes ago should be flagged stale.
      final rawRows = [
        _orderMap(
          status: 'paid',
          createdAt: DateTime.now()
              .subtract(const Duration(hours: 1, minutes: 30))
              .toIso8601String(),
        ),
      ];
      when(() => mockDatasource.fetchOrdersByStatuses(['paid']))
          .thenAnswer((_) async => rawRows);

      final result = await repository.fetchOrdersByStatuses(['paid']);

      expect(result.first.isStale, isTrue,
          reason: 'paid order >1 hour old should be stale');
    });

    test('does NOT mark order as stale when paid and within SLA', () async {
      // A "paid" order created 30 minutes ago should NOT be flagged stale.
      final rawRows = [
        _orderMap(
          status: 'paid',
          createdAt: DateTime.now()
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
        ),
      ];
      when(() => mockDatasource.fetchOrdersByStatuses(['paid']))
          .thenAnswer((_) async => rawRows);

      final result = await repository.fetchOrdersByStatuses(['paid']);

      expect(result.first.isStale, isFalse,
          reason: 'paid order <1 hour old should not be stale');
    });

    test('marks received_by_ops order stale when >4 hours', () async {
      final rawRows = [
        _orderMap(
          status: 'received_by_ops',
          createdAt: DateTime.now()
              .subtract(const Duration(hours: 5))
              .toIso8601String(),
        ),
      ];
      when(() => mockDatasource.fetchOrdersByStatuses(['received_by_ops']))
          .thenAnswer((_) async => rawRows);

      final result = await repository.fetchOrdersByStatuses(['received_by_ops']);

      expect(result.first.isStale, isTrue);
    });

    test('marks engraving order stale when >24 hours', () async {
      final rawRows = [
        _orderMap(
          status: 'engraving',
          createdAt: DateTime.now()
              .subtract(const Duration(hours: 25))
              .toIso8601String(),
        ),
      ];
      when(() => mockDatasource.fetchOrdersByStatuses(['engraving']))
          .thenAnswer((_) async => rawRows);

      final result = await repository.fetchOrdersByStatuses(['engraving']);

      expect(result.first.isStale, isTrue);
    });

    test('marks engraving_done order stale when >4 hours', () async {
      final rawRows = [
        _orderMap(
          status: 'engraving_done',
          createdAt: DateTime.now()
              .subtract(const Duration(hours: 5))
              .toIso8601String(),
        ),
      ];
      when(() => mockDatasource.fetchOrdersByStatuses(['engraving_done']))
          .thenAnswer((_) async => rawRows);

      final result = await repository.fetchOrdersByStatuses(['engraving_done']);

      expect(result.first.isStale, isTrue);
    });
  });

  group('OperatorRepository.transitionOrder', () {
    test('completes without error when datasource succeeds', () async {
      when(() => mockDatasource.transitionOrder('order-1', 'received_by_ops'))
          .thenAnswer((_) async {});

      await expectLater(
        repository.transitionOrder('order-1', 'received_by_ops'),
        completes,
      );
    });

    test('wraps PostgrestException as OperatorException', () async {
      when(() => mockDatasource.transitionOrder('order-1', 'cancelled'))
          .thenThrow(
        PostgrestException(
          message: 'Invalid FSM transition',
          code: 'P0001',
        ),
      );

      await expectLater(
        repository.transitionOrder('order-1', 'cancelled'),
        throwsA(isA<OperatorException>()),
      );
    });

    test('wraps generic Exception as OperatorException', () async {
      when(() => mockDatasource.transitionOrder('order-1', 'shipped'))
          .thenThrow(Exception('network error'));

      await expectLater(
        repository.transitionOrder('order-1', 'shipped'),
        throwsA(isA<OperatorException>()),
      );
    });
  });
}
