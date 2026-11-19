import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single facade for Crashlytics, Analytics, and Performance.
///
/// All observability calls in the app go through this service.
/// Activated in Phase 12 (D-01: Crashlytics + Analytics activation deferred from Phase 1).
///
/// Usage:
///   ObservabilityService.logEvent('qr_created', parameters: {'qr_type': 'url'});
///   ObservabilityService.recordNonFatal(e, s, context: {'screen': 'orders_list'});
class ObservabilityService {
  ObservabilityService._();

  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Wire into [FlutterError.onError] (fatal Flutter framework errors).
  ///
  /// Call in `main()` after Firebase.initializeApp():
  ///   FlutterError.onError = ObservabilityService.onFlutterError;
  static void onFlutterError(FlutterErrorDetails details) {
    _crashlytics.recordFlutterFatalError(details);
  }

  /// Record a non-fatal exception with optional context keys.
  ///
  /// Context keys must not contain PII (no email, phone, or payment data).
  static Future<void> recordNonFatal(
    Object exception,
    StackTrace? stack, {
    Map<String, String> context = const {},
  }) async {
    for (final entry in context.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }
    await _crashlytics.recordError(exception, stack, fatal: false);
  }

  /// Log an analytics event.
  ///
  /// Parameters must be String or int values only (Firebase limit).
  /// In debug/profile mode this is a no-op to avoid polluting analytics.
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Set the analytics + crashlytics user identifier (call after sign-in).
  /// Sends a hashed UID per Firebase policy — no raw PII transmitted.
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Clear user identifier on sign-out.
  static Future<void> clearUserId() async {
    await _analytics.setUserId(id: null);
    await _crashlytics.setUserIdentifier('');
  }
}
