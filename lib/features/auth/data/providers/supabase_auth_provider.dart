import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Supabase Auth Provider - Replaces Firebase Auth
class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  SupabaseAuthProvider() {
    _initialize();
  }
  
  void _initialize() {
    // Get current user
    _currentUser = _client.auth.currentUser;
    
    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((AuthState data) {
      debugPrint('Supabase Auth State Changed: ${data.event}');
      _currentUser = data.session?.user;
      notifyListeners();
    });
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
      
      if (response.user != null) {
        debugPrint('Supabase signup successful: ${response.user!.email}');
        _currentUser = response.user;
        
        // Create user profile in database after successful registration
        try {
          debugPrint('Creating user profile in database...');
          await SupabaseService.createCurrentUserProfile(
            displayName: displayName,
            specificUser: response.user, // Pass the user object to avoid timing issues
          );
          debugPrint('User profile created successfully');
        } catch (profileError) {
          debugPrint('Warning: Failed to create user profile: $profileError');
          // Don't throw error here - user is registered, profile creation can be retried
        }
      }
      
    } on AuthException catch (e) {
      debugPrint('Supabase signup error: ${e.message}');
      _setError('Signup failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected signup error: $e');
      _setError('An unexpected error occurred during signup');
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
        
        // Check if user profile exists, create if missing
        try {
          final existingProfile = await SupabaseService.getCurrentUserProfile(
            specificUser: response.user, // Pass the user object to avoid timing issues
          );
          if (existingProfile == null) {
            debugPrint('No profile found for existing user, creating...');
            await SupabaseService.createCurrentUserProfile(
              displayName: response.user!.userMetadata?['display_name'],
              specificUser: response.user, // Pass the user object to avoid timing issues
            );
            debugPrint('Profile created for existing user');
          }
        } catch (profileError) {
          debugPrint('Warning: Could not check/create profile: $profileError');
        }
      }
      
    } on AuthException catch (e) {
      debugPrint('Supabase signin error: ${e.message}');
      _setError('Login failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected signin error: $e');
      _setError('An unexpected error occurred during login');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _client.auth.signOut();
      _currentUser = null;
      debugPrint('Supabase signout successful');
    } catch (e) {
      debugPrint('Supabase signout error: $e');
      _setError('Failed to sign out');
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
      _setError('Password reset failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected password reset error: $e');
      _setError('An unexpected error occurred');
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
      _setError('Profile update failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected profile update error: $e');
      _setError('An unexpected error occurred');
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
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