import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qraft/features/auth/presentation/controllers/forgot_password_controller.dart';

// Mocktail mocks for the Supabase client + GoTrue auth surface. The controller
// accepts a `SupabaseClient` via constructor (Phase 1 plan 06 testability seam,
// resolves D-08), so we never touch the static `SupabaseService.client` here.
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late ForgotPasswordController controller;

  setUpAll(() {
    // mocktail requires fallback values for any() matchers on non-nullable
    // positional / named args. resetPasswordForEmail accepts a String and an
    // optional named `redirectTo` (also a String) — register both fallbacks.
    registerFallbackValue('');
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    controller = ForgotPasswordController(client: mockClient);
  });

  tearDown(() {
    controller.dispose();
  });

  group('ForgotPasswordController — Initial State', () {
    test('starts with isLoading=false, emailSent=false, errorMessage=null', () {
      expect(controller.state.isLoading, false);
      expect(controller.state.emailSent, false);
      expect(controller.state.errorMessage, isNull);
    });
  });

  group('ForgotPasswordController — submit() happy path', () {
    test('transitions through loading → emailSent', () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
            redirectTo: any(named: 'redirectTo'),
          )).thenAnswer((_) async {});

      final future = controller.submit('user@example.com');
      // Mid-flight state — submit is async and the controller flips
      // isLoading=true synchronously before the awaited Supabase call resolves.
      expect(controller.state.isLoading, true);
      expect(controller.state.errorMessage, isNull);

      await future;
      expect(controller.state.isLoading, false);
      expect(controller.state.emailSent, true);
      expect(controller.state.errorMessage, isNull);

      verify(() => mockAuth.resetPasswordForEmail(
            'user@example.com',
            redirectTo: 'qraft://auth/reset',
          )).called(1);
    });
  });

  group('ForgotPasswordController — submit() AuthException', () {
    test('maps AuthException to errorMessage with "Password reset failed: ..."',
        () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
            redirectTo: any(named: 'redirectTo'),
          )).thenThrow(const AuthException('Invalid email'));

      await controller.submit('user@example.com');

      expect(controller.state.isLoading, false);
      expect(controller.state.emailSent, false);
      expect(controller.state.errorMessage, contains('Password reset failed'));
      expect(controller.state.errorMessage, contains('Invalid email'));
    });
  });

  group('ForgotPasswordController — submit() generic Exception', () {
    test('maps generic Exception to "An unexpected error occurred"', () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
            redirectTo: any(named: 'redirectTo'),
          )).thenThrow(Exception('network down'));

      await controller.submit('user@example.com');

      expect(controller.state.isLoading, false);
      expect(controller.state.emailSent, false);
      expect(controller.state.errorMessage, 'An unexpected error occurred');
    });
  });

  group('ForgotPasswordController — re-entrancy guard', () {
    test('concurrent submit calls only invoke resetPasswordForEmail once',
        () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
            redirectTo: any(named: 'redirectTo'),
          )).thenAnswer((_) async {
        // Simulate latency so the second submit() sees isLoading=true.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final f1 = controller.submit('a@b.com');
      final f2 = controller.submit('a@b.com'); // should no-op while loading
      await Future.wait([f1, f2]);

      verify(() => mockAuth.resetPasswordForEmail(
            any(),
            redirectTo: any(named: 'redirectTo'),
          )).called(1);
    });
  });

  group('ForgotPasswordController — reset()', () {
    test('returns to initial state after a prior submission', () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
            redirectTo: any(named: 'redirectTo'),
          )).thenAnswer((_) async {});

      await controller.submit('user@example.com');
      expect(controller.state.emailSent, true);

      controller.reset();
      expect(controller.state.isLoading, false);
      expect(controller.state.emailSent, false);
      expect(controller.state.errorMessage, isNull);
    });
  });

  group('ForgotPasswordState — copyWith', () {
    test('clearError=true wipes errorMessage while preserving other fields',
        () {
      const s = ForgotPasswordState(
        isLoading: true,
        emailSent: false,
        errorMessage: 'Boom',
      );
      final s2 = s.copyWith(clearError: true);
      expect(s2.errorMessage, isNull);
      expect(s2.isLoading, true);
      expect(s2.emailSent, false);
    });

    test('value equality holds for identical field sets', () {
      const a = ForgotPasswordState(
        isLoading: true,
        emailSent: false,
        errorMessage: 'x',
      );
      const b = ForgotPasswordState(
        isLoading: true,
        emailSent: false,
        errorMessage: 'x',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
