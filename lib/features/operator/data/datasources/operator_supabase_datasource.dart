import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Low-level Supabase data access for operator order management.
///
/// Uses [SupabaseService.operatorClient] (service_role key) to bypass
/// user-scoped RLS on `orders`, `order_items`, and `shipments` tables.
/// This allows operators to see ALL orders, not just their own.
///
/// Requires `OPERATOR_SERVICE_ROLE_KEY` to be set via
/// `--dart-define-from-file=env.json` at build time. Accessing this
/// datasource in a consumer build without the key will throw [StateError].
class OperatorSupabaseDatasource {
  SupabaseClient get _client => SupabaseService.operatorClient;

  const OperatorSupabaseDatasource();

  /// Fetches all orders in [statuses], joined with first order_item for qr_png_url.
  ///
  /// Sorted by created_at ASC so oldest (highest-priority) orders appear first.
  /// Uses operatorClient to bypass user-scoped RLS (sees all users' orders).
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
  /// Requires service_role credential (GRANT EXECUTE to service_role only).
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
  ///
  /// Uses operatorClient to bypass user-scoped RLS.
  Future<Map<String, dynamic>?> fetchOrderDetail(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();
    return response;
  }
}
