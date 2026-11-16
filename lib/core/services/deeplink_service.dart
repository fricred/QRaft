import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../../features/checkout/presentation/pages/payment_result_screen.dart';

/// Global navigator key used by [DeepLinkHandler] to push payment result
/// screens from cold-launch deep links (T-09-12 namespacing).
/// Wire this into [MaterialApp.navigatorKey] in `main.dart`.
final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appNavigatorKey');

// Deeplink service provider
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('qraft/deeplink');
  final StreamController<String> _linkStreamController = StreamController<String>.broadcast();

  // Stream of incoming deeplinks
  Stream<String> get linkStream => _linkStreamController.stream;

  DeepLinkService() {
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // Listen for deeplinks while app is running
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Get initial deeplink when app is launched from link
    _getInitialLink();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'routeUpdated':
        final String link = call.arguments;
        _linkStreamController.add(link);
        break;
    }
  }

  Future<void> _getInitialLink() async {
    try {
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        _linkStreamController.add(initialLink);
      }
    } on PlatformException {
      // Failed to get initial link
    }
  }

  void dispose() {
    _linkStreamController.close();
  }

  // Parse Supabase Auth action links
  static Map<String, String>? parseSupabaseAuthLink(String link) {
    final uri = Uri.parse(link);
    
    // Check if it's our custom QRaft deeplink
    if (uri.scheme == 'qraft' && uri.host == 'auth') {
      if (uri.path == '/verify') {
        return {
          'type': 'signup',
          'action': 'verify',
          'token': uri.queryParameters['token'] ?? '',
        };
      } else if (uri.path == '/reset') {
        return {
          'type': 'recovery',
          'action': 'reset',
          'token': uri.queryParameters['token'] ?? '',
        };
      }
    }
    
    // Check if it's a Supabase auth verification link
    if (uri.path.contains('/auth/v1/verify') && 
        uri.queryParameters.containsKey('token') && 
        uri.queryParameters.containsKey('type')) {
      return {
        'token': uri.queryParameters['token'] ?? '',
        'type': uri.queryParameters['type'] ?? '',
        'redirect_to': uri.queryParameters['redirect_to'] ?? '',
      };
    }

    // Legacy Firebase format support (if still needed)
    if (uri.queryParameters.containsKey('mode') || 
        uri.queryParameters.containsKey('oobCode')) {
      return {
        'mode': uri.queryParameters['mode'] ?? '',
        'oobCode': uri.queryParameters['oobCode'] ?? '',
        'continueUrl': uri.queryParameters['continueUrl'] ?? '',
        'lang': uri.queryParameters['lang'] ?? 'en',
      };
    }

    return null;
  }

  // Legacy method for backwards compatibility
  static Map<String, String>? parseAuthActionLink(String link) {
    return parseSupabaseAuthLink(link);
  }

  // ─── Payment result deep link helpers (T-09-12) ────────────────────────

  /// Returns true when [link] is a Wompi payment-result deep link
  /// (`qraft://payment-result[?...]`).
  ///
  /// Checked BEFORE any auth-related processing to prevent the auth state
  /// machine from accidentally consuming payment-result URLs.
  static bool isPaymentResultLink(String link) {
    return link.startsWith('qraft://payment-result');
  }

  /// Extracts `order_id` and `ref` query parameters from a
  /// `qraft://payment-result` link.
  ///
  /// Returns null when the URL is not a valid payment-result link or when
  /// `order_id` is missing.
  static Map<String, String>? parsePaymentResultLink(String link) {
    if (!isPaymentResultLink(link)) return null;
    final uri = Uri.parse(link);
    final orderId = uri.queryParameters['order_id'];
    if (orderId == null || orderId.isEmpty) return null;
    return {
      'order_id': orderId,
      'ref': uri.queryParameters['ref'] ?? '',
    };
  }

  // Handle password reset deeplink (Supabase format)
  static bool isPasswordResetLink(String link) {
    final parsed = parseSupabaseAuthLink(link);
    return parsed != null && (parsed['type'] == 'recovery' || parsed['mode'] == 'resetPassword');
  }

  // Handle email verification deeplink (Supabase format)
  static bool isEmailVerificationLink(String link) {
    final parsed = parseSupabaseAuthLink(link);
    return parsed != null && (parsed['type'] == 'signup' || parsed['mode'] == 'verifyEmail');
  }

  // Handle email signup confirmation (Supabase specific)
  static bool isSignupConfirmationLink(String link) {
    final parsed = parseSupabaseAuthLink(link);
    return parsed != null && parsed['type'] == 'signup';
  }
}

