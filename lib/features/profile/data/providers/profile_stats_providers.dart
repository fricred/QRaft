import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';

/// Supabase-only providers for profile statistics
/// These providers only work when a user is authenticated

// Provider for user's QR codes
final userQRCodesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authProvider = ref.watch(supabaseAuthProvider);
  
  // Only fetch if user is authenticated and Supabase is initialized
  if (authProvider.currentUser == null || !SupabaseService.isInitialized) {
    return <Map<String, dynamic>>[];
  }
  
  try {
    return await SupabaseService.getCurrentUserQRCodes();
  } catch (e) {
    // Return empty list on error to avoid breaking the UI
    return <Map<String, dynamic>>[];
  }
});

// Provider for user's scan history
final userScanHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authProvider = ref.watch(supabaseAuthProvider);
  
  // Only fetch if user is authenticated and Supabase is initialized
  if (authProvider.currentUser == null || !SupabaseService.isInitialized) {
    return <Map<String, dynamic>>[];
  }
  
  try {
    return await SupabaseService.getCurrentUserScanHistory();
  } catch (e) {
    // Return empty list on error to avoid breaking the UI
    return <Map<String, dynamic>>[];
  }
});

// Provider for user's orders
final userOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authProvider = ref.watch(supabaseAuthProvider);
  
  // Only fetch if user is authenticated and Supabase is initialized
  if (authProvider.currentUser == null || !SupabaseService.isInitialized) {
    return <Map<String, dynamic>>[];
  }
  
  try {
    return await SupabaseService.getCurrentUserOrders();
  } catch (e) {
    // Return empty list on error to avoid breaking the UI
    return <Map<String, dynamic>>[];
  }
});

// Provider for templates (public data)
final templatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!SupabaseService.isInitialized) {
    return <Map<String, dynamic>>[];
  }
  
  try {
    return await SupabaseService.getTemplates();
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
});

// Provider for marketplace products (public data)
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!SupabaseService.isInitialized) {
    return <Map<String, dynamic>>[];
  }
  
  try {
    return await SupabaseService.getProducts();
  } catch (e) {
    return <Map<String, dynamic>>[];
  }
});

// Provider for user profile from Supabase
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authProvider = ref.watch(supabaseAuthProvider);
  
  if (authProvider.currentUser == null || !SupabaseService.isInitialized) {
    return null;
  }
  
  try {
    return await SupabaseService.getCurrentUserProfile(specificUser: authProvider.currentUser);
  } catch (e) {
    return null;
  }
});