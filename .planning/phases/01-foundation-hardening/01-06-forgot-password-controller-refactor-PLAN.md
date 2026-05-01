---
phase: 01-foundation-hardening
plan: 06
type: execute
wave: 3
depends_on:
  - 02
files_modified:
  - lib/features/auth/presentation/controllers/forgot_password_controller.dart
  - lib/features/auth/presentation/widgets/forgot_password_dialog.dart
  - lib/features/auth/presentation/pages/login_screen.dart
  - lib/features/auth/presentation/pages/welcome_screen.dart
  - lib/features/main/main_scaffold.dart
  - lib/features/qr_scanner/qr_scanner_screen.dart
  - .planning/codebase/CONCERNS.md
  - CLAUDE.md
autonomous: true
requirements: []
must_haves:
  truths:
    - "A new `ForgotPasswordController` exists at `lib/features/auth/presentation/controllers/forgot_password_controller.dart` extracting the async/loading/success state machine from `forgot_password_dialog.dart` (D-08)"
    - "The controller pattern decision is documented in this plan (and the resulting SUMMARY): planner picks `StateNotifier<ForgotPasswordState>` with an immutable state class, matching the existing precedent at `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` since no AsyncNotifier example exists in the codebase (D-09; PATTERNS.md `forgot_password_controller.dart` analog discussion)"
    - "`forgot_password_dialog.dart` no longer holds async state in widget local state — `_emailSent` boolean is gone; UI reads `ref.watch(forgotPasswordControllerProvider)`; submission calls `ref.read(forgotPasswordControllerProvider.notifier).submit(email)` (D-08, PATTERNS.md modification target)"
    - "Stable Maestro Keys are present on the dialog: `forgot_password_email_field`, `forgot_password_send_button`, `forgot_password_cancel_button`, `forgot_password_success_state` (PATTERNS.md `forgot_password_dialog.dart` section)"
    - "Login + welcome screens carry stable Keys for Maestro auth flows: `login_email_field`, `login_password_field`, `login_submit_button`, `login_forgot_password_link`, `welcome_login_cta`, `welcome_signup_cta`"
    - "Main scaffold scanner tab is targetable: `main_scaffold_scanner_tab`"
    - "Scanner screen root is targetable: `qr_scanner_screen_root`"
    - "ForgotPasswordController accepts a `SupabaseClient` via constructor (do NOT use static `SupabaseService.client` — testability blocker per D-08; PATTERNS.md note `the controller MUST accept the client via constructor for testability`)"
    - "Empirical test count of `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` BEFORE refactor is recorded: 6 tests (verified via `grep -c 'testWidgets\\|^\\s*test(' file`); the 13/5 documentation in CLAUDE.md and CONCERNS.md is corrected (D-10)"
    - "`.planning/codebase/CONCERNS.md` line 47 (`5 out of 13 tests failing`) is corrected to reflect the empirical count + the fact this plan refactors and plan 07 rewrites the tests"
    - "CLAUDE.md `Testing Implementation Status` section's `🔄 ForgotPasswordDialog: 5/13 tests passing` line is corrected to match reality"
    - "All references to the non-existent `lib/features/auth/presentation/controllers/auth_controller.dart` are scrubbed from `CLAUDE.md` — that file does NOT exist on disk (verified `ls lib/features/auth/presentation/controllers/` returns empty); references replaced with the actual auth state holder `lib/features/auth/data/providers/supabase_auth_provider.dart` or annotated as 'forthcoming `ForgotPasswordController` (Phase 1 plan 06)' depending on context"
    - "`flutter analyze` reports zero new errors and `flutter build apk --debug` + `flutter build ios --debug --no-codesign` both succeed"
  artifacts:
    - path: "lib/features/auth/presentation/controllers/forgot_password_controller.dart"
      provides: "StateNotifier-based controller for forgot password submission"
      min_lines: 80
      contains: "class ForgotPasswordController"
    - path: "lib/features/auth/presentation/widgets/forgot_password_dialog.dart"
      provides: "Refactored dialog reading from ForgotPasswordController; widget keys for Maestro"
      contains: "forgotPasswordControllerProvider"
    - path: "lib/features/auth/presentation/pages/login_screen.dart"
      provides: "Login screen with stable Maestro keys"
      contains: "login_email_field"
    - path: "lib/features/auth/presentation/pages/welcome_screen.dart"
      provides: "Welcome screen with stable Maestro keys"
      contains: "welcome_login_cta"
    - path: "lib/features/main/main_scaffold.dart"
      provides: "Bottom-nav scanner tab carries Maestro key"
      contains: "main_scaffold_scanner_tab"
    - path: "lib/features/qr_scanner/qr_scanner_screen.dart"
      provides: "Scanner screen root carries Maestro key"
      contains: "qr_scanner_screen_root"
    - path: ".planning/codebase/CONCERNS.md"
      provides: "Corrected ForgotPasswordDialog test count"
    - path: "CLAUDE.md"
      provides: "Corrected ForgotPasswordDialog test count + scrubbed auth_controller.dart references"
  key_links:
    - from: "forgot_password_dialog.dart submit handler"
      to: "ForgotPasswordController.submit()"
      via: "ref.read(forgotPasswordControllerProvider.notifier).submit(email) instead of inline supabaseAuthProvider call"
      pattern: "forgotPasswordControllerProvider\\.notifier"
    - from: "forgot_password_dialog.dart UI states"
      to: "ForgotPasswordState (idle/loading/success/error)"
      via: "ref.watch(forgotPasswordControllerProvider) drives loading spinner, success container, error message"
      pattern: "ref\\.watch\\(forgotPasswordControllerProvider\\)"
    - from: "Maestro flows in plan 07"
      to: "Stable Keys added in this plan"
      via: "Keys are the only stable selectors Maestro can target across locales"
      pattern: "Key\\('(forgot_password|login|welcome|main_scaffold|qr_scanner)_"
