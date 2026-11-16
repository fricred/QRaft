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
  /// True when this platform's configured key is a RevenueCat Test Store key (`test_…`).
  static bool get isTestStoreKey => !kIsWeb && _platformApiKey.startsWith('test_');

  /// Purchases cannot work in this build: release build with a Test Store key.
  static bool get purchasesUnavailable => kReleaseMode && isTestStoreKey;

  static String get _platformApiKey =>
      Platform.isIOS ? EnvConfig.revenueCatApiKeyIOS : EnvConfig.revenueCatApiKeyAndroid;

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
      // A different user signed in on this device: re-identify, otherwise purchases and
      // entitlements would be recorded against the previous user.
      if (userId != null && userId.isNotEmpty) {
        // If re-identifying fails, do NOT carry on as the previous user: a purchase would
        // be credited to them. Rethrow so purchases stay unavailable for this session.
        // On failure this rethrows: initializeRevenueCat then marks RevenueCat as not
        // ready, so the paywall offers nothing under the previous identity. The SDK and
        // its listener stay intact (no reconfigure, no duplicate listener).
        await Purchases.logIn(userId);
      }
      return;
    }

    final apiKey = _platformApiKey;

    if (apiKey.isEmpty) {
      // Throw so callers never mark an unconfigured SDK as initialized (native crash
      // on the first Purchases call otherwise).
      throw StateError('RevenueCat: API key not configured');
    }

    // QRAFT-2: a Test Store key simulates purchases and generates no revenue. A release
    // build must never sell with it; leave the SDK unconfigured so nothing can be bought
    // and the paywall explains that payments are unavailable.
    if (purchasesUnavailable) {
      // Throw (not return) so callers never mark the SDK as initialized and nothing
      // calls into an unconfigured Purchases singleton.
      throw StateError('RevenueCat: Test Store key refused in a release build');
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
      // purchases_flutter 10.x replaced purchasePackage() with the unified
      // purchase(PurchaseParams) entry point, and returns a PurchaseResult
      // wrapper rather than CustomerInfo directly; callers here only care
      // about the customer info.
      final result = await Purchases.purchase(PurchaseParams.package(package));
      debugPrint('RevenueCat: Purchase successful');
      return result.customerInfo;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat: Purchase failed - ${e.code}');
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      throw PurchaseError.fromPurchasesError(errorCode);
    }
  }

  /// Offering id holding the one-time "dynamic QR" consumable (store id `qraft_dynamic_qr`).
  /// Kept out of the current (Pro) offering, so the paywall never lists it.
  static const dynamicQrOfferingId = 'dynamic_qr';

  /// The dynamic QR package (for its localized price), or null when not configured.
  Future<Package?> getDynamicQrPackage() async {
    _ensureInitialized();
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(dynamicQrOfferingId);
      return offering?.availablePackages.firstOrNull;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat: dynamic QR offering failed - ${e.code}');
      return null;
    }
  }

  /// Buys one dynamic QR. Returns the store transaction id so the server can link this
  /// exact purchase to the code it was bought for. Throws [PurchaseError] (type `pending`
  /// for cash / carrier payments the store hasn't confirmed yet).
  Future<String?> purchaseDynamicQr(Package package) async {
    _ensureInitialized();
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.storeTransaction.transactionIdentifier;
    } on PlatformException catch (e) {
      debugPrint('RevenueCat: dynamic QR purchase failed - ${e.code}');
      throw PurchaseError.fromPurchasesError(PurchasesErrorHelper.getErrorCode(e));
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
