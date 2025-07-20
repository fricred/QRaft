import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qraft/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qraft/features/auth/data/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  group('AuthController Comprehensive Tests', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('has correct initial state', () {
        final state = container.read(authControllerProvider);
        
        expect(state.isLoading, false);
        expect(state.errorMessage, isNull);
        expect(state.isAuthenticated, false);
      });
    });

    group('signInWithEmailAndPassword', () {
      test('successful sign in updates state correctly', () async {
        // Arrange
        when(() => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => MockUserCredential());

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, true);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.isAuthenticated, true);
        expect(finalState.errorMessage, isNull);
        
        verify(() => mockAuthRepository.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('failed sign in handles AuthException correctly', () async {
        // Arrange
        const errorMessage = 'Invalid email or password';
        when(() => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(AuthException(code: 'invalid-credential', message: errorMessage));

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result, false);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.isAuthenticated, false);
        expect(finalState.errorMessage, errorMessage);
      });

      test('failed sign in handles unexpected exception', () async {
        // Arrange
        when(() => mockAuthRepository.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Network error'));

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, false);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.isAuthenticated, false);
        expect(finalState.errorMessage, 'An unexpected error occurred. Please try again.');
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('successful user creation updates state correctly', () async {
        // Arrange
        when(() => mockAuthRepository.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => MockUserCredential());

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
          displayName: 'New User',
        );

        // Assert
        expect(result, true);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.isAuthenticated, true);
        expect(finalState.errorMessage, isNull);
        
        verify(() => mockAuthRepository.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
          displayName: 'New User',
        )).called(1);
      });

      test('failed user creation handles AuthException correctly', () async {
        // Arrange
        const errorMessage = 'An account already exists with this email address.';
        when(() => mockAuthRepository.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenThrow(AuthException(code: 'email-already-in-use', message: errorMessage));

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.createUserWithEmailAndPassword(
          email: 'existing@example.com',
          password: 'password123',
          displayName: 'User',
        );

        // Assert
        expect(result, false);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.isAuthenticated, false);
        expect(finalState.errorMessage, errorMessage);
      });
    });

    group('sendPasswordResetEmail', () {
      test('successful password reset request updates state correctly', () async {
        // Arrange
        when(() => mockAuthRepository.sendPasswordResetEmail(
          email: any(named: 'email'),
        )).thenAnswer((_) async {});

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.sendPasswordResetEmail(
          email: 'test@example.com',
        );

        // Assert
        expect(result, true);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.errorMessage, isNull);
        
        verify(() => mockAuthRepository.sendPasswordResetEmail(
          email: 'test@example.com',
        )).called(1);
      });

      test('failed password reset handles AuthException correctly', () async {
        // Arrange
        const errorMessage = 'No user found with this email address.';
        when(() => mockAuthRepository.sendPasswordResetEmail(
          email: any(named: 'email'),
        )).thenThrow(AuthException(code: 'user-not-found', message: errorMessage));

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        final result = await controller.sendPasswordResetEmail(
          email: 'nonexistent@example.com',
        );

        // Assert
        expect(result, false);
        
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.errorMessage, errorMessage);
      });
    });

    group('signOut', () {
      test('successful sign out updates state correctly', () async {
        // Arrange
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        await controller.signOut();

        // Assert
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.isAuthenticated, false);
        expect(finalState.errorMessage, isNull);
        
        verify(() => mockAuthRepository.signOut()).called(1);
      });

      test('failed sign out handles exception correctly', () async {
        // Arrange
        when(() => mockAuthRepository.signOut()).thenThrow(Exception('Network error'));

        final controller = container.read(authControllerProvider.notifier);
        
        // Act
        await controller.signOut();

        // Assert
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
        expect(finalState.errorMessage, 'Failed to sign out. Please try again.');
      });
    });

    group('Utility Methods', () {
      test('clearError removes error message', () {
        // Arrange
        final controller = container.read(authControllerProvider.notifier);
        
        // Set an error state first
        controller.state = controller.state.copyWith(errorMessage: 'Test error');
        expect(container.read(authControllerProvider).errorMessage, 'Test error');
        
        // Act
        controller.clearError();
        
        // Assert
        final finalState = container.read(authControllerProvider);
        expect(finalState.errorMessage, isNull);
      });

      test('resetLoading sets isLoading to false', () {
        // Arrange
        final controller = container.read(authControllerProvider.notifier);
        
        // Set loading state first
        controller.state = controller.state.copyWith(isLoading: true);
        expect(container.read(authControllerProvider).isLoading, true);
        
        // Act
        controller.resetLoading();
        
        // Assert
        final finalState = container.read(authControllerProvider);
        expect(finalState.isLoading, false);
      });
    });
  });

  group('AuthState Comprehensive Tests', () {
    test('AuthState can be created with default values', () {
      const state = AuthState();
      
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.isAuthenticated, false);
    });

    test('AuthState can be created with custom values', () {
      const state = AuthState(
        isLoading: true,
        errorMessage: 'Test error',
        isAuthenticated: true,
      );
      
      expect(state.isLoading, true);
      expect(state.errorMessage, 'Test error');
      expect(state.isAuthenticated, true);
    });

    test('AuthState copyWith works correctly for all fields', () {
      const originalState = AuthState(
        isLoading: true,
        errorMessage: 'Original error',
        isAuthenticated: false,
      );

      final newState = originalState.copyWith(
        isLoading: false,
        errorMessage: 'New error',
        isAuthenticated: true,
      );

      expect(newState.isLoading, false);
      expect(newState.errorMessage, 'New error');
      expect(newState.isAuthenticated, true);
    });

    test('AuthState copyWith preserves unchanged fields except errorMessage', () {
      const originalState = AuthState(
        isLoading: true,
        errorMessage: 'Test error',
        isAuthenticated: true,
      );

      final newState = originalState.copyWith(
        isLoading: false,
        errorMessage: 'Test error', // Need to explicitly pass to preserve
      );

      expect(newState.isLoading, false);
      expect(newState.errorMessage, 'Test error');
      expect(newState.isAuthenticated, true); // Preserved
    });

    test('AuthState copyWith can clear errorMessage by passing null', () {
      const originalState = AuthState(
        isLoading: false,
        errorMessage: 'Test error',
        isAuthenticated: false,
      );

      final newState = originalState.copyWith(errorMessage: null);

      expect(newState.isLoading, false);
      expect(newState.errorMessage, isNull);
      expect(newState.isAuthenticated, false);
    });
  });
}