// Deeplink handler provider
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  return DeepLinkHandler(ref.watch(deepLinkServiceProvider));
});

class DeepLinkHandler {
  final DeepLinkService _deepLinkService;
  StreamSubscription<String>? _linkSubscription;

  DeepLinkHandler(this._deepLinkService) {
    _initHandler();
  }

  void _initHandler() {
    _linkSubscription = _deepLinkService.linkStream.listen((String link) {
      handleDeepLink(link);
    });
  }

  void handleDeepLink(String link) {
    debugPrint('🔗 Received deeplink: $link');

    // ── Payment result deep link (qraft://payment-result) ─────────────────
    // Checked FIRST to prevent the auth state machine from consuming it
    // (T-09-12: deep link collision guard).
    if (DeepLinkService.isPaymentResultLink(link)) {
      _handlePaymentResult(link);
      return;
    }

    // Handle Supabase Auth links
    if (DeepLinkService.isSignupConfirmationLink(link)) {
      _handleSignupConfirmation(link);
    } else if (DeepLinkService.isPasswordResetLink(link)) {
      _handlePasswordReset(link);
    } else if (DeepLinkService.isEmailVerificationLink(link)) {
      _handleEmailVerification(link);
    } else {
      debugPrint('⚠️ Unhandled deeplink: $link');
    }
  }

  /// Handles cold-launch `qraft://payment-result?order_id=...` deep links.
  ///
  /// This covers the PSE flow where the user leaves the app and returns via
  /// the system browser.  The WebView intercept handles the in-app case;
  /// this method handles the rarer cold-launch path.
  void _handlePaymentResult(String link) {
    final params = DeepLinkService.parsePaymentResultLink(link);
    if (params == null) {
      debugPrint('⚠️ Payment result deep link missing order_id: $link');
      return;
    }
    debugPrint('💳 Payment result deep link: order_id=${params['order_id']}');

    appNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentResultScreen(
          orderId: params['order_id']!,
          transactionRef: params['ref'] ?? '',
        ),
      ),
    );
  }

  void _handleSignupConfirmation(String link) async {
    final parsed = DeepLinkService.parseSupabaseAuthLink(link);
    // PKCE/implicit links (code=… or #access_token=…) carry no `token`; supabase_flutter
    // completes those itself. Only legacy token links are verified here.
    if (parsed != null && (parsed['token'] ?? '').isNotEmpty) {
      debugPrint('📧 Processing legacy signup confirmation link');
      
      try {
        // Verify the token with Supabase
        if (SupabaseService.isInitialized) {
          // Legacy links carry the token hash; verifyOTP needs it as tokenHash.
          final response = await SupabaseService.client.auth.verifyOTP(
            tokenHash: parsed['token']!,
            type: OtpType.email,
          );
          
          if (response.user != null) {
            debugPrint('✅ Email verification successful for: ${response.user!.email}');
            // The auth state will update automatically via the auth listener
          } else {
            debugPrint('❌ Email verification failed: No user returned');
          }
        } else {
          debugPrint('❌ Supabase not initialized, cannot verify token');
        }
      } catch (e) {
        debugPrint('❌ Error verifying signup: $e');
      }
    } else {
      debugPrint('❌ Invalid signup confirmation link format');
    }
  }

  void _handlePasswordReset(String link) {
    final parsed = DeepLinkService.parseAuthActionLink(link);
    if (parsed != null) {
      // Log password reset link received with oobCode: ${parsed['oobCode']}
      // TODO: Navigate to password reset screen with oobCode
      // This would typically navigate to a screen where user can enter new password
    }
  }

  void _handleEmailVerification(String link) {
    final parsed = DeepLinkService.parseAuthActionLink(link);
    if (parsed != null) {
      // Log email verification link received with oobCode: ${parsed['oobCode']}
      // TODO: Auto-verify email or navigate to verification confirmation
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}