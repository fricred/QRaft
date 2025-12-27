import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase has not been initialized or configured. Check your environment variables.');
    }
    return _client!;
  }
  
  static bool get isInitialized => _client != null;
  
  static Future<void> initialize() async {
    debugPrint('Initializing Supabase...');
    debugPrint('Supabase URL: ${SupabaseConfig.supabaseUrl}');
    debugPrint('Supabase Key: ${SupabaseConfig.supabaseAnonKey.substring(0, 10)}...');
    
    // Only initialize if we have valid config
    if (SupabaseConfig.supabaseUrl.contains('your-project') || 
        SupabaseConfig.supabaseAnonKey.contains('your-anon-key')) {
      debugPrint('Supabase configuration not set, skipping initialization');
      return;
    }
    
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');
      
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
      // Supabase already initialized or configuration error
      try {
        _client = Supabase.instance.client;
        debugPrint('Using existing Supabase instance');
      } catch (_) {
        debugPrint('Failed to get Supabase instance');
      }
    }
  }
  
  // User Profile Operations
  static Future<Map<String, dynamic>?> getCurrentUserProfile({User? specificUser}) async {
    try {
      final user = specificUser ?? client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found in getCurrentUserProfile');
        return null;
      }
      
      debugPrint('🔍 Getting user profile for: ${user.email} (ID: ${user.id})');
      final response = await client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      debugPrint('📊 User profile response: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  /// Get user profile by ID (for backwards compatibility)
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return getCurrentUserProfile();
  }
  
  /// Create user profile for current authenticated user
  static Future<void> createCurrentUserProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    String? company,
    String? jobTitle,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
    User? specificUser, // Optional user parameter for when currentUser might be stale
  }) async {
    try {
      final user = specificUser ?? client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found in SupabaseService.createCurrentUserProfile');
        throw Exception('No authenticated user found');
      }
      
      debugPrint('✅ Creating profile for user: ${user.email} (ID: ${user.id})');
      
      final profileData = {
        'id': user.id,
        'email': user.email ?? '',
        'display_name': displayName ?? user.userMetadata?['display_name'],
        'photo_url': photoUrl ?? user.userMetadata?['avatar_url'],
        'phone_number': phoneNumber,
        'bio': bio,
        'location': location,
        'website': website,
        'company': company,
        'job_title': jobTitle,
        'preferences': preferences ?? {},
        'statistics': statistics ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Creating user profile with data: $profileData');
      await client.from(SupabaseConfig.usersTable).insert(profileData);
      debugPrint('User profile created successfully in Supabase');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    String? company,
    String? jobTitle,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
  }) async {
    return createCurrentUserProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
      bio: bio,
      location: location,
      website: website,
      company: company,
      jobTitle: jobTitle,
      preferences: preferences,
      statistics: statistics,
    );
  }
  
  /// Update current user's profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    String? company,
    String? jobTitle,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Only include non-null values
      if (displayName != null) updateData['display_name'] = displayName;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (website != null) updateData['website'] = website;
      if (company != null) updateData['company'] = company;
      if (jobTitle != null) updateData['job_title'] = jobTitle;
      if (preferences != null) updateData['preferences'] = preferences;
      if (statistics != null) updateData['statistics'] = statistics;
      
      debugPrint('Updating user profile for: ${user.id}');
      await client.from(SupabaseConfig.usersTable)
          .update(updateData)
          .eq('id', user.id);
      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Legacy method for compatibility - now uses current user
  static Future<void> updateUserProfileLegacy({
    required String userId,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? location,
    String? website,
    String? company,
    String? jobTitle,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
  }) async {
    return updateUserProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
      bio: bio,
      location: location,
      website: website,
      company: company,
      jobTitle: jobTitle,
      preferences: preferences,
      statistics: statistics,
    );
  }
  
  // QR Code Operations
  /// Get current user's QR codes
  static Future<List<Map<String, dynamic>>> getCurrentUserQRCodes() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      final response = await client
          .from(SupabaseConfig.qrCodesTable)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get QR codes: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<List<Map<String, dynamic>>> getUserQRCodes(String userId) async {
    return getCurrentUserQRCodes();
  }
  
  /// Save QR code for current user
  static Future<String> saveCurrentUserQRCode({
    required String qrType,
    required String content,
    required String qrData,
    String? title,
    String? description,
    Map<String, dynamic>? customization,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      final response = await client
          .from(SupabaseConfig.qrCodesTable)
          .insert({
            'user_id': user.id,
            'qr_type': qrType,
            'content': content,
            'qr_data': qrData,
            'title': title,
            'description': description,
            'customization': customization,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return response['id'];
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<String> saveQRCode({
    required String userId,
    required String qrType,
    required String content,
    required String qrData,
    String? title,
    String? description,
    Map<String, dynamic>? customization,
  }) async {
    return saveCurrentUserQRCode(
      qrType: qrType,
      content: content,
      qrData: qrData,
      title: title,
      description: description,
      customization: customization,
    );
  }
  
  static Future<void> deleteQRCode(String qrCodeId) async {
    try {
      await client
          .from(SupabaseConfig.qrCodesTable)
          .delete()
          .eq('id', qrCodeId);
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }
  
  // Scan History Operations
  /// Save scan history for current user
  static Future<void> saveCurrentUserScanHistory({
    required String qrType,
    required String content,
    required String scannedData,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      await client.from(SupabaseConfig.scanHistoryTable).insert({
        'user_id': user.id,
        'qr_type': qrType,
        'content': content,
        'scanned_data': scannedData,
        'scanned_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save scan history: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<void> saveScanHistory({
    required String userId,
    required String qrType,
    required String content,
    required String scannedData,
  }) async {
    return saveCurrentUserScanHistory(
      qrType: qrType,
      content: content,
      scannedData: scannedData,
    );
  }
  
  /// Get current user's scan history
  static Future<List<Map<String, dynamic>>> getCurrentUserScanHistory() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      final response = await client
          .from(SupabaseConfig.scanHistoryTable)
          .select()
          .eq('user_id', user.id)
          .order('scanned_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get scan history: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<List<Map<String, dynamic>>> getUserScanHistory(String userId) async {
    return getCurrentUserScanHistory();
  }

  // QR Scanner Operations - New methods for enhanced scanner
  /// Save scan result using new ScanResult model
  static Future<void> saveScanResult(scanResult) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      final scanData = {
        'id': scanResult.id,
        'user_id': user.id,
        'raw_value': scanResult.rawValue,  
        'qr_type': scanResult.toJson()['type'], // Use the toJson method which has the fix
        'display_value': scanResult.displayValue,
        'parsed_data': scanResult.parsedData,
        'scanned_at': scanResult.scannedAt.toIso8601String(),
      };
      
      await client.from(SupabaseConfig.scanHistoryTable).insert(scanData);
      debugPrint('✅ Saved scan result: ${scanResult.displayValue}');
    } catch (e) {
      debugPrint('❌ Failed to save scan result: $e');
      throw Exception('Failed to save scan result: $e');
    }
  }
  
  /// Get scan history as ScanResult objects
  /// [limit] controls how many items to fetch (-1 for unlimited, defaults to 100)
  static Future<List<dynamic>> getScanHistory({int limit = 100}) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final queryLimit = limit == -1 ? 1000 : limit; // -1 means unlimited (cap at 1000)

      final response = await client
          .from(SupabaseConfig.scanHistoryTable)
          .select()
          .eq('user_id', user.id)
          .order('scanned_at', ascending: false)
          .limit(queryLimit);
      
      // Convert to ScanResult objects
      return response.map((data) {
        // Import ScanResult dynamically to avoid circular imports
        return {
          'id': data['id'],
          'rawValue': data['raw_value'],
          'type': data['qr_type'],
          'displayValue': data['display_value'],
          'parsedData': data['parsed_data'],
          'scannedAt': data['scanned_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get scan history: $e');
      throw Exception('Failed to get scan history: $e');
    }
  }
  
  /// Delete specific scan result
  static Future<void> deleteScanResult(String scanId) async {
    try {
      await client
          .from(SupabaseConfig.scanHistoryTable)
          .delete()
          .eq('id', scanId);
      debugPrint('✅ Deleted scan result: $scanId');
    } catch (e) {
      debugPrint('❌ Failed to delete scan result: $e');
      throw Exception('Failed to delete scan result: $e');
    }
  }
  
  /// Clear all scan history for current user
  static Future<void> clearScanHistory() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      await client
          .from(SupabaseConfig.scanHistoryTable)
          .delete()
          .eq('user_id', user.id);
      debugPrint('✅ Cleared all scan history');
    } catch (e) {
      debugPrint('❌ Failed to clear scan history: $e');
      throw Exception('Failed to clear scan history: $e');
    }
  }
  
  // Template Operations
  static Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await client
          .from(SupabaseConfig.templatesTable)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get templates: $e');
    }
  }
  
  // Marketplace Operations
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await client
          .from(SupabaseConfig.productsTable)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }
  
  /// Create order for current user
  static Future<String> createCurrentUserOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    Map<String, dynamic>? shippingAddress,
    Map<String, dynamic>? customization,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      // Create order
      final orderResponse = await client
          .from(SupabaseConfig.ordersTable)
          .insert({
            'user_id': user.id,
            'status': 'pending',
            'total_amount': totalAmount,
            'shipping_address': shippingAddress,
            'customization': customization,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      
      final orderId = orderResponse['id'];
      
      // Create order items
      final orderItems = items.map((item) => {
        ...item,
        'order_id': orderId,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      
      await client
          .from(SupabaseConfig.orderItemsTable)
          .insert(orderItems);
      
      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<String> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    Map<String, dynamic>? shippingAddress,
    Map<String, dynamic>? customization,
  }) async {
    return createCurrentUserOrder(
      items: items,
      totalAmount: totalAmount,
      shippingAddress: shippingAddress,
      customization: customization,
    );
  }
  
  /// Get current user's orders
  static Future<List<Map<String, dynamic>>> getCurrentUserOrders() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }
      
      final response = await client
          .from(SupabaseConfig.ordersTable)
          .select('*, ${SupabaseConfig.orderItemsTable}(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }
  
  /// Legacy method for compatibility
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    return getCurrentUserOrders();
  }
}