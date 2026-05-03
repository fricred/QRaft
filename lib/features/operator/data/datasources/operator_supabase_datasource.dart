import 'package:supabase_flutter/supabase_flutter.dart';

/// Low-level Supabase data access for operator order management.
///
/// Security note: uses the standard authenticated client for now.
/// Plan 11-03 will swap to a service_role client for operator routes,
/// which is required to bypass user-scoped RLS on the `orders` table
/// and to execute the `transition_order` RPC (GRANT EXECUTE to service_role only).
class OperatorSupabaseDatasource {
  final SupabaseClient _client;

  const OperatorSupabaseDatasource(this._client);

  /// Fetches all orders in [statuses], joined with first order_item for qr_png_url.
  ///
  /// Sorted by created_at ASC so oldest (highest-priority) orders appear first.
  Future<List<Map<String, dynamic>>> fetchOrdersByStatuses(
    List<String> statuses,
  ) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(qr_png_url)')
        .inFilter('status', statuses)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Calls the `transition_order` RPC.
  ///
  /// Throws [PostgrestException] if the FSM rejects the transition or the
  /// order is not found. The repository wraps this in [OperatorException].
  Future<void> transitionOrder(String orderId, String newStatus) async {
    await _client.rpc(
      'transition_order',
      params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
      },
    );
  }

  /// Fetches a single order with all items for the detail screen.
  Future<Map<String, dynamic>?> fetchOrderDetail(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();
    return response;
  }
}
