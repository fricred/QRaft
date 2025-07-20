import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qraft/features/auth/data/providers/auth_provider.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  group('AuthRepository Basic Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late AuthRepository authRepository;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authRepository = AuthRepository(mockFirebaseAuth);
    });

    group('signInWithEmailAndPassword', () {
      test('calls Firebase Auth with correct parameters', () async {
        // Arrange
        final mockUserCredential = MockUserCredential();
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        await authRepository.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('throws AuthException when FirebaseAuthException occurs', () async {
        // Arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        ));

        // Act & Assert
        expect(
          () => authRepository.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('calls Firebase Auth with correct parameters', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
        when(() => mockUser.reload()).thenAnswer((_) async {});
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        await authRepository.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
          displayName: 'New User',
        );

        // Assert
        verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
        )).called(1);
        verify(() => mockUser.updateDisplayName('New User')).called(1);
        verify(() => mockUser.reload()).called(1);
      });

      test('throws AuthException when FirebaseAuthException occurs', () async {
        // Arrange
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The account already exists for that email.',
        ));

        // Act & Assert
        expect(
          () => authRepository.createUserWithEmailAndPassword(
            email: 'existing@example.com',
            password: 'password123',
            displayName: 'User',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('calls Firebase Auth with correct parameters', () async {
        // Arrange
        when(() => mockFirebaseAuth.sendPasswordResetEmail(
          email: any(named: 'email'),
          actionCodeSettings: any(named: 'actionCodeSettings'),
        )).thenAnswer((_) async {});

        // Act
        await authRepository.sendPasswordResetEmail(
          email: 'test@example.com',
        );

        // Assert
        verify(() => mockFirebaseAuth.sendPasswordResetEmail(
          email: 'test@example.com',
          actionCodeSettings: any(named: 'actionCodeSettings'),
        )).called(1);
      });

      test('throws AuthException when FirebaseAuthException occurs', () async {
        // Arrange
        when(() => mockFirebaseAuth.sendPasswordResetEmail(
          email: any(named: 'email'),
          actionCodeSettings: any(named: 'actionCodeSettings'),
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        ));

        // Act & Assert
        expect(
          () => authRepository.sendPasswordResetEmail(
            email: 'nonexistent@example.com',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('verifyPasswordResetCode', () {
      test('calls Firebase Auth with correct code', () async {
        // Arrange
        const testCode = 'test-reset-code-123';
        const testEmail = 'test@example.com';
        when(() => mockFirebaseAuth.verifyPasswordResetCode(any()))
            .thenAnswer((_) async => testEmail);

        // Act
        final result = await authRepository.verifyPasswordResetCode(testCode);

        // Assert
        expect(result, true);
        verify(() => mockFirebaseAuth.verifyPasswordResetCode(testCode)).called(1);
      });

      test('throws AuthException when FirebaseAuthException occurs', () async {
        // Arrange
        const testCode = 'invalid-code';
        when(() => mockFirebaseAuth.verifyPasswordResetCode(any()))
            .thenThrow(FirebaseAuthException(
          code: 'invalid-action-code',
          message: 'The action code is invalid.',
        ));

        // Act & Assert
        expect(
          () => authRepository.verifyPasswordResetCode(testCode),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('confirmPasswordReset', () {
      test('calls Firebase Auth with correct parameters', () async {
        // Arrange
        const testCode = 'test-reset-code-123';
        const newPassword = 'newSecurePassword123';
        when(() => mockFirebaseAuth.confirmPasswordReset(
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async {});

        // Act
        await authRepository.confirmPasswordReset(
          code: testCode,
          newPassword: newPassword,
        );

        // Assert
        verify(() => mockFirebaseAuth.confirmPasswordReset(
          code: testCode,
          newPassword: newPassword,
        )).called(1);
      });

      test('throws AuthException when FirebaseAuthException occurs', () async {
        // Arrange
        const testCode = 'expired-code';
        const newPassword = 'newPassword123';
        when(() => mockFirebaseAuth.confirmPasswordReset(
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenThrow(FirebaseAuthException(
          code: 'expired-action-code',
          message: 'The action code has expired.',
        ));

        // Act & Assert
        expect(
          () => authRepository.confirmPasswordReset(
            code: testCode,
            newPassword: newPassword,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('calls Firebase Auth signOut', () async {
        // Arrange
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authRepository.signOut();

        // Assert
        verify(() => mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('currentUser getter', () {
      test('returns current user from Firebase Auth', () {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authRepository.currentUser;

        // Assert
        expect(result, equals(mockUser));
        verify(() => mockFirebaseAuth.currentUser).called(1);
      });

      test('returns null when no user is signed in', () {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = authRepository.currentUser;

        // Assert
        expect(result, isNull);
      });
    });

    group('isSignedIn getter', () {
      test('returns true when user is signed in', () {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authRepository.isSignedIn;

        // Assert
        expect(result, true);
      });

      test('returns false when no user is signed in', () {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = authRepository.isSignedIn;

        // Assert
        expect(result, false);
      });
    });
  });

  group('AuthException Basic Tests', () {
    test('AuthException can be created with code and message', () {
      const message = 'Test error message';
      const code = 'test-error';
      final exception = AuthException(code: code, message: message);

      expect(exception.message, equals(message));
      expect(exception.code, equals(code));
    });

    test('AuthException fromFirebaseAuthException factory works', () {
      final firebaseException = FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for that email.',
      );
      
      final authException = AuthException.fromFirebaseAuthException(firebaseException);
      
      expect(authException.code, equals('user-not-found'));
      expect(authException.message, isNotEmpty);
    });
  });
}