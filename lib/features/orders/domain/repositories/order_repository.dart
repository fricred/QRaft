import '../entities/order_entity.dart';
import '../entities/order_item_entity.dart';

/// Abstract repository for order data access.
///
/// Implementations must:
/// - Enforce user ownership (RLS handles this at DB level, but the impl must
///   pass the correct authenticated client).
/// - Return an empty list (not throw) when the user has no orders.
abstract class OrderRepository {
  /// Returns a paginated, most-recent-first list of the current user's orders.
  ///
  /// [offset] and [limit] follow offset-based pagination (page size = 20).
  Future<List<OrderEntity>> getUserOrders({int offset = 0, int limit = 20});

  /// Returns a [Stream] that emits the latest state of order [orderId].
  ///
  /// Backed by Supabase Realtime `postgres_changes` so status updates appear
  /// in the UI in <2 seconds without a manual refresh.
  ///
  /// Emits `null` if the row does not exist or the user has no RLS access.
  Stream<OrderEntity?> watchOrder(String orderId);

  /// Fetches the line items for order [orderId].
  ///
  /// This is a one-time fetch (not realtime) — items never change after order
  /// creation.
  Future<List<OrderItemEntity>> getOrderItems(String orderId);
}