---

<objective>
Extract the async/loading/success state machine from `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` (currently 328 lines, see PATTERNS.md caveat 2) into a new `ForgotPasswordController` (StateNotifier + immutable state class) per D-08 and D-09. Add stable Maestro Keys to the dialog AND to the auth flow widgets, main scaffold, and scanner screen so plan 07 can author E2E flows. Reconcile the test-count discrepancy between CLAUDE.md / CONCERNS.md and the actual file (6 tests, not 13) per D-10. Test rewrites land in plan 07; this plan stops at "controller exists, dialog uses it, builds clean."

**Also (per checker WARNING 4):** scrub the references to the non-existent `lib/features/auth/presentation/controllers/auth_controller.dart` from `CLAUDE.md`. PATTERNS.md caveat 1 documents the discrepancy: that file does NOT exist on disk; the actual auth state holder is `lib/features/auth/data/providers/supabase_auth_provider.dart`. CLAUDE.md still has 4 stale references that must be reconciled in task 1 alongside the test-count fix.

**Controller pattern decision (D-09 — planner picks):**

Use `StateNotifier<ForgotPasswordState>` with an immutable `ForgotPasswordState` class. Reasoning:
1. PATTERNS.md note 1: there is NO `AsyncNotifier` example in the entire codebase (D-09 invites the planner to weigh consistency vs forward-looking).
2. The closest precedent is `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` which uses `StateNotifier` + immutable state class. That is the consistent pattern.
3. Migrating other providers from `StateNotifier` → `AsyncNotifier` is explicitly listed in CONTEXT.md `<deferred>` as out-of-Phase-1 scope.
4. Phase 1 is foundation hardening — introducing a brand-new pattern just for one controller would create asymmetry without benefit.

Output: New controller + refactored dialog + stable Keys on 5 widgets + 2 docs reconciled (test count + auth_controller.dart scrub).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/phases/01-foundation-hardening/01-CONTEXT.md
@.planning/phases/01-foundation-hardening/01-PATTERNS.md
@.planning/codebase/CONCERNS.md
@lib/features/auth/data/providers/supabase_auth_provider.dart
@lib/features/auth/presentation/widgets/forgot_password_dialog.dart
@lib/features/auth/presentation/pages/login_screen.dart
@lib/features/auth/presentation/pages/welcome_screen.dart
@lib/features/main/main_scaffold.dart
@lib/features/qr_scanner/qr_scanner_screen.dart
@lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart
@.maestro/CONVENTIONS.md

<interfaces>
<!-- Patterns to follow, copied from PATTERNS.md / source files. Executor uses these directly. -->

From lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart (state class + StateNotifier shape — the analog for ForgotPasswordController):
```dart
class QRCustomizationState {
  final QRCustomization customization;
  final bool isPreviewMode;

  const QRCustomizationState({
    this.customization = const QRCustomization(),
    this.isPreviewMode = false,
  });

  QRCustomizationState copyWith({
    QRCustomization? customization,
    bool? isPreviewMode,
  }) {
    return QRCustomizationState(
      customization: customization ?? this.customization,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
    );
  }
}

class QRCustomizationController extends StateNotifier<QRCustomizationState> {
  QRCustomizationController() : super(const QRCustomizationState());

  void updateForegroundColor(Color color) {
    final customization = state.customization.copyWith(
      foregroundColor: _colorToInt(color),
    );
    state = state.copyWith(customization: customization);
  }
}

final qrCustomizationControllerProvider = StateNotifierProvider<QRCustomizationController, QRCustomizationState>((ref) {
  return QRCustomizationController();
});
```

From lib/features/auth/data/providers/supabase_auth_provider.dart (try/AuthException/catch/finally pattern, lines 145-165):
```dart
Future<void> resetPassword(String email) async {
  try {
    _setLoading(true);
    _clearError();

    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'qraft://auth/reset',
    );
    debugPrint('Password reset email sent to: $email');

  } on AuthException catch (e) {
    debugPrint('Password reset error: ${e.message}');
    _setError('Password reset failed: ${e.message}');
  } catch (e) {
    debugPrint('Unexpected password reset error: $e');
    _setError('An unexpected error occurred');
  } finally {
    _setLoading(false);
  }
}
```

From lib/features/auth/presentation/widgets/forgot_password_dialog.dart (current async logic to EXTRACT, lines 27-38):
```dart
void _handleSendResetEmail() async {
  if (_formKey.currentState?.validate() ?? false) {
    final authProvider = ref.read(supabaseAuthProvider);
    await authProvider.resetPassword(_emailController.text);

    if (authProvider.errorMessage == null) {
      setState(() {
        _emailSent = true;
      });
    }
  }
}
```

This becomes (post-refactor):
```dart
void _handleSendResetEmail() async {
  if (_formKey.currentState?.validate() ?? false) {
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text);
  }
}
```

The local `_emailSent` boolean and `setState` are removed. UI states come from `ref.watch(forgotPasswordControllerProvider)`.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Empirically count tests + reconcile CLAUDE.md (test count + auth_controller scrub) and CONCERNS.md</name>
  <files>.planning/codebase/CONCERNS.md, CLAUDE.md</files>
  <read_first>
    - test/features/auth/presentation/widgets/forgot_password_dialog_test.dart (count tests empirically)
    - .planning/codebase/CONCERNS.md (find the line claiming "5 out of 13 tests failing" — line 47)
    - CLAUDE.md (find every line referencing the non-existent `auth_controller.dart`; verified pre-plan via `grep -n 'auth_controller' CLAUDE.md`: 4 hits — lines 66, 786, 828, 849)
    - CLAUDE.md (find the line claiming "🔄 ForgotPasswordDialog: 5/13 tests passing")
    - PATTERNS.md caveat 1 (documents that `lib/features/auth/presentation/controllers/auth_controller.dart` does NOT exist; the actual auth state holder is `supabase_auth_provider.dart`)
  </read_first>
  <action>
**Step 1 — count tests empirically.** Run:
```bash
grep -cE 'testWidgets\(|^\s*test\(' test/features/auth/presentation/widgets/forgot_password_dialog_test.dart
```
Expected output: `6` (per PATTERNS.md note 1 and CONTEXT.md D-10).

If the count is something other than 6, USE THE ACTUAL NUMBER throughout — do not hard-code 6.

**Step 2 — also count failing tests by running the suite.** Run:
```bash
flutter test test/features/auth/presentation/widgets/forgot_password_dialog_test.dart 2>&1 | tail -5
```
Capture the "+N -M" passing/failing summary. Use `M` as "failing" count.

