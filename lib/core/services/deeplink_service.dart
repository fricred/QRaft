import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Parse Firebase Auth action links
  static Map<String, String>? parseFirebaseAuthLink(String link) {
    final uri = Uri.parse(link);
    
    // Check if it's a Firebase Auth action link
    if (!uri.queryParameters.containsKey('mode') || 
        !uri.queryParameters.containsKey('oobCode')) {
      return null;
    }

    return {
      'mode': uri.queryParameters['mode'] ?? '',
      'oobCode': uri.queryParameters['oobCode'] ?? '',
      'continueUrl': uri.queryParameters['continueUrl'] ?? '',
      'lang': uri.queryParameters['lang'] ?? 'en',
    };
  }

  // Handle password reset deeplink
  static bool isPasswordResetLink(String link) {
    final parsed = parseFirebaseAuthLink(link);
    return parsed != null && parsed['mode'] == 'resetPassword';
  }

  // Handle email verification deeplink
  static bool isEmailVerificationLink(String link) {
    final parsed = parseFirebaseAuthLink(link);
    return parsed != null && parsed['mode'] == 'verifyEmail';
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
    // Log received deeplink: $link

    // Handle Firebase Auth links
    if (DeepLinkService.isPasswordResetLink(link)) {
      _handlePasswordReset(link);
    } else if (DeepLinkService.isEmailVerificationLink(link)) {
      _handleEmailVerification(link);
    } else {
      // Log unhandled deeplink: $link
    }
  }

  void _handlePasswordReset(String link) {
    final parsed = DeepLinkService.parseFirebaseAuthLink(link);
    if (parsed != null) {
      // Log password reset link received with oobCode: ${parsed['oobCode']}
      // TODO: Navigate to password reset screen with oobCode
      // This would typically navigate to a screen where user can enter new password
    }
  }

  void _handleEmailVerification(String link) {
    final parsed = DeepLinkService.parseFirebaseAuthLink(link);
    if (parsed != null) {
      // Log email verification link received with oobCode: ${parsed['oobCode']}
      // TODO: Auto-verify email or navigate to verification confirmation
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}