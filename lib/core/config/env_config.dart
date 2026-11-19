import 'package:flutter/foundation.dart';

/// Flutter 2025 Best Practice: Using dart-define for secure environment variables
/// 
/// Usage:
/// Development: flutter run --dart-define-from-file=env.json
/// Production: flutter build --dart-define-from-file=env.production.json
class EnvConfig {
  /// Get Supabase URL from dart-define
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  /// Get Supabase Anon Key from dart-define
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY', 
    defaultValue: 'your-anon-key-here',
  );
  
  /// RevenueCat API Key for iOS
  static const String revenueCatApiKeyIOS = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: '',
  );

  /// RevenueCat API Key for Android
  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: '',
  );

  /// Check if RevenueCat is properly configured
  static bool get isRevenueCatConfigured {
    return revenueCatApiKeyIOS.isNotEmpty || revenueCatApiKeyAndroid.isNotEmpty;
  }

  /// Check if Supabase is properly configured
  static bool get isSupabaseConfigured {
    return !supabaseUrl.contains('your-project') && 
           !supabaseAnonKey.contains('your-anon-key');
  }
  
  /// Get configuration status for debugging
  static Map<String, dynamic> get configStatus {
    return {
      'isSupabaseConfigured': isSupabaseConfigured,
      'supabaseUrl': supabaseUrl,
      'supabaseKeyLength': supabaseAnonKey.length,
      'usingDartDefine': true,
    };
  }
  
  /// Print configuration status (for development debugging)
  static void debugConfig() {
    if (kDebugMode) {
      debugPrint('🔧 Environment Configuration:');
      debugPrint('   Supabase configured: $isSupabaseConfigured');
      debugPrint('   Supabase URL: $supabaseUrl');
      debugPrint('   Supabase Key length: ${supabaseAnonKey.length}');
      
      if (!isSupabaseConfigured) {
        debugPrint('⚠️  Use: flutter run --dart-define-from-file=env.json');
      } else {
        debugPrint('✅ Environment properly configured');
      }
    }
  }
}