import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConfig {
  static const String deepLinkDomain = 'qraft-e8a1d.firebaseapp.com';
  static const String customScheme = 'qraft';
  
  /// Configure Firebase Auth action code settings for password reset
  static ActionCodeSettings getPasswordResetActionCodeSettings() {
    return ActionCodeSettings(
      // The URL to redirect to after the user clicks the link
      url: 'https://$deepLinkDomain/auth/reset-password',
      
      // This must be true for mobile apps
      handleCodeInApp: true,
      
      // iOS app configuration
      iOSBundleId: 'io.gothcorp.qraft',
      
      // Android app configuration
      androidPackageName: 'io.gothcorp.qraft',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      
      // Custom link domain
      // dynamicLinkDomain: deepLinkDomain, // Deprecated
    );
  }
  
  /// Configure Firebase Auth action code settings for email verification
  static ActionCodeSettings getEmailVerificationActionCodeSettings() {
    return ActionCodeSettings(
      url: 'https://$deepLinkDomain/auth/verify-email',
      handleCodeInApp: true,
      iOSBundleId: 'io.gothcorp.qraft',
      androidPackageName: 'io.gothcorp.qraft',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      // dynamicLinkDomain: deepLinkDomain, // Deprecated
    );
  }
  
  /// Send password reset email with custom action code settings
  static Future<void> sendPasswordResetEmailWithCustomSettings({
    required String email,
  }) async {
    final auth = FirebaseAuth.instance;
    final actionCodeSettings = getPasswordResetActionCodeSettings();
    
    await auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }
  
  /// Verify password reset code
  static Future<bool> verifyPasswordResetCode(String code) async {
    try {
      final auth = FirebaseAuth.instance;
      await auth.verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      // Log error verifying password reset code: $e
      return false;
    }
  }
  
  /// Confirm password reset with new password
  static Future<bool> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      await auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      // Log error confirming password reset: $e
      return false;
    }
  }
  
  /// Parse Firebase Auth link and extract action code
  static String? extractActionCodeFromLink(String link) {
    final uri = Uri.parse(link);
    return uri.queryParameters['oobCode'];
  }
  
  /// Parse Firebase Auth link and extract mode
  static String? extractModeFromLink(String link) {
    final uri = Uri.parse(link);
    return uri.queryParameters['mode'];
  }
}