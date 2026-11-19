import '../../../../core/utils/friendly_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Supabase Auth Provider - Replaces Firebase Auth
class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecovering = false;
  String? _noticeMessage;
  bool _errorShown = false;
  String? _unconfirmedEmail;

  /// Persisted so a recovery session restored after an app restart still forces the
  /// new-password step (QRAFT-3). Supabase only emits passwordRecovery once.
  static const _recoveryPrefKey = 'auth_recovery_pending';

  static bool _recoveryPendingAtLaunch = false;

  /// Reads the persisted recovery flag. Call once before runApp.
  static Future<void> preloadRecoveryFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recoveryPendingAtLaunch = prefs.getBool(_recoveryPrefKey) ?? false;
    } catch (e) {
      debugPrint('Could not read recovery flag: $e');
    }
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// True after the user opened a password-recovery link and must still choose a new
  /// password (QRAFT-3). While true the app shows the reset screen, not the home screen.
  bool get isRecovering => _isRecovering;

  /// Non-error information for the user (e.g. "confirm your email"), shown once.
  String? get noticeMessage => _noticeMessage;

  /// Email of the last sign-in rejected because it is not confirmed yet (QRAFT-15), so the
  /// UI can offer to resend the confirmation email.
  String? get unconfirmedEmail => _unconfirmedEmail;

  /// Resends the sign-up confirmation email. Returns true when the request was accepted.
  Future<bool> resendConfirmation() async {
    final email = _unconfirmedEmail;
    if (email == null) return false;
    try {
      await _client.auth.resend(type: OtpType.signup, email: email, emailRedirectTo: 'qraft://auth/verify');
      _errorMessage = null; // the old "not confirmed" error is no longer current
      _noticeMessage = deviceIsSpanish()
          ? 'Te reenviamos el correo de confirmación a $email.'
          : 'We sent the confirmation email to $email again.';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Resend confirmation failed: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
      return false;
    }
  }

  /// Returns the current error for a snackbar exactly once, and only after the request
  /// finished. errorMessage itself stays available for inline display (reset screen).
  String? takeErrorForSnackbar() {
    if (_errorMessage == null || _errorShown || _isLoading) return null;
    _errorShown = true;
    return _errorMessage;
  }

  /// Returns the pending notice and clears it without notifying, so a listener shows it
  /// exactly once.
  String? takeNotice() {
    final notice = _noticeMessage;
    _noticeMessage = null;
    return notice;
  }
  
  SupabaseAuthProvider() {
    _initialize();
  }
  
  void _initialize() {
    // Get current user
    _currentUser = _client.auth.currentUser;
    
    // A recovery that was interrupted (app killed) must resume on the reset screen. The
    // flag is preloaded before runApp (see preloadRecoveryFlag) so the very first frame
    // already routes to the reset screen instead of mounting the home screen.
    if (_currentUser != null && _recoveryPendingAtLaunch) {
      _isRecovering = true;
    } else if (_recoveryPendingAtLaunch) {
      // No session survived: a leftover flag must not hijack a later normal sign-in.
      _setRecovering(false);
    }

    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((AuthState data) {
      debugPrint('Supabase Auth State Changed: ${data.event}');
      if (data.event == AuthChangeEvent.passwordRecovery) {
        // Start the reset screen clean: an older login error must not look like a
        // failed reset.
        _errorMessage = null;
        _setRecovering(true);
      } else if (data.event == AuthChangeEvent.signedOut) {
        _setRecovering(false);
      }
      _currentUser = data.session?.user;
      if (data.event == AuthChangeEvent.signedIn && _currentUser != null) {
        _ensureProfile(_currentUser!); // covers deep-link confirmation sessions too
      }
      notifyListeners();
    });
  }

  /// Safety net for the on_auth_user_created trigger, which never blocks sign-up: make
  /// sure the profile row exists. ignoreDuplicates keeps this a no-op normally.
  Future<void> _ensureProfile(User user) async {
    try {
      await _client.from('users').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'display_name': user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'],
      }, onConflict: 'id', ignoreDuplicates: true);
    } catch (e) {
      debugPrint('Warning: could not ensure user profile: $e');
    }
  }

  Future<void> _setRecovering(bool value) async {
    _isRecovering = value;
    if (!value) _recoveryPendingAtLaunch = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_recoveryPrefKey, true);
      } else {
        await prefs.remove(_recoveryPrefKey);
      }
    } catch (e) {
      debugPrint('Could not persist recovery flag: $e');
    }
  }
  
  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
        emailRedirectTo: 'qraft://auth/verify', // Custom deeplink for email verification
      );
      
      // The public.users profile is created server-side by the on_auth_user_created
      // trigger (QRAFT-1), so the client no longer inserts it.
      if (response.session != null) {
        debugPrint('Supabase signup successful: ${response.user?.email}');
        _currentUser = response.user;
      } else if (response.user != null) {
        // Email confirmation is required: there is no session yet, so the user must not
        // enter the app (QRAFT-1 / QRAFT-15). Tell them what to do next.
        debugPrint('Supabase signup pending email confirmation: ${response.user!.email}');
        // Neutral on purpose: for an already-registered email Supabase answers the same
        // way (anti-enumeration), so do not promise an email that may never come.
        _noticeMessage = deviceIsSpanish()
            ? 'Revisa $email. Si es una cuenta nueva, te enviamos un enlace para confirmarla. Si ya tenías cuenta, inicia sesión.'
            : 'Check $email. If this is a new account we sent a confirmation link. If you already had an account, sign in.';
      }

    } on AuthException catch (e) {
      debugPrint('Supabase signup error: ${e.message}');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } catch (e) {
      debugPrint('Unexpected signup error: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('Supabase signin successful: ${response.user!.email}');
        _currentUser = response.user;
        
      }
      
    } on AuthException catch (e) {
      debugPrint('Supabase signin error: ${e.message}');
      _unconfirmedEmail = (e.code == 'email_not_confirmed' ||
              e.message.toLowerCase().contains('email not confirmed'))
          ? email
          : null;
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } catch (e) {
      debugPrint('Unexpected signin error: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      if (!await _boundedSignOut()) {
        throw StateError('Local session could not be cleared');
      }
      _currentUser = null;
      debugPrint('Supabase signout successful');
    } catch (e) {
      debugPrint('Supabase signout error: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } finally {
      _setLoading(false);
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'qraft://auth/reset', // Custom deeplink for password reset
      );
      debugPrint('Password reset email sent to: $email');
      
    } on AuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      _setLoading(true);
      
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoUrl != null) updates['avatar_url'] = photoUrl;
      
      final response = await _client.auth.updateUser(
        UserAttributes(data: updates),
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        debugPrint('Profile updated successfully');
      }
      
    } on AuthException catch (e) {
      debugPrint('Profile update error: ${e.message}');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } catch (e) {
      debugPrint('Unexpected profile update error: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sets the new password after a recovery link (QRAFT-3). Returns true on success.
  Future<bool> completePasswordRecovery(String newPassword) async {
    try {
      _setLoading(true);
      _clearError();
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      // The reset screen unmounts as soon as recovery ends, so confirm via a notice that
      // the signed-in shell shows.
      _noticeMessage = deviceIsSpanish() ? 'Contraseña actualizada.' : 'Password updated.';
      await _setRecovering(false);
      return true;
    } on AuthException catch (e) {
      debugPrint('Password recovery error: ${e.message}');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
      return false;
    } catch (e) {
      debugPrint('Unexpected password recovery error: $e');
      _setError(friendlyAuthMessage(e, spanish: deviceIsSpanish()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Abandons a recovery: signs the temporary recovery session out. The recovery flag is
  /// only cleared once sign-out succeeded, so a failed sign-out can never land the
  /// recovery session in the app without a new password.
  Future<void> cancelPasswordRecovery() async {
    try {
      _setLoading(true);
      _clearError();
      // Only leave the recovery state once the recovery session is really gone;
      // otherwise a restart would restore it straight into the app.
      if (await _boundedSignOut()) {
        await _setRecovering(false);
        _currentUser = null;
      } else {
        _setError(deviceIsSpanish()
            ? 'No pudimos cerrar la sesión. Inténtalo de nuevo.'
            : "We couldn't sign you out. Please try again.");
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Signs out without ever hanging (QRAFT-8). gotrue removes the local session and
  /// emits signedOut before its network call, so a slow or missing network only delays
  /// the server-side revoke, which we stop waiting for after a few seconds.
  Future<bool> _boundedSignOut() async {
    try {
      await _client.auth.signOut().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Sign-out network step did not finish: $e');
    }
    // Success means the local session is really gone, whatever happened on the network.
    return _client.auth.currentSession == null;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    _errorShown = false;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    _unconfirmedEmail = null;
    notifyListeners();
  }
  
  void clearError() {
    _clearError();
  }
}

// Riverpod providers
final supabaseAuthProvider = ChangeNotifierProvider<SupabaseAuthProvider>((ref) {
  return SupabaseAuthProvider();
});

// Auth state provider
final authStateProvider = Provider<User?>((ref) {
  return ref.watch(supabaseAuthProvider).currentUser;
});

// Loading state provider  
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(supabaseAuthProvider).isLoading;
});

// Error state provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(supabaseAuthProvider).errorMessage;
});

// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(supabaseAuthProvider).isAuthenticated;
});