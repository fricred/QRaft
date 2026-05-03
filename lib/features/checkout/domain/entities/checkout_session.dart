import 'package:equatable/equatable.dart';

/// Returned by the create_payment_intent Edge Function (Plan 09-02).
/// Contains everything WompiWebViewScreen needs to open the payment URL.
class CheckoutSession extends Equatable {
  const CheckoutSession({
    required this.orderId,
    required this.transactionRef,
    required this.wompiCheckoutUrl,
    required this.amountCop,
  });

  final String orderId;
  final String transactionRef;

  /// Full Wompi Web Checkout URL produced by the create_payment_intent
  /// Edge Function (09-02). The WebView loads this URL directly.
  final String wompiCheckoutUrl;

  /// Order total in whole Colombian pesos (COP).
  final int amountCop;

  @override
  List<Object?> get props => [orderId, transactionRef, wompiCheckoutUrl, amountCop];
}

/// Wompi-specific configuration constants shared across checkout screens.
class WompiConfig {
  WompiConfig._();

  /// The redirect URL that Wompi calls when the payment flow completes
  /// (approved, declined, or timed-out).  Matched by a prefix so that
  /// Wompi's appended query params (id, etc.) are tolerated.
  static const String checkoutRedirectUrl = 'qraft://payment-result';
}
