import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase data source for order queries.
///
/// Security: all queries are executed with the authenticated client — Supabase
/// RLS policies enforce `user_id = auth.uid()` at the DB level (T-10-05).
/// The [watchOrder] stream returns null if the row is inaccessible (RLS
/// rejects cross-user access — T-10-08).
class OrderSupabaseDataSource {
  final SupabaseClient _client;

  OrderSupabaseDataSource(this._client);

  /// Returns a paginated list of the current user's orders, newest first.
  ///
  /// RLS SELECT policy on `orders` ensures only the authenticated user's rows
  /// are returned — even if [_client.auth.currentUser] somehow returned another
  /// user's ID this could not return foreign rows.
  Future<List<Map<String, dynamic>>> getUserOrders({
    int offset = 0,
    int limit = 20,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final response = await _client
        .from('orders')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Returns a [Stream] backed by Supabase Realtime postgres_changes on the
  /// `orders` table, filtered to [orderId].
  ///
  /// Emits null when the row is absent or RLS denies access.
  ///
  /// The stream emits a new value on any UPDATE to the row — status changes
  /// from server-side RPCs appear within ~1 second (pattern per ARCHITECTURE.md).
  Stream<Map<String, dynamic>?> watchOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }

  /// Fetches order items for [orderId] — one-time query (items are immutable
  /// after order creation).
  ///
  /// RLS on `order_items` uses an EXISTS subquery on `orders` so a cross-user
  /// [orderId] returns an empty list rather than throwing.
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final response = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId);
    return List<Map<String, dynamic>>.from(response as List);
  }
}
