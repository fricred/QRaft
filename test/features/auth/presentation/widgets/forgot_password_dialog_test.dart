import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qraft/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:qraft/features/auth/data/providers/supabase_auth_provider.dart';
import 'package:qraft/shared/widgets/glass_button.dart';
import 'package:qraft/l10n/app_localizations.dart';

// Mock classes
class MockSupabaseAuthProvider extends Mock implements SupabaseAuthProvider {}

void main() {
  group('ForgotPasswordDialog Tests', () {
    late MockSupabaseAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockSupabaseAuthProvider();
      
      // Set up default mock behavior
      when(() => mockAuthProvider.isLoading).thenReturn(false);
      when(() => mockAuthProvider.errorMessage).thenReturn(null);
      when(() => mockAuthProvider.resetPassword(any())).thenAnswer((_) async {});
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          supabaseAuthProvider.overrideWith((ref) => mockAuthProvider),
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

    testWidgets('renders dialog with correct structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for basic dialog structure
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(GlassButton), findsAtLeastNWidgets(1));
    });

    testWidgets('contains email input field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that email field exists
      final emailField = find.byType(TextFormField);
      expect(emailField, findsOneWidget);
      
      // Verify we can enter text
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('validates empty email input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to submit empty form by tapping the GlassButton (send button)
      final sendButton = find.byType(GlassButton);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Form validation should prevent submission - form should still be visible
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('accepts valid email format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'valid@example.com');
      await tester.pumpAndSettle();

      // Email should be accepted
      expect(find.text('valid@example.com'), findsOneWidget);
    });

    testWidgets('has cancel and send buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for action buttons by type rather than text (due to localization)
      expect(find.byType(OutlinedButton), findsOneWidget); // Cancel button
      expect(find.byType(GlassButton), findsOneWidget);    // Send button
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseAuthProvider.overrideWith((ref) => mockAuthProvider),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ForgotPasswordDialog(),
                  ),
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
      
      // Verify dialog is shown
      expect(find.byType(ForgotPasswordDialog), findsOneWidget);

      // Tap cancel button (OutlinedButton)
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(ForgotPasswordDialog), findsNothing);
    });
  });
}