**Step 3 — edit `.planning/codebase/CONCERNS.md`.** Find the section starting with `**ForgotPasswordDialog Test Failures:**` (currently around line 45-52). Update the `Symptoms:` line:
```
- Symptoms: 5 out of 13 tests failing for password reset flow
```
Change to (substituting the actual numbers):
```
- Symptoms: {M} out of {N_actual} tests {pre-refactor} for password reset flow (verified empirically 2026-05-01 — prior 5/13 figure in this doc was stale; reconciled per Phase 1 D-10)
```
Where `{N_actual}` is what step 1 returned and `{M}` is what step 2 returned.

ALSO update the "Test Coverage Gaps" section near line 322-327. Change:
```
- What's not tested: 5 out of 13 tests failing (per CLAUDE.md)
```
To:
```
- What's not tested: {M} of {N_actual} tests failing (verified empirically 2026-05-01); plan 06 extracts state into a controller, plan 07 rewrites the suite against the controller
```

**Step 4 — edit `CLAUDE.md` test-count line.** Find the line in the "Testing Implementation Status" section that says:
```
- 🔄 **ForgotPasswordDialog**: 5/13 tests passing (basic functionality working)
```
Change to:
```
- 🔄 **ForgotPasswordDialog**: {N_actual - M}/{N_actual} tests passing pre-refactor (verified 2026-05-01); refactored into controller + tests rewritten in Phase 1 plans 06+07
```

If the strings differ slightly from what is documented above (e.g., spaces, exact wording), find the actual matching strings via grep and update those.

**Step 5 — scrub `auth_controller.dart` references from CLAUDE.md (per checker WARNING 4).**

First, run `grep -n 'auth_controller' CLAUDE.md` to enumerate. As of 2026-05-01 baseline there are 4 lines:

| Line | Current text (approximately) | Context |
|---|---|---|
| 66 | `flutter test test/features/auth/presentation/controllers/auth_controller_simple_test.dart - Run AuthController tests` | "Code Quality" command list |
| 786 | `**AuthController** (\`test/features/auth/presentation/controllers/auth_controller_simple_test.dart\`)` | "Controller Tests" section heading |
| 828 | `flutter test test/features/auth/presentation/controllers/auth_controller_simple_test.dart` | "Running Tests" code block |
| 849 | `│               └── auth_controller_simple_test.dart  # State management tests` | "Test Structure" tree diagram |

The test file `test/features/auth/presentation/controllers/auth_controller_simple_test.dart` and the implementation file `lib/features/auth/presentation/controllers/auth_controller.dart` both do NOT exist on disk (verified `ls lib/features/auth/presentation/controllers/` returns empty as of 2026-05-01).

Replace strategy:
- The 4 references all describe a removed test file. The actual code path that handles auth is `lib/features/auth/data/providers/supabase_auth_provider.dart`, with its own test at `test/features/auth/data/providers/supabase_auth_provider_test.dart`.
- Replace each occurrence as follows:

  **Line 66:** Replace
  ```
  - `flutter test test/features/auth/presentation/controllers/auth_controller_simple_test.dart` - Run AuthController tests
  ```
  with
  ```
  - `flutter test test/features/auth/data/providers/supabase_auth_provider_test.dart` - Run SupabaseAuthProvider tests (the actual auth state holder; the legacy `AuthController` tests were removed when auth migrated to Supabase per D-03)
  ```

  **Line 786 area** (Controller Tests bullet — likely a multi-line block with surrounding bullets describing what tests existed). Replace the block so the AuthController bullet becomes:
  ```
  - **SupabaseAuthProvider** (`test/features/auth/data/providers/supabase_auth_provider_test.dart`)
    - Supabase Auth integration tests (replaces the removed AuthController tests; auth migrated to Supabase per D-03)
  ```
  Plus add a NEW bullet for the upcoming controller introduced in this plan:
  ```
  - **ForgotPasswordController** (NEW in Phase 1 plan 06; tests in Phase 1 plan 07 at `test/features/auth/presentation/controllers/forgot_password_controller_test.dart`)
  ```

  **Line 828 area** (Running Tests code block — replace the entire `flutter test` line that points at `auth_controller_simple_test.dart`):
  ```
  flutter test test/features/auth/data/providers/supabase_auth_provider_test.dart
  ```

  **Line 849 area** (Test Structure tree diagram — change the leaf `auth_controller_simple_test.dart` reference):
  ```
  │               └── supabase_auth_provider_test.dart  # State management tests (Supabase auth)
  ```

