import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/order_supabase_data_source.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/repositories/order_repository.dart';

/// Provides the [OrderRepository] implementation backed by Supabase.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    OrderSupabaseDataSource(SupabaseService.client),
  );
});

/// Paginated list of the current user's orders.
///
/// The family parameter is the pagination [offset] (multiples of 20).
/// Pull-to-refresh invalidates offset=0 to reload from the beginning.
final ordersListProvider =
    FutureProvider.family<List<OrderEntity>, int>((ref, offset) {
  return ref
      .read(orderRepositoryProvider)
      .getUserOrders(offset: offset, limit: 20);
});

/// Realtime stream for a single order identified by [orderId].
///
/// Backed by Supabase Realtime postgres_changes — status updates appear
/// within ~1s without manual refresh. Emits null when the row is absent or
/// the RLS policy denies access (T-10-08 mitigation).
final orderDetailStreamProvider =
    StreamProvider.family<OrderEntity?, String>((ref, orderId) {
  return ref.read(orderRepositoryProvider).watchOrder(orderId);
});

/// One-time fetch of line items for order [orderId].
///
/// Items are immutable after order creation so a StreamProvider is unnecessary.
final orderItemsProvider =
    FutureProvider.family<List<OrderItemEntity>, String>((ref, orderId) {
  return ref.read(orderRepositoryProvider).getOrderItems(orderId);
});
