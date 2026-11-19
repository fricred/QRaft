import '../../../../core/services/payments_service.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/shipping_address.dart';
import '../../domain/use_cases/create_order_use_case.dart';

/// Repository that exposes checkout operations to the presentation layer.
///
/// Thin wrapper over [CreateOrderUseCase] following the repository pattern
/// established in Phase 4.  Keeps the presentation layer decoupled from
/// [PaymentsService] directly.
class CheckoutRepositoryImpl {
  CheckoutRepositoryImpl({PaymentsService? paymentsService})
      : _useCase = CreateOrderUseCase(
          paymentsService ?? const PaymentsService(),
        );

  final CreateOrderUseCase _useCase;

  /// Atomically creates an order and returns a [CheckoutSession] containing
  /// the Wompi Web Checkout URL.
  Future<CheckoutSession> createOrder({
    required List<String> cartItemIds,
    required ShippingAddress shipping,
  }) =>
      _useCase(cartItemIds: cartItemIds, shipping: shipping);
}
