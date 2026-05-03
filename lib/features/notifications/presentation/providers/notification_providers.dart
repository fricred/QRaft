import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/core/services/deeplink_service.dart';
import 'package:qraft/features/orders/presentation/pages/order_detail_screen.dart';

// ---------------------------------------------------------------------------
// Navigation helper
// ---------------------------------------------------------------------------

/// Navigates to [OrderDetailScreen] for the given order ID.
///
/// Uses the global [appNavigatorKey] — safe to call from any context
/// (background handlers, FCM callbacks, etc.) without a [BuildContext].
///
/// T-10-09: The screen fetches the order from Supabase with RLS enforcing
/// user_id = auth.uid(), so a forged order_id shows empty/error state — no
/// data leak risk from navigation.
void _navigateToOrder(String orderId) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  nav.push(
    MaterialPageRoute<void>(
      builder: (_) => OrderDetailScreen(orderId: orderId),
    ),
  );
}

// ---------------------------------------------------------------------------
// notificationHandlerProvider
// ---------------------------------------------------------------------------

/// Side-effect provider that wires the FCM background-tap lifecycle callback.
///
/// **Usage:** Read this provider once on app startup (e.g. in
/// [MainScaffold]'s `initState` override) to activate the listener.
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   ref.read(notificationHandlerProvider);
///   checkInitialFcmMessage();
/// }
/// ```
///
/// Background tap (app was in background, user tapped OS notification):
/// [FirebaseMessaging.onMessageOpenedApp] fires when the app resumes from
/// background due to a notification tap.
///
/// Killed-app tap: handled separately by [checkInitialFcmMessage] because
/// [FirebaseMessaging.instance.getInitialMessage] is async and cannot be
/// awaited inside a synchronous Riverpod provider.
final notificationHandlerProvider = Provider<void>((ref) {
  // Background tap: app was backgrounded, user tapped notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final orderId = message.data['order_id'] as String?;
    if (orderId != null) _navigateToOrder(orderId);
  });
});

// ---------------------------------------------------------------------------
// checkInitialFcmMessage
// ---------------------------------------------------------------------------

/// Checks if the app was cold-launched by tapping a killed-app FCM notification.
///
/// Call this once after reading [notificationHandlerProvider] in startup.
/// It is separate from the provider because [getInitialMessage] is async and
/// Riverpod providers must be synchronous.
///
/// Navigation is deferred one frame via [WidgetsBinding.addPostFrameCallback]
/// to ensure the [Navigator] is fully mounted before pushing a route.
Future<void> checkInitialFcmMessage() async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final orderId = initialMessage.data['order_id'] as String?;
    if (orderId != null) {
      // Defer one frame so the Navigator widget is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToOrder(orderId));
    }
  }
}
