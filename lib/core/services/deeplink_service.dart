import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

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

  void _handleSignupConfirmation(String link) async {
    final parsed = DeepLinkService.parseSupabaseAuthLink(link);
    if (parsed != null && parsed['token'] != null) {
      debugPrint('📧 Processing signup confirmation with token: ${parsed['token']?.substring(0, 10)}...');
      
      try {
        // Verify the token with Supabase
        if (SupabaseService.isInitialized) {
          final response = await SupabaseService.client.auth.verifyOTP(
            token: parsed['token']!,
            type: OtpType.signup,
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