import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/core/services/deeplink_service.dart';

void main() {
  group('DeepLinkService Tests', () {
    late DeepLinkService deepLinkService;
    late List<MethodCall> methodCalls;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = <MethodCall>[];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'getInitialLink':
              return null; // No initial link by default
            default:
              return null;
          }
        },
      );

      deepLinkService = DeepLinkService();
    });

    tearDown(() {
      deepLinkService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        null,
      );
    });

    test('initializes and calls getInitialLink', () async {
      // Allow some time for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      expect(methodCalls, isNotEmpty);
      expect(methodCalls.any((call) => call.method == 'getInitialLink'), isTrue);
    });

    test('linkStream is available and ready for links', () async {
      // Test that the linkStream is properly initialized and can be listened to
      expect(deepLinkService.linkStream, isNotNull);
      expect(deepLinkService.linkStream, isA<Stream<String>>());
      
      // Test that we can subscribe to the stream without errors
      bool canSubscribe = false;
      try {
        final subscription = deepLinkService.linkStream.listen((_) {});
        canSubscribe = true;
        await subscription.cancel();
      } catch (e) {
        canSubscribe = false;
      }
      
      expect(canSubscribe, isTrue);
    });

    test('handles initial link when provided', () async {
      // Arrange
      const initialLink = 'qraft://auth/verify-email?mode=verifyEmail&oobCode=abc123';
      List<String> receivedLinks = [];
      
      // Mock method channel to return initial link
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'getInitialLink':
              return initialLink;
            default:
              return null;
          }
        },
      );

      // Act
      final newService = DeepLinkService();
      
      // Listen to the stream
      final subscription = newService.linkStream.listen((link) {
        receivedLinks.add(link);
      });
      
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Assert
      expect(receivedLinks, contains(initialLink));
      
      // Clean up
      await subscription.cancel();
      newService.dispose();
    });

    test('handles platform exceptions gracefully', () async {
      // Mock method channel to throw exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Platform not available',
          );
        },
      );

      // Should not throw when creating service
      expect(() => DeepLinkService(), returnsNormally);
    });
  });

  group('DeepLinkService Static Methods Tests', () {
    group('parseFirebaseAuthLink', () {
      test('parses valid Firebase auth link correctly', () {
        const validLink = 'https://qraft.gothcorp.io/auth/action?mode=resetPassword&oobCode=test123&continueUrl=https://example.com&lang=es';
        
        final result = DeepLinkService.parseFirebaseAuthLink(validLink);
        
        expect(result, isNotNull);
        expect(result!['mode'], equals('resetPassword'));
        expect(result['oobCode'], equals('test123'));
        expect(result['continueUrl'], equals('https://example.com'));
        expect(result['lang'], equals('es'));
      });

      test('returns null for invalid Firebase auth link', () {
        const invalidLink = 'https://example.com/some/path';
        
        final result = DeepLinkService.parseFirebaseAuthLink(invalidLink);
        
        expect(result, isNull);
      });

      test('returns null for link missing required parameters', () {
        const incompleteLink = 'https://qraft.gothcorp.io/auth/action?mode=resetPassword';
        
        final result = DeepLinkService.parseFirebaseAuthLink(incompleteLink);
        
        expect(result, isNull);
      });

      test('handles missing optional parameters', () {
        const linkWithoutOptionals = 'https://qraft.gothcorp.io/auth/action?mode=verifyEmail&oobCode=abc123';
        
        final result = DeepLinkService.parseFirebaseAuthLink(linkWithoutOptionals);
        
        expect(result, isNotNull);
        expect(result!['mode'], equals('verifyEmail'));
        expect(result['oobCode'], equals('abc123'));
        expect(result['continueUrl'], equals(''));
        expect(result['lang'], equals('en')); // Default value
      });
    });

    group('isPasswordResetLink', () {
      test('returns true for valid password reset link', () {
        const resetLink = 'https://qraft.gothcorp.io/auth/action?mode=resetPassword&oobCode=test123';
        
        final result = DeepLinkService.isPasswordResetLink(resetLink);
        
        expect(result, isTrue);
      });

      test('returns false for email verification link', () {
        const verifyLink = 'https://qraft.gothcorp.io/auth/action?mode=verifyEmail&oobCode=test123';
        
        final result = DeepLinkService.isPasswordResetLink(verifyLink);
        
        expect(result, isFalse);
      });

      test('returns false for invalid link', () {
        const invalidLink = 'https://example.com/some/path';
        
        final result = DeepLinkService.isPasswordResetLink(invalidLink);
        
        expect(result, isFalse);
      });
    });

    group('isEmailVerificationLink', () {
      test('returns true for valid email verification link', () {
        const verifyLink = 'https://qraft.gothcorp.io/auth/action?mode=verifyEmail&oobCode=test123';
        
        final result = DeepLinkService.isEmailVerificationLink(verifyLink);
        
        expect(result, isTrue);
      });

      test('returns false for password reset link', () {
        const resetLink = 'https://qraft.gothcorp.io/auth/action?mode=resetPassword&oobCode=test123';
        
        final result = DeepLinkService.isEmailVerificationLink(resetLink);
        
        expect(result, isFalse);
      });

      test('returns false for invalid link', () {
        const invalidLink = 'https://example.com/some/path';
        
        final result = DeepLinkService.isEmailVerificationLink(invalidLink);
        
        expect(result, isFalse);
      });
    });
  });

  group('DeepLinkHandler Tests', () {
    late DeepLinkService mockDeepLinkService;
    late DeepLinkHandler deepLinkHandler;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Create a real DeepLinkService for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        (MethodCall methodCall) async => null,
      );
      
      mockDeepLinkService = DeepLinkService();
      deepLinkHandler = DeepLinkHandler(mockDeepLinkService);
    });

    tearDown(() {
      deepLinkHandler.dispose();
      mockDeepLinkService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        null,
      );
    });

    test('handles password reset link correctly', () async {
      const resetLink = 'https://qraft.gothcorp.io/auth/action?mode=resetPassword&oobCode=test123';
      
      // The handler should process the link without throwing
      expect(() => deepLinkHandler.handleDeepLink(resetLink), returnsNormally);
    });

    test('handles email verification link correctly', () async {
      const verifyLink = 'https://qraft.gothcorp.io/auth/action?mode=verifyEmail&oobCode=test123';
      
      // The handler should process the link without throwing
      expect(() => deepLinkHandler.handleDeepLink(verifyLink), returnsNormally);
    });

    test('handles unknown link gracefully', () async {
      const unknownLink = 'https://example.com/unknown/path';
      
      // The handler should process unknown links without throwing
      expect(() => deepLinkHandler.handleDeepLink(unknownLink), returnsNormally);
    });

    test('disposes properly', () {
      expect(() => deepLinkHandler.dispose(), returnsNormally);
    });
  });

  group('Integration Tests', () {
    test('DeepLinkService and DeepLinkHandler work together', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        (MethodCall methodCall) async => null,
      );

      final service = DeepLinkService();
      final handler = DeepLinkHandler(service);

      // Should initialize without errors
      expect(service, isNotNull);
      expect(handler, isNotNull);

      // Clean up
      handler.dispose();
      service.dispose();
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('qraft/deeplink'),
        null,
      );
    });
  });
}