After edits, the goal is: `grep -c 'auth_controller' CLAUDE.md` returns 0 OR every remaining hit is wrapped in an annotation like "(removed in Supabase migration per D-03)".

Do NOT touch any other content in either file.
  </action>
  <verify>
    <automated>grep -c '5 out of 13' .planning/codebase/CONCERNS.md | xargs -I {} test {} -eq 0 &amp;&amp; grep -c '5/13 tests passing' CLAUDE.md | xargs -I {} test {} -eq 0 &amp;&amp; grep -c 'auth_controller_simple_test\.dart\|auth_controller\.dart' CLAUDE.md | xargs -I {} test {} -eq 0</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c 'verified empirically 2026-05-01' .planning/codebase/CONCERNS.md` returns at least 1
    - `grep -c '5 out of 13' .planning/codebase/CONCERNS.md` returns 0 (stale claim removed)
    - `grep -c '5/13 tests passing' CLAUDE.md` returns 0 (stale claim removed)
    - `grep -c 'pre-refactor' CLAUDE.md` returns at least 1 (new wording)
    - `grep -c 'auth_controller_simple_test\.dart' CLAUDE.md` returns 0 (4 stale references scrubbed; PATTERNS.md caveat 1)
    - `grep -c 'auth_controller\.dart' CLAUDE.md` returns 0 (no references to the non-existent file)
    - `grep -c 'supabase_auth_provider_test\.dart' CLAUDE.md` returns at least 2 (replacements landed in command list + tree diagram)
    - `grep -c 'ForgotPasswordController' CLAUDE.md` returns at least 1 (forward-pointer added for Phase 1 plan 06 controller)
    - The empirical test count was captured (visible in the diff or commit message — executor MUST commit a clear message naming the new count)
  </acceptance_criteria>
  <done>Both CLAUDE.md and CONCERNS.md reflect the empirical test count of `forgot_password_dialog_test.dart`; the 4 stale `auth_controller(_simple_test).dart` references in CLAUDE.md are scrubbed and replaced with the actual `supabase_auth_provider_test.dart` path plus a forward-pointer to the new `ForgotPasswordController`; D-10 reconciliation step completed before any refactor work.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create ForgotPasswordController + provider</name>
  <files>lib/features/auth/presentation/controllers/forgot_password_controller.dart</files>
  <read_first>
    - lib/features/auth/data/providers/supabase_auth_provider.dart (try/on AuthException/catch/finally pattern at lines 145-165 — the exact shape to mirror)
    - lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart (StateNotifier + immutable state class shape — analog for the new controller per PATTERNS.md `forgot_password_controller.dart` section)
    - lib/features/auth/presentation/widgets/forgot_password_dialog.dart (lines 27-38 — async logic being extracted)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md `forgot_password_controller.dart` (NEW) section
  </read_first>
  <action>
Create exactly ONE file with the following content (adjust import paths if package layout differs):

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Immutable state for the forgot-password flow.
/// Mirrors the QRCustomizationState pattern in
/// lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart
@immutable
class ForgotPasswordState {
  final bool isLoading;
  final bool emailSent;
  final String? errorMessage;

  const ForgotPasswordState({
    this.isLoading = false,
    this.emailSent = false,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    bool? emailSent,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      emailSent: emailSent ?? this.emailSent,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotPasswordState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          emailSent == other.emailSent &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isLoading, emailSent, errorMessage);
}

/// Controller that owns the forgot-password submission state machine.
/// Extracted from forgot_password_dialog.dart per D-08 to break the
/// "Riverpod async state race conditions" flagged in CONCERNS.md.
///
/// Pattern decision (D-09): StateNotifier + immutable state class, matching
/// the existing precedent at qr_customization_controller.dart. No AsyncNotifier
/// example exists in the codebase, and migration is explicitly out of Phase 1
/// scope per CONTEXT.md `<deferred>`.
///
/// Testability: accepts SupabaseClient via constructor; tests inject a
/// MockSupabaseClient (mocktail). Default constructor falls back to
/// SupabaseService.client for production callers.
class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  final SupabaseClient _client;

  ForgotPasswordController({SupabaseClient? client})
      : _client = client ?? SupabaseService.client,
        super(const ForgotPasswordState());

  /// Sends a password-reset email. Mirrors the try/AuthException/catch/finally
  /// shape from supabase_auth_provider.dart:145-165 exactly.
  Future<void> submit(String email) async {
    if (state.isLoading) return; // re-entrancy guard
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'qraft://auth/reset',
      );
      debugPrint('Password reset email sent to: $email');
      state = state.copyWith(isLoading: false, emailSent: true);
    } on AuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset failed: ${e.message}',
      );
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Resets state — used when the dialog reopens after a prior submission.
  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(),
);
```

