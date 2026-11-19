/// Wompi payment gateway configuration.
///
/// Switch environments via the WOMPI_ENV dart-define flag (in env.json):
///   "WOMPI_ENV": "test"   → sandbox, no real charges
///   "WOMPI_ENV": "prod"   → production, real charges
///
/// Run with:
///   flutter run --dart-define-from-file=env.json         (test by default)
///   flutter run --dart-define-from-file=env.prod.json    (prod override)
///
/// Public keys are safe in the binary. Private keys/secrets live exclusively in
/// Supabase Edge Function secrets (WOMPI_PRIVATE_KEY_TEST / _PROD), never here.
class WompiPaymentConfig {
  WompiPaymentConfig._();

  static const String _env =
      String.fromEnvironment('WOMPI_ENV', defaultValue: 'test');

  /// True when running in sandbox/test mode — no real charges.
  static bool get isTestMode => _env == 'test';

  /// Wompi public key selected by WOMPI_ENV flag.
  static const String _publicKeyTest =
      String.fromEnvironment('WOMPI_PUBLIC_KEY_TEST', defaultValue: '');

  static const String _publicKeyProd =
      String.fromEnvironment('WOMPI_PUBLIC_KEY_PROD', defaultValue: '');

  static String get publicKey => isTestMode ? _publicKeyTest : _publicKeyProd;

  /// REST API base URL selected by environment.
  static String get apiBase =>
      isTestMode ? sandboxBase : productionBase;

  static const String productionBase = 'https://production.wompi.co/v1';
  static const String sandboxBase = 'https://sandbox.wompi.co/v1';

  /// Deep link that Wompi Web Checkout redirects to on completion.
  static const String checkoutRedirectUrl = 'qraft://payment-result';
}
