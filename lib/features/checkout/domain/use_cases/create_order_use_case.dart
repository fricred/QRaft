import 'package:uuid/uuid.dart';
import '../../../../core/services/payments_service.dart';
import '../entities/checkout_session.dart';
import '../entities/shipping_address.dart';

/// Domain use case that drives the checkout flow.
///
/// Generates a UUID v4 idempotency key once per call and delegates to
/// [PaymentsService.createPaymentIntent], which invokes the
/// create-payment-intent Edge Function.
///
/// The idempotency key becomes the Wompi transaction reference and is stored
/// as payments.transaction_ref (UNIQUE) in the database.  If the user retries
/// the checkout with the same [CreateOrderUseCase] instance the key will
/// differ (a new UUID is generated per call) — idempotency protection is at
/// the infrastructure level; the use case does not cache the key.
class CreateOrderUseCase {
  const CreateOrderUseCase(this._payments);

  final PaymentsService _payments;

  Future<CheckoutSession> call({
    required List<String> cartItemIds,
    required ShippingAddress shipping,
  }) async {
    final idempotencyKey = const Uuid().v4();
    return _payments.createPaymentIntent(
      cartItemIds: cartItemIds,
      shipping: shipping,
      idempotencyKey: idempotencyKey,
    );
  }
}