NOTE: The exact import path for `SupabaseService` may differ. Check `lib/core/services/` for the file and adjust. If `SupabaseService.client` does not expose a public getter, expose one OR import `Supabase.instance.client` instead — the constructor parameter is the testability seam, the default is just for ergonomics.

NOTE: Keep `autoDispose` so closing/reopening the dialog resets the state automatically. This sidesteps the race-condition pitfall in CONCERNS.md without an explicit `reset()` call from the dialog.
  </action>
  <verify>
    <automated>flutter analyze lib/features/auth/presentation/controllers/ 2>&amp;1 | grep -v '^Analyzing' | grep -E '(error|warning)' | wc -l | xargs -I {} test {} -eq 0</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/features/auth/presentation/controllers/forgot_password_controller.dart` exists
    - `grep -c 'class ForgotPasswordController extends StateNotifier' lib/features/auth/presentation/controllers/forgot_password_controller.dart` returns 1
    - `grep -c 'class ForgotPasswordState' lib/features/auth/presentation/controllers/forgot_password_controller.dart` returns 1
    - `grep -c 'on AuthException' lib/features/auth/presentation/controllers/forgot_password_controller.dart` returns 1
    - `grep -c 'forgotPasswordControllerProvider' lib/features/auth/presentation/controllers/forgot_password_controller.dart` returns 1
    - `grep -c 'SupabaseClient? client' lib/features/auth/presentation/controllers/forgot_password_controller.dart` returns 1 (constructor injection seam for tests)
    - `flutter analyze lib/features/auth/presentation/controllers/` exits 0
  </acceptance_criteria>
  <done>ForgotPasswordController exists with StateNotifier + immutable state class shape, mirrors the supabase_auth_provider error-handling pattern exactly, accepts SupabaseClient via constructor for testability, declares its provider, and passes `flutter analyze`.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Refactor dialog to use controller + add Maestro Keys to dialog/login/welcome/scaffold/scanner</name>
  <files>lib/features/auth/presentation/widgets/forgot_password_dialog.dart, lib/features/auth/presentation/pages/login_screen.dart, lib/features/auth/presentation/pages/welcome_screen.dart, lib/features/main/main_scaffold.dart, lib/features/qr_scanner/qr_scanner_screen.dart</files>
  <read_first>
    - lib/features/auth/presentation/widgets/forgot_password_dialog.dart (current dialog — 328 lines, async logic at lines 27-38, success state at lines 246-309)
    - lib/features/auth/presentation/controllers/forgot_password_controller.dart (created in task 2)
    - lib/features/auth/presentation/pages/login_screen.dart (find email field, password field, submit button, forgot-password link)
    - lib/features/auth/presentation/pages/welcome_screen.dart (find login CTA and signup CTA)
    - lib/features/main/main_scaffold.dart (find bottom nav scanner tab)
    - lib/features/qr_scanner/qr_scanner_screen.dart (find scaffold root)
    - .maestro/CONVENTIONS.md (selector naming convention `<feature>_<element>_<role>` — created by plan 02)
  </read_first>
  <action>
**Edit 1: `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` — replace async state with controller**

Replace the local `_emailSent` field, the `_handleSendResetEmail` body, and the loading/success render branches:

```dart
// REMOVE:
bool _emailSent = false;

