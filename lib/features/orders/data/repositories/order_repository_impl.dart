import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_supabase_data_source.dart';

/// Supabase implementation of [OrderRepository].
///
/// Maps raw [Map<String, dynamic>] rows from [OrderSupabaseDataSource] to
/// domain entities using their `fromMap` factories.
class OrderRepositoryImpl implements OrderRepository {
  final OrderSupabaseDataSource _dataSource;

  OrderRepositoryImpl(this._dataSource);

  @override
  Future<List<OrderEntity>> getUserOrders({
    int offset = 0,
    int limit = 20,
  }) async {
    final rows = await _dataSource.getUserOrders(offset: offset, limit: limit);
    return rows.map(OrderEntity.fromMap).toList();
  }

  @override
  Stream<OrderEntity?> watchOrder(String orderId) {
    return _dataSource.watchOrder(orderId).map(
      (row) => row != null ? OrderEntity.fromMap(row) : null,
    );
  }

  @override
  Future<List<OrderItemEntity>> getOrderItems(String orderId) async {
    final rows = await _dataSource.getOrderItems(orderId);
    return rows.map(OrderItemEntity.fromMap).toList();
  }
}
