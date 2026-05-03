import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/core/services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Background message handler
//
// MUST be a top-level free function (not a method or closure).
// The @pragma annotation keeps the entry point alive in AOT-compiled builds.
//
// RULE: No UI calls (no BuildContext, no Navigator, no showDialog) in this
// function.  iOS kills the UI isolate for background/terminated messages.
// Phase 10 plan 03 adds the foreground overlay via flutter_local_notifications.
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Log data payload for debugging — token value never logged (T-10-03).
  debugPrint('FCM background message received: ${message.messageId}');
  // Phase 10 plan 03 will handle local notification display in foreground.
}

// ---------------------------------------------------------------------------
// FcmService
// ---------------------------------------------------------------------------

/// Activates Firebase Cloud Messaging, requests OS notification permission,
/// registers the FCM token in Supabase `user_fcm_tokens`, and listens for
/// automatic token rotations.
///
/// Production usage:
/// ```dart
/// // Call once after authentication is confirmed:
/// await FcmService.instance.initialize();
/// ```
///
/// Testing:
/// ```dart
/// final svc = FcmService.testInstance(
///   messaging: mockMessaging,
///   currentUserIdResolver: () => 'test-uid',
/// );
/// ```
class FcmService {
  final FirebaseMessaging _messaging;

  /// Injected resolver for the current authenticated user ID.
  /// In production this reads from [SupabaseService]; in tests it can be
  /// substituted with a stub.
  final String? Function() _currentUserIdResolver;

  // ---------------------------------------------------------------------------
  // Constructors
  // ---------------------------------------------------------------------------

  /// Private constructor used by both the singleton and test factory.
  FcmService._({
    required FirebaseMessaging messaging,
    required String? Function() currentUserIdResolver,
  })  : _messaging = messaging,
        _currentUserIdResolver = currentUserIdResolver;

  /// Production singleton — wired to real Firebase and Supabase.
  static final FcmService instance = FcmService._(
    messaging: FirebaseMessaging.instance,
    currentUserIdResolver: () =>
        SupabaseService.isInitialized
            ? SupabaseService.client.auth.currentUser?.id
            : null,
  );

  /// Test factory — allows injecting a mock [FirebaseMessaging] and a stub
  /// user-ID resolver so tests never touch real Firebase or Supabase.
  factory FcmService.testInstance({
    required FirebaseMessaging messaging,
    String? Function()? currentUserIdResolver,
  }) {
    return FcmService._(
      messaging: messaging,
      currentUserIdResolver: currentUserIdResolver ?? () => null,
    );
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests OS notification permission.
  ///
  /// - iOS: shows a system dialog on first call.
  /// - Android ≥13: shows a system dialog on first call.
  ///
  /// Returns `true` for [AuthorizationStatus.authorized] or
  /// [AuthorizationStatus.provisional]; `false` otherwise.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint(
      'FCM permission status: ${settings.authorizationStatus} — granted: $granted',
    );
    return granted;
  }

  /// Registers this device's FCM token in Supabase `user_fcm_tokens`.
  ///
  /// Guards against unauthenticated calls — returns immediately if no user is
  /// signed in.  Listens for token rotations and re-registers automatically.
  Future<void> initialize() async {
    final userId = _currentUserIdResolver();
    if (userId == null) {
      debugPrint('FCM: no authenticated user — skipping token registration');
      return;
    }

    await requestPermission();

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Re-register whenever Firebase rotates the token.
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed — re-registering');
      await _registerToken(newToken);
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Upserts the FCM token in Supabase `user_fcm_tokens`.
  ///
  /// Uses ON CONFLICT (user_id, token) to update `last_seen_at` without
  /// creating duplicate rows (T-10-04 DoS guard).
  ///
  /// Never logs the token value (T-10-03 information-disclosure mitigaton).
  Future<void> _registerToken(String token) async {
    final userId = _currentUserIdResolver();
    if (userId == null) {
      debugPrint('FCM: _registerToken called with no authenticated user — skipping');
      return;
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    debugPrint('FCM: registering token for platform=$platform');

    await SupabaseService.client.from('user_fcm_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,token',
    );

    debugPrint('FCM: token registered successfully');
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the production [FcmService] singleton.
///
/// In [_AuthWrapperState] (main.dart) use:
/// ```dart
/// ref.read(fcmServiceProvider).initialize();
/// ```
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService.instance);