// REPLACE _handleSendResetEmail body:
void _handleSendResetEmail() async {
  if (_formKey.currentState?.validate() ?? false) {
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text);
  }
}
```

In the `build()` method, add at the top (right after `super.build`):
```dart
final fpState = ref.watch(forgotPasswordControllerProvider);
final isLoading = fpState.isLoading;
final emailSent = fpState.emailSent;
final errorMessage = fpState.errorMessage;
```

Then replace any reference to:
- the old `_emailSent` → `emailSent`
- `authProvider.isLoading` → `isLoading`
- `authProvider.errorMessage` → `errorMessage`

Add the import at the top:
```dart
import '../controllers/forgot_password_controller.dart';
```

**Edit 2: Add stable Keys to the dialog widgets** (PATTERNS.md `forgot_password_dialog.dart` selector list):

- Email `TextFormField` (around line 150) → add `key: const Key('forgot_password_email_field')`
- Cancel `OutlinedButton` (around line 215) → add `key: const Key('forgot_password_cancel_button')`
- Send `PrimaryGlassButton` (around line 237) → add `key: const Key('forgot_password_send_button')`
- Success state container (around lines 246-309) → wrap or set `key: const Key('forgot_password_success_state')`
- Dialog root `AlertDialog` or `Container` → `key: const Key('forgot_password_dialog_root')`

Also wrap the send button in a `Semantics(label: 'Send reset email', child: ...)` so Maestro can find by accessibility label as a backup.

**Edit 3: `lib/features/auth/presentation/pages/login_screen.dart` — add Maestro Keys**

Find the email `TextFormField`, password `TextFormField`, login submit button, and forgot-password link. Add these Keys:

- Email field: `Key('login_email_field')`
- Password field: `Key('login_password_field')`
- Submit button: `Key('login_submit_button')`
- Forgot password link: `Key('login_forgot_password_link')`
- Screen root scaffold: `Key('login_screen_root')`

**Edit 4: `lib/features/auth/presentation/pages/welcome_screen.dart` — add Maestro Keys**

Find the login CTA and signup CTA. Add:

- Login CTA: `Key('welcome_login_cta')`
- Signup CTA: `Key('welcome_signup_cta')`
- Screen root: `Key('welcome_screen_root')`

**Edit 5: `lib/features/main/main_scaffold.dart` — add Maestro Key on scanner tab**

Find the bottom nav scanner tab item (likely `BottomNavigationBarItem` or `NavigationDestination` with `Icons.qr_code_scanner` or similar). Wrap or place a Key on the tappable target so Maestro can find it. Pattern:

If the tab is a `BottomNavigationBarItem`, you cannot put a Key directly on the item. Instead, use a stable `key` on a wrapping widget OR use `Semantics(identifier: 'main_scaffold_scanner_tab', child: ...)` around the tab icon. Pick whichever works for the existing scaffold pattern.

If `main_scaffold.dart` uses a `BottomNavigationBar`, the cleanest path is to wrap the scaffold's body widgets each in a `KeyedSubtree(key: Key('main_scaffold_<tab>_body'))` — but Maestro typically targets the tap target. The simplest reliable pattern: add a key to the icon widget itself. Example:

```dart
BottomNavigationBarItem(
  icon: Icon(Icons.qr_code_scanner, key: const Key('main_scaffold_scanner_tab')),
  label: l10n.scannerTab,
),
```

Choose the variant that matches the existing scaffold structure. Add equivalent keys for the other tabs while you are there (`main_scaffold_home_tab`, `main_scaffold_library_tab`, `main_scaffold_marketplace_tab`, `main_scaffold_profile_tab`) so plan 07 has a full set of selectors.

**Edit 6: `lib/features/qr_scanner/qr_scanner_screen.dart` — add Maestro Key on scaffold root**

The scanner screen's root `Scaffold` (or `Container` if it isn't a Scaffold) must carry `Key('qr_scanner_screen_root')`. Plan 07's `scanner-tab-launch.yaml` flow asserts visibility of this id after permission grant.

```dart
return Scaffold(
  key: const Key('qr_scanner_screen_root'),
  // ...
);
```

**Verify nothing else broke:** run `flutter analyze` and `flutter test test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` — the existing test file may now fail because the dialog state shape changed. **That is expected.** Plan 07 rewrites the test suite. For this plan: fix any non-test compile errors only. Test breakage from contract changes is allowed; compile errors in `lib/` are not.
  </action>
  <verify>
    <automated>flutter analyze lib/ 2>&amp;1 | grep -v '^Analyzing' | grep -E '(error|warning) -' | wc -l | xargs -I {} test {} -eq 0 &amp;&amp; flutter build apk --debug --target-platform android-arm64 2>&amp;1 | tail -3 | grep -q 'Built'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c '_emailSent' lib/features/auth/presentation/widgets/forgot_password_dialog.dart` returns 0 (local boolean removed)
    - `grep -c 'forgotPasswordControllerProvider' lib/features/auth/presentation/widgets/forgot_password_dialog.dart` returns at least 2 (notifier call + watch)
    - `grep -cE "Key\('forgot_password_(email_field|send_button|cancel_button|success_state|dialog_root)'" lib/features/auth/presentation/widgets/forgot_password_dialog.dart` returns at least 4
    - `grep -cE "Key\('login_(email_field|password_field|submit_button|forgot_password_link|screen_root)'" lib/features/auth/presentation/pages/login_screen.dart` returns at least 4
    - `grep -cE "Key\('welcome_(login_cta|signup_cta|screen_root)'" lib/features/auth/presentation/pages/welcome_screen.dart` returns at least 2
    - `grep -c "main_scaffold_scanner_tab" lib/features/main/main_scaffold.dart` returns at least 1
    - `grep -c "qr_scanner_screen_root" lib/features/qr_scanner/qr_scanner_screen.dart` returns at least 1
    - `flutter analyze lib/` exits 0 (zero errors in app code; test errors caused by contract changes are acceptable for this plan and resolved by plan 07)
    - `flutter build apk --debug --target-platform android-arm64` succeeds
  </acceptance_criteria>
  <done>Dialog reads from controller; local `_emailSent` boolean and direct `supabaseAuthProvider` call are gone; 5+ Maestro Keys present across the 5 modified UI files; app code analyzes cleanly; debug build succeeds. Test rewrites are deferred to plan 07.</done>
