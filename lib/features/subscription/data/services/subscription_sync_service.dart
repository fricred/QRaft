import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Service to sync RevenueCat subscription data with Supabase
class SubscriptionSyncService {
  final SupabaseClient _supabase;
  StreamSubscription<CustomerInfo>? _customerInfoSubscription;

  SubscriptionSyncService({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  /// Start listening to subscription changes and sync with Supabase
  void startListening(Stream<CustomerInfo> customerInfoStream) {
    _customerInfoSubscription?.cancel();
    _customerInfoSubscription = customerInfoStream.listen(
      _onCustomerInfoUpdated,
      onError: (error) {
        debugPrint('SubscriptionSync: Stream error - $error');
      },
    );
  }

  /// Stop listening to subscription changes
  void stopListening() {
    _customerInfoSubscription?.cancel();
    _customerInfoSubscription = null;
  }

  /// Handle customer info update from RevenueCat
  Future<void> _onCustomerInfoUpdated(CustomerInfo customerInfo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('SubscriptionSync: No authenticated user, skipping sync');
        return;
      }

      await syncSubscription(userId, customerInfo);
    } catch (e) {
      debugPrint('SubscriptionSync: Failed to sync - $e');
    }
  }

  /// Asks the server to re-read this user's plan from RevenueCat and store it.
  ///
  /// The plan columns of `users` can only be written server-side (trigger
  /// protect_subscription_columns), so the app never writes them directly: the
  /// `sync-subscription` edge function verifies the entitlement with RevenueCat's API.
  /// The app picks up the change through the users realtime listener.
  Future<void> syncSubscription(String userId, CustomerInfo customerInfo) async {
    final res = await _supabase.functions.invoke('sync-subscription');
    debugPrint('SubscriptionSync: server sync for $userId -> ${res.status} ${res.data}');
    // The server reads RevenueCat at most once every ~20s per user. If this call was
    // throttled (e.g. right after a purchase), re-check once the window has passed so
    // the new state isn't missed even if the webhook is slow.
    final data = res.data;
    if (data is Map && data['throttled'] == true) {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 21), () async {
        if (_supabase.auth.currentUser?.id != userId) return;
        try {
          await _supabase.functions.invoke('sync-subscription');
        } catch (e) {
          debugPrint('SubscriptionSync: retry failed - $e');
        }
      });
    }
  }

  Timer? _retryTimer;

  /// Force sync current subscription state
  Future<void> forceSync() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final customerInfo = await Purchases.getCustomerInfo();
      await syncSubscription(userId, customerInfo);
    } catch (e) {
      debugPrint('SubscriptionSync: Force sync failed - $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    stopListening();
  }
}
