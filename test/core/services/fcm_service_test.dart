import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qraft/core/services/fcm_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

// ---------------------------------------------------------------------------
// FcmService tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
  });

  group('backgroundMessageHandler', () {
    test('is a top-level function (compile-time check)', () {
      // If the symbol compiles, the top-level @pragma function exists.
      // We cannot call it in unit tests (it requires Firebase background
      // isolate), so we just verify the type.
      expect(firebaseBackgroundMessageHandler, isA<Function>());
    });
  });

  group('FcmService.requestPermission', () {
    test('returns true when FirebaseMessaging grants authorizationStatus.authorized', () async {
      when(
        () => mockMessaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
          announcement: any(named: 'announcement'),
          carPlay: any(named: 'carPlay'),
          criticalAlert: any(named: 'criticalAlert'),
        ),
      ).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.notSupported,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.notSupported,
          providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        ),
      );

      final service = FcmService.testInstance(messaging: mockMessaging);
      final result = await service.requestPermission();

      expect(result, isTrue);
    });

    test('returns false when FirebaseMessaging returns authorizationStatus.denied', () async {
      when(
        () => mockMessaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
          announcement: any(named: 'announcement'),
          carPlay: any(named: 'carPlay'),
          criticalAlert: any(named: 'criticalAlert'),
        ),
      ).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.denied,
          alert: AppleNotificationSetting.disabled,
          announcement: AppleNotificationSetting.notSupported,
          badge: AppleNotificationSetting.disabled,
          carPlay: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.disabled,
          notificationCenter: AppleNotificationSetting.disabled,
          showPreviews: AppleShowPreviewSetting.never,
          sound: AppleNotificationSetting.disabled,
          timeSensitive: AppleNotificationSetting.notSupported,
          providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        ),
      );

      final service = FcmService.testInstance(messaging: mockMessaging);
      final result = await service.requestPermission();

      expect(result, isFalse);
    });

    test('returns true when FirebaseMessaging returns authorizationStatus.provisional', () async {
      when(
        () => mockMessaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
          announcement: any(named: 'announcement'),
          carPlay: any(named: 'carPlay'),
          criticalAlert: any(named: 'criticalAlert'),
        ),
      ).thenAnswer(
        (_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.provisional,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.notSupported,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.notSupported,
          providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        ),
      );

      final service = FcmService.testInstance(messaging: mockMessaging);
      final result = await service.requestPermission();

      // provisional = soft grant on iOS; we treat it as granted
      expect(result, isTrue);
    });
  });

  group('FcmService.initialize', () {
    test('no-ops (does not throw) when currentUser is null', () async {
      // When no user is signed in, initialize() must return without error.
      // We use a test instance with a no-user resolver.
      final service = FcmService.testInstance(
        messaging: mockMessaging,
        currentUserIdResolver: () => null,
      );

      // Should not throw
      await expectLater(service.initialize(), completes);

      // Verify FirebaseMessaging was NOT called for token retrieval when
      // no user is present (no-op guard).
      verifyNever(() => mockMessaging.getToken());
    });
  });
}
