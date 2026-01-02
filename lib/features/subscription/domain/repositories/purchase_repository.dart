import 'package:purchases_flutter/purchases_flutter.dart';
import '../entities/purchase_product.dart';
import '../entities/purchase_error.dart';

/// Result of a purchase operation
class PurchaseResult {
  final bool success;
  final CustomerInfo? customerInfo;
  final PurchaseError? error;

  const PurchaseResult._({
    required this.success,
    this.customerInfo,
    this.error,
  });

  factory PurchaseResult.success(CustomerInfo customerInfo) => PurchaseResult._(
        success: true,
        customerInfo: customerInfo,
      );

  factory PurchaseResult.failure(PurchaseError error) => PurchaseResult._(
        success: false,
        error: error,
      );
}

/// Abstract repository for purchase operations
abstract class PurchaseRepository {
  /// Initialize the purchase system with user ID
  Future<void> initialize(String? userId);

  /// Get available products for purchase
  Future<List<PurchaseProduct>> getProducts();

  /// Purchase a product
  Future<PurchaseResult> purchaseProduct(PurchaseProduct product);

  /// Restore previous purchases
  Future<PurchaseResult> restorePurchases();

  /// Get current customer subscription info
  Future<CustomerInfo?> getCustomerInfo();

  /// Check if user has active Pro entitlement
  Future<bool> hasProAccess();

  /// Listen to customer info changes
  Stream<CustomerInfo> get customerInfoStream;

  /// Logout the current user (clears cached customer info)
  Future<void> logout();

  /// Login/identify a user
  Future<CustomerInfo> login(String userId);

  /// Set user attributes for customer identification in RevenueCat
  Future<void> setUserAttributes({
    String? email,
    String? displayName,
    String? phoneNumber,
  });
}
