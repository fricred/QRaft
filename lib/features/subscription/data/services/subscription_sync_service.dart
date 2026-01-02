import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/subscription_plan.dart';

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

  /// Sync subscription data to Supabase
  Future<void> syncSubscription(String userId, CustomerInfo customerInfo) async {
    final hasProAccess = customerInfo.entitlements.active.containsKey('pro');
    final proEntitlement = customerInfo.entitlements.all['pro'];

    // Determine subscription tier
    SubscriptionTier tier;
    SubscriptionStatus status;
    String? productId;
    SubscriptionPeriod? periodType;
    DateTime? expiresAt;
    DateTime? purchaseDate;

    if (hasProAccess && proEntitlement != null) {
      tier = SubscriptionTier.pro;
      status = _mapEntitlementStatus(proEntitlement);
      productId = proEntitlement.productIdentifier;
      periodType = _mapPeriodType(proEntitlement.productIdentifier);

      if (proEntitlement.expirationDate != null) {
        expiresAt = DateTime.parse(proEntitlement.expirationDate!);
      }

      purchaseDate = DateTime.parse(proEntitlement.latestPurchaseDate);
    } else {
      tier = SubscriptionTier.free;
      status = SubscriptionStatus.active;
    }

    // Update Supabase
    final updateData = {
      'subscription_plan': tier.name,
      'subscription_status': _statusToString(status),
      'subscription_expires_at': expiresAt?.toIso8601String(),
      'subscription_product_id': productId,
      'subscription_period_type': periodType?.name,
      'original_purchase_date': purchaseDate?.toIso8601String(),
      'revenuecat_customer_id': customerInfo.originalAppUserId,
      'last_verified_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from('users')
        .update(updateData)
        .eq('id', userId);

    debugPrint('SubscriptionSync: Updated user $userId - tier: ${tier.name}, status: ${status.name}');
  }

  /// Map RevenueCat entitlement to subscription status
  SubscriptionStatus _mapEntitlementStatus(EntitlementInfo entitlement) {
    if (entitlement.willRenew) {
      return SubscriptionStatus.active;
    }

    if (entitlement.unsubscribeDetectedAt != null) {
      return SubscriptionStatus.cancelled;
    }

    if (entitlement.billingIssueDetectedAt != null) {
      return SubscriptionStatus.billingIssue;
    }

    // Check if expired
    if (entitlement.expirationDate != null) {
      final expiry = DateTime.parse(entitlement.expirationDate!);
      if (DateTime.now().isAfter(expiry)) {
        return SubscriptionStatus.expired;
      }
    }

    return SubscriptionStatus.active;
  }

  /// Map product ID to period type
  SubscriptionPeriod? _mapPeriodType(String productId) {
    if (productId.contains('monthly')) {
      return SubscriptionPeriod.monthly;
    } else if (productId.contains('annual') || productId.contains('yearly')) {
      return SubscriptionPeriod.annual;
    } else if (productId.contains('lifetime')) {
      return SubscriptionPeriod.lifetime;
    }
    return null;
  }

  /// Convert status enum to database string
  String _statusToString(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.trial:
        return 'trial';
      case SubscriptionStatus.billingIssue:
        return 'billing_issue';
    }
  }

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
    stopListening();
  }
}
