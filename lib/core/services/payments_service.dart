import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/checkout/domain/entities/checkout_session.dart';
import '../../features/checkout/domain/entities/shipping_address.dart';

/// Exception thrown when the create-payment-intent Edge Function returns a
/// non-200 response or the response body cannot be decoded.
///
/// Per T-09-10: only the error code/message is surfaced here — ShippingAddress
/// fields are NEVER included in log messages.
class PaymentServiceException implements Exception {
  const PaymentServiceException(this.message);

  final String message;

  @override
  String toString() => 'PaymentServiceException: $message';
}

/// Flutter-side service that invokes the create-payment-intent Supabase
/// Edge Function and returns a [CheckoutSession].
///
/// The Edge Function owns all secret handling (Wompi private key, integrity
/// secret) and returns a pre-built checkout URL that WompiWebViewScreen opens
/// directly.  This service never touches Wompi's REST API directly.
class PaymentsService {
  const PaymentsService();

  /// Calls the `create-payment-intent` Edge Function and returns a
  /// [CheckoutSession] on success.
  ///
  /// [cartItemIds] — list of cart_item UUIDs to include in the order.
  /// [shipping]    — collected from ShippingScreen; serialized via toJson().
  /// [idempotencyKey] — UUID v4 generated once per checkout attempt; passed
  ///                    as-is to the Edge Function which stores it as
  ///                    payments.transaction_ref (UNIQUE constraint).
  ///
  /// Throws [PaymentServiceException] on any non-200 response.
  Future<CheckoutSession> createPaymentIntent({
    required List<String> cartItemIds,
    required ShippingAddress shipping,
    required String idempotencyKey,
  }) async {
    final FunctionResponse response;
    try {
      response = await Supabase.instance.client.functions.invoke(
        'create-payment-intent',
        body: {
          'cart_item_ids': cartItemIds,
          'shipping': shipping.toJson(),
          'idempotency_key': idempotencyKey,
        },
      );
    } on FunctionException catch (e) {
      // Log only the status code — do not log shipping fields (T-09-10)
      throw PaymentServiceException(
        'Edge Function error: ${e.status} — ${e.reasonPhrase}',
      );
    }

    if (response.status != 200) {
      final errorMsg = (response.data is Map)
          ? (response.data as Map)['error']?.toString() ?? 'Unknown error'
          : response.data?.toString() ?? 'Unknown error';
      throw PaymentServiceException(
        'create-payment-intent returned ${response.status}: $errorMsg',
      );
    }

    if (response.data is! Map<String, dynamic>) {
      throw const PaymentServiceException(
        'create-payment-intent returned unexpected response type',
      );
    }

    return CheckoutSession.fromJson(response.data as Map<String, dynamic>);
  }
}
