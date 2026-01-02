import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/subscription_realtime_service.dart';
import '../../data/datasources/revenuecat_datasource.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../data/services/subscription_sync_service.dart';
import '../../domain/entities/purchase_product.dart';
import '../../domain/entities/purchase_error.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../../profile/data/providers/profile_stats_providers.dart';

/// Provider for RevenueCat data source (singleton)
final revenueCatDataSourceProvider = Provider<RevenueCatDataSource>((ref) {
  final dataSource = RevenueCatDataSource();
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});

/// Provider for purchase repository
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final dataSource = ref.watch(revenueCatDataSourceProvider);
  return PurchaseRepositoryImpl(dataSource: dataSource);
});

/// Provider for subscription sync service
final subscriptionSyncServiceProvider = Provider<SubscriptionSyncService>((ref) {
  final dataSource = ref.watch(revenueCatDataSourceProvider);
  final syncService = SubscriptionSyncService();

  // Start listening to customer info changes
  syncService.startListening(dataSource.customerInfoStream);

  ref.onDispose(() => syncService.dispose());
  return syncService;
});

/// Provider for subscription realtime service (listens to Supabase changes)
final subscriptionRealtimeServiceProvider = Provider<SubscriptionRealtimeService>((ref) {
  final service = SubscriptionRealtimeService(
    Supabase.instance.client,
    ref,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for available purchase products
final purchaseProductsProvider = FutureProvider<List<PurchaseProduct>>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.getProducts();
});

/// Provider for monthly product
final monthlyProductProvider = Provider<PurchaseProduct?>((ref) {
  final productsAsync = ref.watch(purchaseProductsProvider);
  return productsAsync.whenOrNull(
    data: (products) => products.where((p) => p.type == ProductType.monthly).firstOrNull,
  );
});

/// Provider for annual product
final annualProductProvider = Provider<PurchaseProduct?>((ref) {
  final productsAsync = ref.watch(purchaseProductsProvider);
  return productsAsync.whenOrNull(
    data: (products) => products.where((p) => p.type == ProductType.annual).firstOrNull,
  );
});

/// Provider for lifetime product
final lifetimeProductProvider = Provider<PurchaseProduct?>((ref) {
  final productsAsync = ref.watch(purchaseProductsProvider);
  return productsAsync.whenOrNull(
    data: (products) => products.where((p) => p.type == ProductType.lifetime).firstOrNull,
  );
});

/// Provider for annual savings percentage
final annualSavingsProvider = Provider<int?>((ref) {
  final annual = ref.watch(annualProductProvider);
  final monthly = ref.watch(monthlyProductProvider);

  if (annual == null || monthly == null) return null;
  return annual.calculateSavingsPercent(monthly);
});

/// Provider for RevenueCat customer info stream
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  final dataSource = ref.watch(revenueCatDataSourceProvider);
  return dataSource.customerInfoStream;
});

/// Provider for current customer info
final customerInfoProvider = FutureProvider<CustomerInfo?>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.getCustomerInfo();
});

/// Provider to check if user has pro access via RevenueCat
final hasRevenueCatProAccessProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.hasProAccess();
});

/// Purchase state for handling purchase operations
enum PurchaseState { idle, loading, success, error }

/// State notifier for purchase operations
class PurchaseController extends StateNotifier<PurchaseControllerState> {
  final PurchaseRepository _repository;
  final SubscriptionSyncService _syncService;
  final void Function()? _onSubscriptionChanged;

  PurchaseController({
    required PurchaseRepository repository,
    required SubscriptionSyncService syncService,
    void Function()? onSubscriptionChanged,
  })  : _repository = repository,
        _syncService = syncService,
        _onSubscriptionChanged = onSubscriptionChanged,
        super(const PurchaseControllerState());