</task>

</tasks>

<verification>
After all 3 tasks complete:

```bash
# 1. Doc reconciliation visible
grep -E 'verified empirically|pre-refactor' .planning/codebase/CONCERNS.md CLAUDE.md

# 2. auth_controller scrub complete
grep -c 'auth_controller' CLAUDE.md  # must return 0

# 3. Controller exists and is structured correctly
grep -E 'class ForgotPasswordController|class ForgotPasswordState|forgotPasswordControllerProvider' \
  lib/features/auth/presentation/controllers/forgot_password_controller.dart

# 4. Dialog uses controller
grep -E 'forgotPasswordControllerProvider|ref\.watch\(forgotPasswordControllerProvider' \
  lib/features/auth/presentation/widgets/forgot_password_dialog.dart

# 5. All Maestro selectors present
grep -rE "Key\('(forgot_password|login|welcome|main_scaffold|qr_scanner)_" lib/

# 6. Build is clean
flutter analyze
flutter build apk --debug --target-platform android-arm64
flutter build ios --debug --no-codesign
```
</verification>

<success_criteria>
- D-08 satisfied: dialog state lives in `ForgotPasswordController`, not in widget local state
- D-09 satisfied: pattern decision documented in this plan + SUMMARY (StateNotifier + immutable state class, matching qr_customization_controller.dart precedent)
- D-10 satisfied: stale 5/13 figure removed from CLAUDE.md and CONCERNS.md; empirical count recorded; rewrite path delegated to plan 07
- Checker WARNING 4 satisfied: 4 stale `auth_controller(_simple_test).dart` references in CLAUDE.md scrubbed and replaced with `supabase_auth_provider_test.dart` plus a forward-pointer to the new `ForgotPasswordController`
- Plan 07 has every selector it needs to author Maestro flows for: forgot-password, login (valid + invalid), logout, session-persistence, scanner-tab-launch
- App still builds and analyzes cleanly on iOS + Android debug
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-hardening/01-06-SUMMARY.md` documenting:
- Empirical test counts captured in task 1 (X tests, Y failing)
- The pattern decision (StateNotifier + immutable state) and the rationale that landed in this plan
- The complete list of Maestro Keys added across the 5 UI files (table form: file → key)
- The 4 `auth_controller`-related lines scrubbed from CLAUDE.md and what each was replaced with (line-by-line diff summary)
- Confirmation that plan 07 will rewrite tests against the new controller
- Note that the now-broken `forgot_password_dialog_test.dart` is intentionally left broken — plan 07's task 1 rewrites it
</output>
</content>
</invoke>