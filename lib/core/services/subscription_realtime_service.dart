import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/profile/data/providers/profile_stats_providers.dart';

/// Service that listens to real-time subscription changes from Supabase.
/// When the webhook updates subscription status (e.g., EXPIRATION event),
/// this service detects the change and refreshes the app state.
class SubscriptionRealtimeService {
  final SupabaseClient _supabase;
  final Ref _ref;
  RealtimeChannel? _channel;
  String? _currentUserId;

  SubscriptionRealtimeService(this._supabase, this._ref);

  /// Fields that trigger a subscription state refresh when changed
  static const _subscriptionFields = [
    'subscription_plan',
    'subscription_status',
    'subscription_expires_at',
    'subscription_product_id',
    'subscription_period_type',
  ];

  /// Start listening for subscription changes for a specific user
  void startListening(String userId) {
    // Don't re-subscribe if already listening for this user
    if (_currentUserId == userId && _channel != null) {
      debugPrint('SubscriptionRealtime: Already listening for user $userId');
      return;
    }

    // Stop any existing subscription
    stopListening();

    _currentUserId = userId;

    debugPrint('SubscriptionRealtime: Starting listener for user $userId');

    _channel = _supabase
        .channel('user_subscription_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: _onUserUpdated,
        )
        .subscribe((status, error) {
      if (error != null) {
        debugPrint('SubscriptionRealtime: Subscribe error: $error');
      } else {
        debugPrint('SubscriptionRealtime: Subscribe status: $status');
      }
    });
  }

  /// Handle user record updates from Supabase
  void _onUserUpdated(PostgresChangePayload payload) {
    debugPrint('SubscriptionRealtime: Received update event');

    final oldRecord = payload.oldRecord;
    final newRecord = payload.newRecord;

    // Check if any subscription-related field changed
    final hasSubscriptionChange = _subscriptionFields.any((field) {
      final oldValue = oldRecord[field];
      final newValue = newRecord[field];
      final changed = oldValue != newValue;

      if (changed) {
        debugPrint('SubscriptionRealtime: Field "$field" changed: $oldValue -> $newValue');
      }

      return changed;
    });

    if (hasSubscriptionChange) {
      debugPrint('SubscriptionRealtime: Subscription changed! Invalidating userProfileProvider...');
      _ref.invalidate(userProfileProvider);
    } else {
      debugPrint('SubscriptionRealtime: No subscription field changes detected');
    }
  }

  /// Stop listening for changes
  void stopListening() {
    if (_channel != null) {
      debugPrint('SubscriptionRealtime: Stopping listener for user $_currentUserId');
      _supabase.removeChannel(_channel!);
      _channel = null;
      _currentUserId = null;
    }
  }

  /// Dispose the service
  void dispose() {
    stopListening();
  }
}