  /// Purchase a product
  Future<bool> purchase(PurchaseProduct product) async {
    state = state.copyWith(
      purchaseState: PurchaseState.loading,
      error: null,
    );

    final result = await _repository.purchaseProduct(product);

    if (result.success) {
      // Sync with Supabase
      await _syncService.forceSync();

      // Notify listeners to refresh subscription state
      _onSubscriptionChanged?.call();

      state = state.copyWith(
        purchaseState: PurchaseState.success,
        lastPurchasedProduct: product,
      );
      return true;
    } else {
      state = state.copyWith(
        purchaseState: PurchaseState.error,
        error: result.error,
      );
      return false;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    state = state.copyWith(
      restoreState: PurchaseState.loading,
      error: null,
    );

    final result = await _repository.restorePurchases();

    if (result.success) {
      // Sync with Supabase
      await _syncService.forceSync();

      // Notify listeners to refresh subscription state
      _onSubscriptionChanged?.call();

      state = state.copyWith(restoreState: PurchaseState.success);
      return true;
    } else {
      state = state.copyWith(
        restoreState: PurchaseState.error,
        error: result.error,
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const PurchaseControllerState();
  }
}

/// State for purchase controller
class PurchaseControllerState {
  final PurchaseState purchaseState;
  final PurchaseState restoreState;
  final PurchaseError? error;
  final PurchaseProduct? lastPurchasedProduct;

  const PurchaseControllerState({
    this.purchaseState = PurchaseState.idle,
    this.restoreState = PurchaseState.idle,
    this.error,
    this.lastPurchasedProduct,
  });

  bool get isPurchasing => purchaseState == PurchaseState.loading;
  bool get isRestoring => restoreState == PurchaseState.loading;
  bool get isLoading => isPurchasing || isRestoring;

  PurchaseControllerState copyWith({
    PurchaseState? purchaseState,
    PurchaseState? restoreState,
    PurchaseError? error,
    PurchaseProduct? lastPurchasedProduct,
  }) {
    return PurchaseControllerState(
      purchaseState: purchaseState ?? this.purchaseState,
      restoreState: restoreState ?? this.restoreState,
      error: error,
      lastPurchasedProduct: lastPurchasedProduct ?? this.lastPurchasedProduct,
    );
  }
}

/// Provider for purchase controller
final purchaseControllerProvider =
    StateNotifierProvider<PurchaseController, PurchaseControllerState>((ref) {
  final repository = ref.watch(purchaseRepositoryProvider);
  final syncService = ref.watch(subscriptionSyncServiceProvider);

  return PurchaseController(
    repository: repository,
    syncService: syncService,
    onSubscriptionChanged: () {
      // Invalidate profile to refresh subscription data from Supabase
      ref.invalidate(userProfileProvider);
      debugPrint('PurchaseController: Invalidated userProfileProvider');
    },
  );
});

/// Helper provider to get selected product for purchase
final selectedProductProvider = StateProvider<PurchaseProduct?>((ref) => null);

/// Provider to track if RevenueCat is initialized
final isRevenueCatInitializedProvider = StateProvider<bool>((ref) => false);

/// Initialize RevenueCat SDK and sync user attributes
Future<void> initializeRevenueCat(WidgetRef ref, String? userId) async {
  try {
    final repository = ref.read(purchaseRepositoryProvider);
    await repository.initialize(userId);
    ref.read(isRevenueCatInitializedProvider.notifier).state = true;
    debugPrint('RevenueCat initialized successfully');

    // Sync user attributes to RevenueCat for customer identification
    if (userId != null) {
      try {
        final userProfile = await ref.read(userProfileProvider.future);
        if (userProfile != null) {
          await repository.setUserAttributes(
            email: userProfile['email'] as String?,
            displayName: userProfile['display_name'] as String?,
            phoneNumber: userProfile['phone_number'] as String?,
          );
          debugPrint('RevenueCat user attributes synced');
        }
      } catch (e) {
        debugPrint('Failed to sync RevenueCat attributes: $e');
        // Don't fail initialization if attribute sync fails
      }
    }
  } catch (e) {
    debugPrint('Failed to initialize RevenueCat: $e');
  }
}

/// Login user to RevenueCat
Future<void> loginRevenueCat(WidgetRef ref, String userId) async {
  try {
    final repository = ref.read(purchaseRepositoryProvider);
    await repository.login(userId);
    debugPrint('RevenueCat user logged in: $userId');
  } catch (e) {
    debugPrint('Failed to login to RevenueCat: $e');
  }
}

/// Logout user from RevenueCat
Future<void> logoutRevenueCat(WidgetRef ref) async {
  try {
    final repository = ref.read(purchaseRepositoryProvider);
    await repository.logout();
    debugPrint('RevenueCat user logged out');
  } catch (e) {
    debugPrint('Failed to logout from RevenueCat: $e');
  }
}

/// Start listening for subscription changes from Supabase Realtime
void startSubscriptionRealtime(WidgetRef ref, String userId) {
  try {
    final service = ref.read(subscriptionRealtimeServiceProvider);
    service.startListening(userId);
    debugPrint('Subscription Realtime started for user: $userId');
  } catch (e) {
    debugPrint('Failed to start Subscription Realtime: $e');
  }
}

/// Stop listening for subscription changes
void stopSubscriptionRealtime(WidgetRef ref) {
  try {
    final service = ref.read(subscriptionRealtimeServiceProvider);
    service.stopListening();
    debugPrint('Subscription Realtime stopped');
  } catch (e) {
    debugPrint('Failed to stop Subscription Realtime: $e');
  }
}
