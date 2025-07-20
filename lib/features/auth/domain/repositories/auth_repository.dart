import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;
  
  /// Get current user
  UserEntity? get currentUser;
  
  /// Sign in with email and password
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  /// Create user with email and password
  Future<UserEntity> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });
  
  /// Sign out
  Future<void> signOut();
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email});
  
  /// Send email verification
  Future<void> sendEmailVerification();
  
  /// Reload user data
  Future<void> reloadUser();
  
  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  });
}