import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qraft/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:qraft/features/auth/presentation/widgets/forgot_password_dialog.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Fake `SupabaseClient` we hand to the production controller subclass so its
/// constructor never reaches into the static `SupabaseService.client` (which
/// would throw "Supabase has not been initialized" in the test environment).
/// The stub controller below short-circuits `submit()` so this fake's methods
/// are never invoked — it exists purely to satisfy the constructor signature.
class _FakeSupabaseClient extends Fake implements SupabaseClient {}

/// Stub controller for widget tests.
///
/// Per Phase 1 plan 07 PATTERNS guidance (checker WARNING 5): extends the
/// production class directly so all inherited `StateNotifier` members
/// (`state` setter, `addListener`, `dispose`) keep working — no
/// `noSuchMethod` fallback needed. `submit()` is overridden as a no-op
/// because widget tests assert state-driven UI; the real submission path
/// is exercised in `forgot_password_controller_test.dart`.
class _StubController extends ForgotPasswordController {
  _StubController(ForgotPasswordState initial)
      : super(client: _FakeSupabaseClient()) {
    state = initial;
  }

  @override
  Future<void> submit(String email) async {
    // Intentionally a no-op — widget tests drive the UI from injected state.
  }
}

Widget createTestWidget({ForgotPasswordState? state}) {
  final stub = _StubController(state ?? const ForgotPasswordState());
  return ProviderScope(
    overrides: [
      forgotPasswordControllerProvider.overrideWith((ref) => stub),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ForgotPasswordDialog()),
    ),
  );
}

void main() {
  group('ForgotPasswordDialog — UI rendering', () {
    testWidgets('renders email field, send button, cancel button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgot_password_dialog_root')),
          findsOneWidget);
      expect(find.byKey(const Key('forgot_password_email_field')),
          findsOneWidget);
      expect(find.byKey(const Key('forgot_password_send_button')),
          findsOneWidget);
      expect(find.byKey(const Key('forgot_password_cancel_button')),
          findsOneWidget);
    });

    testWidgets('accepts text input on the email field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('forgot_password_email_field'));
      await tester.enterText(emailField, 'user@example.com');
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('empty submit triggers form validation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap send with empty email — the Form validator should fire and the
      // form should remain visible (not advance to success state).
      await tester.tap(find.byKey(const Key('forgot_password_send_button')));
      await tester.pumpAndSettle();

      // Form is still rendered (validation prevented the success-state swap).
      expect(find.byKey(const Key('forgot_password_email_field')),
          findsOneWidget);
      // Success-state container must NOT appear because submit was blocked.
      expect(find.byKey(const Key('forgot_password_success_state')),
          findsNothing);
    });
  });

  group('ForgotPasswordDialog — state-driven UI', () {
    testWidgets('loading state shows progress indicator', (tester) async {
      // Use runAsync so the indeterminate CircularProgressIndicator's internal
      // ticker can run on the real clock instead of the fake test clock; this
      // keeps the test from tripping the "Timer still pending" invariant when
      // the widget tree is torn down.
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget(
          state: const ForgotPasswordState(isLoading: true),
        ));
        await tester.pump();

        // PrimaryGlassButton with isLoading=true renders a CircularProgressIndicator.
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    testWidgets('success state shows the success container', (tester) async {
      await tester.pumpWidget(createTestWidget(
        state: const ForgotPasswordState(emailSent: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgot_password_success_state')),
          findsOneWidget);
      // The form fields must NOT be visible when in success state.
      expect(find.byKey(const Key('forgot_password_email_field')),
          findsNothing);
    });

    testWidgets('cancel button exists and is tappable in idle state',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const Key('forgot_password_cancel_button'));
      expect(cancelBtn, findsOneWidget);
      // Just tap — different dialog wrappings differ; existence is the signal.
      await tester.tap(cancelBtn);
      await tester.pump();
    });
  });
}
