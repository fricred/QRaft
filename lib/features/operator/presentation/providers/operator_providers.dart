export '../../domain/entities/operator_order_row.dart';
export '../../../orders/domain/entities/order_entity.dart'
    show OrderStatus, OrderStatusX;
export '../../../orders/domain/entities/order_item_entity.dart'
    show OrderItemEntity;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/operator_supabase_datasource.dart';
import '../../data/repositories/operator_repository_impl.dart';
import '../../domain/repositories/operator_repository.dart';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

/// Provides the [OperatorSupabaseDatasource] using the service_role client.
///
/// The datasource now uses [SupabaseService.operatorClient] internally, so
/// no client is passed at construction time. Accessing this provider in a
/// consumer build without OPERATOR_SERVICE_ROLE_KEY will throw [StateError].
final operatorDatasourceProvider = Provider<OperatorSupabaseDatasource>((ref) {
  return const OperatorSupabaseDatasource();
});

// ---------------------------------------------------------------------------
// Operator auth provider
// ---------------------------------------------------------------------------

/// Returns true if the currently authenticated user is in `operator_profiles`.
///
/// Calls the `is_operator()` SECURITY DEFINER RPC via the operatorClient.
/// Returns false on any error (including unconfigured operator client or
/// unauthenticated users) — safe default for route guard checks (T-11-10).
final isOperatorProvider = FutureProvider<bool>((ref) async {
  try {
    final result =
        await SupabaseService.operatorClient.rpc('is_operator');
    return result == true;
  } catch (_) {
    return false;
  }
});

/// Provides the [OperatorRepository] implementation.
final operatorRepositoryProvider = Provider<OperatorRepository>((ref) {
  return OperatorRepositoryImpl(ref.read(operatorDatasourceProvider));
});

// ---------------------------------------------------------------------------
// Order queue provider
// ---------------------------------------------------------------------------

/// Fetches operator order queue filtered by [statuses].
///
/// The family parameter is the list of DB status strings to include.
/// Invalidate this provider to force a refresh (called from
/// [transitionOrderStateProvider] after a successful transition).
final operatorOrdersProvider =
    FutureProvider.family<List<OperatorOrderRow>, List<String>>(
        (ref, statuses) async {
  return ref
      .read(operatorRepositoryProvider)
      .fetchOrdersByStatuses(statuses);
});

// ---------------------------------------------------------------------------
// Order detail provider
// ---------------------------------------------------------------------------

/// Fetches the full order record (with items) for operator detail view.
///
/// Returns a raw map with nested `order_items` list — parsed by the screen
/// directly to avoid duplicating entity classes for this single operator screen.
final operatorOrderDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, orderId) async {
  final datasource = ref.read(operatorDatasourceProvider);
  return datasource.fetchOrderDetail(orderId);
});

// ---------------------------------------------------------------------------
// Transition state
// ---------------------------------------------------------------------------

/// State for [TransitionOrderNotifier] — tracks in-flight transition status.
class TransitionOrderState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const TransitionOrderState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  TransitionOrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) =>
      TransitionOrderState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        success: success ?? this.success,
      );
}

/// StateNotifier that tracks async transition state (loading / success / error).
///
/// After a successful transition, invalidates [operatorOrdersProvider] and
/// [operatorOrderDetailProvider] so the UI refreshes automatically.
class TransitionOrderNotifier extends StateNotifier<TransitionOrderState> {
  final OperatorRepository _repository;
  final Ref _ref;

  TransitionOrderNotifier(this._repository, this._ref)
      : super(const TransitionOrderState());

  /// Calls [OperatorRepository.transitionOrder] and updates state accordingly.
  Future<void> performTransition(String orderId, String newStatus) async {
    state = const TransitionOrderState(isLoading: true);
    try {
      await _repository.transitionOrder(orderId, newStatus);
      _invalidateQueues();
      state = const TransitionOrderState(success: true);
    } on OperatorException catch (e) {
      state = TransitionOrderState(errorMessage: e.message);
    } catch (e) {
      state = TransitionOrderState(errorMessage: e.toString());
    }
  }

  /// Resets state back to idle (call after consuming success/error).
  void reset() => state = const TransitionOrderState();

  void _invalidateQueues() {
    _ref.invalidate(operatorOrdersProvider);
    _ref.invalidate(operatorOrderDetailProvider);
  }
}

/// Provider for the transition state notifier.
final transitionOrderStateProvider =
    StateNotifierProvider<TransitionOrderNotifier, TransitionOrderState>((ref) {
  return TransitionOrderNotifier(
    ref.read(operatorRepositoryProvider),
    ref,
  );
});
