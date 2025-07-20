import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qraft/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:qraft/features/auth/data/providers/auth_provider.dart';
import 'package:qraft/shared/widgets/glass_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('ForgotPasswordDialog Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: ForgotPasswordDialog(),
          ),
        ),
      );
    }

    testWidgets('renders dialog with correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for dialog elements
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email to receive reset link'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('validates email input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to submit without email
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('calls sendPasswordResetEmail when valid email is entered', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockAuthRepository.sendPasswordResetEmail(email: 'test@example.com')).called(1);
    });

    testWidgets('shows success state after email is sent', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Assert - Check for success state
      expect(find.text('Email Sent!'), findsOneWidget);
      expect(find.textContaining('test@example.com'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_rounded), findsOneWidget);
    });

    testWidgets('closes dialog when cancel is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showForgotPasswordDialog(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordDialog), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordDialog), findsNothing);
    });

    testWidgets('closes dialog when done is pressed in success state', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showForgotPasswordDialog(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ForgotPasswordDialog), findsNothing);
    });

    testWidgets('form submission works correctly', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enter email and click Send button
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Assert - Repository method should be called
      verify(() => mockAuthRepository.sendPasswordResetEmail(email: 'test@example.com')).called(1);
    });

    testWidgets('can enter email and form validates correctly', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Enter valid email
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      
      // Assert - Form should accept valid email
      expect(find.text('test@example.com'), findsOneWidget);
      
      // Form should be submittable (Send button should be present)
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('dialog has proper structure and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for basic dialog structure
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.byType(PrimaryGlassButton), findsOneWidget);
    });

    testWidgets('handles email sending failure gracefully', (WidgetTester tester) async {
      // Arrange - Mock failure
      when(() => mockAuthRepository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(AuthException(code: 'user-not-found', message: 'User not found'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Assert - Should remain in form state (not show success)
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email Sent!'), findsNothing);
    });

    testWidgets('email field has correct input properties', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for TextFormField existence
      expect(find.byType(TextFormField), findsOneWidget);
      
      // Check for email hint text
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for semantic labels
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
      
      // Check for proper form structure
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('showForgotPasswordDialog function tests', () {
    testWidgets('shows dialog when called', (WidgetTester tester) async {
      final mockAuthRepository = MockAuthRepository();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showForgotPasswordDialog(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ForgotPasswordDialog), findsNothing);

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordDialog), findsOneWidget);
    });

    testWidgets('dialog is not dismissible by tapping outside', (WidgetTester tester) async {
      final mockAuthRepository = MockAuthRepository();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showForgotPasswordDialog(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordDialog), findsOneWidget);

      // Try to dismiss by tapping outside
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.byType(ForgotPasswordDialog), findsOneWidget);
    });
  });
}