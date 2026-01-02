import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/env_config.dart';
import '../../domain/entities/purchase_product.dart';
import '../../domain/entities/purchase_error.dart';

/// RevenueCat SDK wrapper - handles all direct SDK interactions
class RevenueCatDataSource {
  bool _isInitialized = false;
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Store listener reference for cleanup
  void Function(CustomerInfo)? _customerInfoListener;

  /// Stream of customer info updates
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize RevenueCat SDK
  Future<void> initialize(String? userId) async {
    if (_isInitialized) {
      debugPrint('RevenueCat: Already initialized');
      return;
    }

    final apiKey = Platform.isIOS
        ? EnvConfig.revenueCatApiKeyIOS
        : EnvConfig.revenueCatApiKeyAndroid;

    if (apiKey.isEmpty) {
      debugPrint('RevenueCat: API key not configured');
      return;
    }

    try {
      final configuration = PurchasesConfiguration(apiKey);

      if (userId != null && userId.isNotEmpty) {
        configuration.appUserID = userId;
      }

      await Purchases.configure(configuration);

      // Listen to customer info updates - store reference for cleanup
      _customerInfoListener = (customerInfo) {
        _customerInfoController.add(customerInfo);
      };
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);

      _isInitialized = true;
      debugPrint('RevenueCat: Initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat: Initialization failed - $e');
      rethrow;
    }
  }

  /// Get available offerings/packages
  Future<List<PurchaseProduct>> getProducts() async {
    _ensureInitialized();

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        debugPrint('RevenueCat: No current offering available');
        return [];
      }

      final products = <PurchaseProduct>[];

      // Get packages in preferred order
      final packageTypes = [
        PackageType.monthly,
        PackageType.annual,
        PackageType.lifetime,
      ];

      for (final packageType in packageTypes) {
        Package? package;

        switch (packageType) {
          case PackageType.monthly:
            package = current.monthly;
          case PackageType.annual:
            package = current.annual;
          case PackageType.lifetime:
            package = current.lifetime;
          default:
            continue;
        }

        if (package != null) {
          products.add(PurchaseProduct.fromPackage(package));
        }
      }

      debugPrint('RevenueCat: Found ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('RevenueCat: Failed to get products - $e');
      rethrow;
    }
  }

  /// Purchase a product
  Future<CustomerInfo> purchasePackage(Package package) async {
    _ensureInitialized();

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      debugPrint('RevenueCat: Purchase successful');
      return customerInfo;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat: Purchase failed - ${e.code}');
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw PurchaseError.fromPurchasesError(errorCode);
    }
  }

  /// Restore previous purchases
  Future<CustomerInfo> restorePurchases() async {
    _ensureInitialized();

    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('RevenueCat: Purchases restored');
      return customerInfo;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat: Restore failed - ${e.code}');
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw PurchaseError.fromPurchasesError(errorCode);
    }
  }

  /// Get current customer info
  Future<CustomerInfo> getCustomerInfo() async {
    _ensureInitialized();

    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat: Failed to get customer info - $e');
      rethrow;
    }
  }

  /// Check if user has active pro entitlement
  Future<bool> hasProAccess() async {
    _ensureInitialized();

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('RevenueCat: Failed to check pro access - $e');
      return false;
    }
  }

  /// Login/identify user
  Future<CustomerInfo> login(String userId) async {
    _ensureInitialized();

    try {
      final result = await Purchases.logIn(userId);
      debugPrint('RevenueCat: User logged in - $userId');
      return result.customerInfo;
    } catch (e) {
      debugPrint('RevenueCat: Login failed - $e');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _ensureInitialized();

    try {
      await Purchases.logOut();
      debugPrint('RevenueCat: User logged out');
    } catch (e) {
      debugPrint('RevenueCat: Logout failed - $e');
      rethrow;
    }
  }

  /// Get current app user ID
  Future<String> getAppUserID() async {
    _ensureInitialized();
    return await Purchases.appUserID;
  }

  /// Set user attributes (email, displayName, phoneNumber)
  /// These are synced to RevenueCat for customer identification
  Future<void> setUserAttributes({
    String? email,
    String? displayName,
    String? phoneNumber,
  }) async {
    if (!_isInitialized) {
      debugPrint('RevenueCat: Cannot set attributes - not initialized');
      return;
    }

    try {
      if (email != null && email.isNotEmpty) {
        await Purchases.setEmail(email);
        debugPrint('RevenueCat: Set email attribute');
      }
      if (displayName != null && displayName.isNotEmpty) {
        await Purchases.setDisplayName(displayName);
        debugPrint('RevenueCat: Set displayName attribute');
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        await Purchases.setPhoneNumber(phoneNumber);
        debugPrint('RevenueCat: Set phoneNumber attribute');
      }
    } catch (e) {
      debugPrint('RevenueCat: Failed to set attributes - $e');
      // Don't rethrow - attribute sync failure shouldn't break the app
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('RevenueCat SDK not initialized. Call initialize() first.');
    }
  }

  /// Dispose resources
  void dispose() {
    // Remove SDK listener to prevent memory leak
    if (_customerInfoListener != null) {
      Purchases.removeCustomerInfoUpdateListener(_customerInfoListener!);
      _customerInfoListener = null;
    }
    _customerInfoController.close();
  }
}
