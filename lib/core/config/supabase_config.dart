import 'env_config.dart';

class SupabaseConfig {
  /// Get Supabase URL from EnvConfig (handles .env and dart-define)
  static String get supabaseUrl => EnvConfig.supabaseUrl;
  
  /// Get Supabase Anon Key from EnvConfig (handles .env and dart-define)
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  
  /// Get Supabase Service Key from EnvConfig (bypasses RLS)
  static String get supabaseServiceKey => EnvConfig.supabaseServiceKey;
  
  // Database table names
  static const String usersTable = 'users';
  static const String qrCodesTable = 'qr_codes';
  static const String templatesTable = 'templates';
  static const String scanHistoryTable = 'scan_history';
  static const String productsTable = 'products';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
}