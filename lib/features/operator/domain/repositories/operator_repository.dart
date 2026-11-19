import '../entities/operator_order_row.dart';

export '../entities/operator_order_row.dart';

/// Abstract contract for operator data access.
///
/// Implementations must bypass user-scoped RLS — this is enforced in
/// plan 11-03 via service_role client. For now, the standard authenticated
/// client is used (operator sees only their accessible rows until 11-03).
abstract class OperatorRepository {
  /// Fetches all orders matching [statuses], sorted by created_at ASC.
  ///
  /// [statuses] is a list of DB enum string values (e.g. ['paid', 'received_by_ops']).
  /// Throws [OperatorException] on Supabase or network errors.
  Future<List<OperatorOrderRow>> fetchOrdersByStatuses(List<String> statuses);

  /// Transitions [orderId] to [newStatus] via the `transition_order` RPC.
  ///
  /// Throws [OperatorException] when the RPC raises a Postgres exception
  /// (invalid FSM transition, not found, etc.).
  Future<void> transitionOrder(String orderId, String newStatus);
}
