/// Wompi payment gateway configuration constants.
///
/// The public key is safe to embed in the Flutter binary — it is only used
/// to open the Wompi Web Checkout page in a WebView.  It is NEVER used for
/// server-to-server API calls (those use the private key stored exclusively in
/// the Supabase Edge Function environment, per T-09-06).
///
/// The integrity signature is computed server-side in the
/// create-payment-intent Edge Function — never in this binary.
class WompiPaymentConfig {
  WompiPaymentConfig._();

  /// Wompi public key injected at build time via --dart-define-from-file.
  /// Safe to ship in the binary; only authorises opening the checkout page.
  static const String publicKey =
      String.fromEnvironment('WOMPI_PUBLIC_KEY', defaultValue: '');

  /// Wompi production REST API base URL.
  static const String productionBase = 'https://production.wompi.co/v1';

  /// Wompi sandbox REST API base URL.
  static const String sandboxBase = 'https://sandbox.wompi.co/v1';

  /// Deep link that Wompi Web Checkout redirects to on payment completion
  /// (approved, declined, or timed-out).
  /// Must match the value returned by the create-payment-intent Edge Function
  /// and the scheme registered in AndroidManifest.xml / Info.plist.
  static const String checkoutRedirectUrl = 'qraft://payment-result';
}
