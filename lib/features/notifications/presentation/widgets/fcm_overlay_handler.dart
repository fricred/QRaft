import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ---------------------------------------------------------------------------
// FcmOverlayHandler
// ---------------------------------------------------------------------------

/// Initializes [FlutterLocalNotificationsPlugin] and shows a local
/// notification banner whenever a FCM message arrives while the app is in the
/// **foreground**.
///
/// iOS and Android handle background/killed notifications at the OS level
/// automatically once FCM is configured; this widget only handles the
/// foreground case where FCM messages would otherwise be silently dropped.
///
/// **Placement:** Wrap the scaffold body once in [MainScaffold]:
/// ```dart
/// body: FcmOverlayHandler(
///   child: IndexedStack(...),
/// ),
/// ```
///
/// The widget renders `child` unmodified — it is purely a side-effect wrapper.
class FcmOverlayHandler extends StatefulWidget {
  final Widget child;
  const FcmOverlayHandler({super.key, required this.child});

  @override
  State<FcmOverlayHandler> createState() => _FcmOverlayHandlerState();
}

class _FcmOverlayHandlerState extends State<FcmOverlayHandler> {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _sub;

  // Android notification channel constants (must match channel created in _init)
  static const _androidChannelId = 'qraft_orders';
  static const _androidChannelName = 'Órdenes QRaft';

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _sub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the local notifications plugin and creates the Android
  /// notification channel required for Android 8+ (API 26+).
  ///
  /// iOS: permission is requested by [FcmService.requestPermission]; we set
  /// all `request*Permission` flags to false here to avoid a second prompt.
  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(initSettings);

    // Android 8+ requires an explicit notification channel to be created
    // before showing notifications with Importance.high.
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: 'Actualizaciones de estado de órdenes QRaft',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ---------------------------------------------------------------------------
  // Foreground message handler
  // ---------------------------------------------------------------------------

  /// Shows a heads-up banner via [FlutterLocalNotificationsPlugin.show]
  /// when a FCM message arrives while the app is in the foreground.
  ///
  /// If the message has no [RemoteNotification] (data-only message), this
  /// is a no-op — the caller handles data-only payloads via Supabase Realtime.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      // Use hashCode as notification ID — unique per message without state.
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
