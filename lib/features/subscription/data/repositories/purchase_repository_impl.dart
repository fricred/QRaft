import 'package:flutter/foundation.dart';
// purchases_flutter 10.x added its own PurchaseResult, which collides with the
// domain type of the same name defined in purchase_repository.dart. The domain
// one is what this repository's contract returns.
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

import '../../domain/entities/purchase_product.dart';
import '../../domain/entities/purchase_error.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/revenuecat_datasource.dart';

/// Implementation of PurchaseRepository using RevenueCat
class PurchaseRepositoryImpl implements PurchaseRepository {
  final RevenueCatDataSource _dataSource;

  PurchaseRepositoryImpl({
    RevenueCatDataSource? dataSource,
  }) : _dataSource = dataSource ?? RevenueCatDataSource();

  @override
  Future<void> initialize(String? userId) async {
    await _dataSource.initialize(userId);
  }

  @override
  Future<List<PurchaseProduct>> getProducts() async {
    return _dataSource.getProducts();
  }

  @override
  Future<PurchaseResult> purchaseProduct(PurchaseProduct product) async {
    // In debug/simulator mode the mock products have no StoreKit Package.
    // Simulate a successful purchase so the full paywall UX can be tested
    // without App Store Connect products set up.
    if (product.package == null && kDebugMode) {
      debugPrint('RevenueCat: simulating purchase for ${product.id} (debug mode)');
      await Future<void>.delayed(const Duration(seconds: 1));
      return PurchaseResult.success(null);
    }

    if (product.package == null) {
      return PurchaseResult.failure(
        const PurchaseError(
          type: PurchaseErrorType.productNotAvailable,
          message: 'Product package not available',
        ),
      );
    }

    try {
      final customerInfo = await _dataSource.purchasePackage(product.package!);
      return PurchaseResult.success(customerInfo);
    } on PurchaseError catch (error) {
      return PurchaseResult.failure(error);
    } catch (e) {
      return PurchaseResult.failure(
        PurchaseError(
          type: PurchaseErrorType.unknown,
          message: 'An unexpected error occurred',
          debugMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    try {
      final customerInfo = await _dataSource.restorePurchases();
      return PurchaseResult.success(customerInfo);
    } on PurchaseError catch (error) {
      return PurchaseResult.failure(error);
    } catch (e) {
      return PurchaseResult.failure(
        PurchaseError(
          type: PurchaseErrorType.unknown,
          message: 'Failed to restore purchases',
          debugMessage: e.toString(),
        ),
      );
    }
  }

  @override
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await _dataSource.getCustomerInfo();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasProAccess() async {
    return _dataSource.hasProAccess();
  }

  @override
  Stream<CustomerInfo> get customerInfoStream => _dataSource.customerInfoStream;

  @override
  Future<void> logout() async {
    await _dataSource.logout();
  }

  @override
  Future<CustomerInfo> login(String userId) async {
    return _dataSource.login(userId);
  }

  @override
  Future<void> setUserAttributes({
    String? email,
    String? displayName,
    String? phoneNumber,
  }) async {
    await _dataSource.setUserAttributes(
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
    );
  }
}
