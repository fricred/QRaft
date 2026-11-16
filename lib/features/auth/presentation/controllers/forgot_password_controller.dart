import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Immutable state for the forgot-password flow.
///
/// Mirrors the `QRCustomizationState` pattern at
/// `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart`
/// (StateNotifier + immutable state class). Phase 1 plan 06 explicitly picks
/// this pattern over `AsyncNotifier` per D-09: there is NO `AsyncNotifier`
/// example in the codebase and migration is out of Phase 1 scope.
@immutable
class ForgotPasswordState {
  /// True while a `submit()` call is in flight.
  final bool isLoading;

  /// True once Supabase confirms the reset email was queued.
  final bool emailSent;

  /// Localized-friendly user-facing error string. Null when no error.
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
///
/// Extracted from `lib/features/auth/presentation/widgets/forgot_password_dialog.dart`
/// per Phase 1 D-08 to break the "Riverpod async state race conditions" flagged in
/// `.planning/codebase/CONCERNS.md`. The dialog previously held an `_emailSent`
/// boolean in widget local state and read `authProvider.errorMessage` post-`await`,
/// which created a race window between the underlying `SupabaseAuthProvider`
/// state machine and the dialog's perception of it.
///
/// Pattern decision (D-09): `StateNotifier<ForgotPasswordState>` + immutable
/// state class, mirroring the existing precedent at
/// `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart`.
/// Reasoning:
/// 1. PATTERNS.md note 1: there is NO `AsyncNotifier` example in the codebase
///    (D-09 invites the planner to weigh consistency vs forward-looking).
/// 2. The closest precedent is `qr_customization_controller.dart` — `StateNotifier`
///    + immutable state class is the consistent pattern.
/// 3. Migrating other providers from `StateNotifier` -> `AsyncNotifier` is
///    explicitly listed in CONTEXT.md `<deferred>` as out-of-Phase-1 scope.
/// 4. Phase 1 is foundation hardening — introducing a brand-new pattern just
///    for one controller would create asymmetry without benefit.
///
/// Testability: accepts a `SupabaseClient` via constructor; tests inject a
/// `MockSupabaseClient` (mocktail). Default constructor falls back to
/// `SupabaseService.client` for production callers. Do NOT touch the static
/// `SupabaseService.client` directly inside `submit()` — that would re-introduce
/// the testability blocker D-08 calls out.
class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  final SupabaseClient _client;

  ForgotPasswordController({SupabaseClient? client})
      : _client = client ?? SupabaseService.client,
        super(const ForgotPasswordState());

  /// Sends a password-reset email through Supabase Auth.
  ///
  /// Mirrors the try / `on AuthException` / catch / finally shape from
  /// `supabase_auth_provider.dart:145-165` exactly so the error-handling
  /// surface is consistent across the auth subsystem.
  ///
  /// Re-entrancy guard: returns immediately if a previous call is still in
  /// flight, so double-tapping the send button cannot fire two requests.
  Future<void> submit(String email) async {
    if (state.isLoading) return;
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

  /// Resets state — useful when the dialog reopens after a prior submission.
  ///
  /// `autoDispose` on the provider already does this for free when the dialog
  /// is closed, but the explicit method exists so widget code can opt to
  /// reset without dropping the controller (e.g., in a multi-step flow).
  void reset() {
    state = const ForgotPasswordState();
  }
}

/// Riverpod provider for `ForgotPasswordController`.
///
/// Uses `autoDispose` so closing/reopening the dialog automatically resets
/// the state — sidestepping the race-condition pitfall flagged in CONCERNS.md
/// without requiring an explicit `reset()` call from the dialog.
final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(),
);
