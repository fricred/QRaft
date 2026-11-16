import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_riverpod/legacy.dart';
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
import 'subscription_providers.dart' show debugPremiumOverrideProvider;

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
// No automatic retry (Riverpod 3 retries failed providers and shows "loading" meanwhile):
// when the store is unavailable the paywall must show its error/retry state, not spin.
final purchaseProductsProvider = FutureProvider<List<PurchaseProduct>>(retry: (_, __) => null, (ref) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  try {
    final products = await repository.getProducts();
    if (products.isNotEmpty) return products;
    // Fall through to mock if empty
  } catch (e) {
    debugPrint('purchaseProductsProvider: getProducts failed — $e');
    if (!kDebugMode) rethrow; // surface error state in production paywall
  }

  // In debug mode (simulator/dev) return mock products so the paywall renders.
  // Purchases are not real — StoreKit will intercept and show a sandbox prompt.
  if (kDebugMode) {
    return [
      const PurchaseProduct(
        id: 'qraft_pro_monthly',
        title: 'QRaft Pro Mensual',
        description: '7 días gratis, luego mensual',
        priceString: '\$4.99',
        price: 4.99,
        currencyCode: 'USD',
        type: ProductType.monthly,
        trialDays: 7,
      ),
      const PurchaseProduct(
        id: 'qraft_pro_yearly',
        title: 'QRaft Pro Anual',
        description: '7 días gratis, ahorra 33%',
        priceString: '\$39.99',
        price: 39.99,
        currencyCode: 'USD',
        type: ProductType.annual,
        trialDays: 7,
      ),
      const PurchaseProduct(
        id: 'qraft_pro_lifetime',
        title: 'QRaft Pro Lifetime',
        description: 'Acceso de por vida',
        priceString: '\$9.99',
        price: 9.99,
        currencyCode: 'USD',
        type: ProductType.lifetime,
      ),
    ];
  }
  return [];
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
  final void Function()? _onDebugPurchaseSuccess;

  PurchaseController({
    required PurchaseRepository repository,
    required SubscriptionSyncService syncService,
    void Function()? onSubscriptionChanged,
    void Function()? onDebugPurchaseSuccess,
  })  : _repository = repository,
        _syncService = syncService,
        _onSubscriptionChanged = onSubscriptionChanged,
        _onDebugPurchaseSuccess = onDebugPurchaseSuccess,
        super(const PurchaseControllerState());

  /// Purchase a product
  Future<bool> purchase(PurchaseProduct product) async {
    state = state.copyWith(
      purchaseState: PurchaseState.loading,
      error: null,
    );

    final result = await _repository.purchaseProduct(product);

    if (result.success) {
      // In debug mode with a simulated purchase (package == null), activate the
      // debug premium override so isPremiumProvider returns true immediately.
      if (kDebugMode && product.package == null) {
        _onDebugPurchaseSuccess?.call();
      } else {
        // Real purchase: sync entitlements from RevenueCat → Supabase.
        await _syncService.forceSync();
      }

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
    onDebugPurchaseSuccess: kDebugMode
        ? () {
            ref.read(debugPremiumOverrideProvider.notifier).state = true;
            debugPrint('PurchaseController: debug premium override activated');
          }
        : null,
  );
});

/// Helper provider to get selected product for purchase
final selectedProductProvider = StateProvider<PurchaseProduct?>((ref) => null);

/// Provider to track if RevenueCat is initialized
final isRevenueCatInitializedProvider = StateProvider<bool>((ref) => false);

/// True when RevenueCat initialization failed (no key, offline…): the paywall must stop
/// waiting and show prices as unavailable instead of spinning forever.
final isRevenueCatInitFailedProvider = StateProvider<bool>((ref) => false);

/// Reads providers; satisfied by both `WidgetRef.read` and `ProviderContainer.read`.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Every RevenueCat identity operation (configure/logIn, logOut) runs through this queue,
/// strictly one after another. That removes all sign-out/sign-in races: the SDK identity
/// always ends as the last requested user, and the ready flag is only ever set by the
/// operation that actually finished last.
Future<void> _revenueCatQueue = Future<void>.value();

Future<void> _enqueueRevenueCat(Future<void> Function() op) {
  final run = _revenueCatQueue.then((_) => op());
  _revenueCatQueue = run.catchError((Object _) {});
  return run;
}

/// Initialize RevenueCat for [userId] and sync user attributes (queued).
/// [container] is the app-wide ProviderContainer (never a widget ref, which may be
/// disposed before the queued operation runs).
Future<void> initializeRevenueCat(ProviderContainer container, String? userId) =>
    _enqueueRevenueCat(() => _initializeRevenueCat(container.read, userId));

/// Makes sure RevenueCat is ready for the current user before a purchase or restore,
/// retrying a failed initialization once. Uses the app-wide [container] (never a
/// short-lived widget ref, which may be disposed while this awaits).
Future<bool> ensureRevenueCatReady(ProviderContainer container, String? userId) async {
  if (container.read(isRevenueCatInitializedProvider)) return true;
  await _enqueueRevenueCat(() async {
    // Another queued operation may already have made it ready.
    if (container.read(isRevenueCatInitializedProvider)) return;
    await _initializeRevenueCat(container.read, userId);
  });
  return container.read(isRevenueCatInitializedProvider);
}

Future<void> _initializeRevenueCat(ProviderReader read, String? userId) async {
  try {
    final repository = read(purchaseRepositoryProvider);
    read(isRevenueCatInitFailedProvider.notifier).state = false;
    // Not ready while (re)identifying: nothing may be bought under the old identity.
    read(isRevenueCatInitializedProvider.notifier).state = false;
    await repository.initialize(userId);
    read(isRevenueCatInitializedProvider.notifier).state = true;
    debugPrint('RevenueCat initialized successfully');

    // Sync user attributes to RevenueCat for customer identification
    if (userId != null) {
      try {
        final userProfile = await read(userProfileProvider.future);
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
    read(isRevenueCatInitFailedProvider.notifier).state = true;
    read(isRevenueCatInitializedProvider.notifier).state = false;
    debugPrint('Failed to initialize RevenueCat: $e');
  }
}

/// Logout user from RevenueCat (queued after any running initialization).
Future<void> logoutRevenueCat(ProviderContainer container) {
  final read = container.read;
  // Not ready from this moment: nothing may be bought while the identity changes.
  read(isRevenueCatInitializedProvider.notifier).state = false;
  return _enqueueRevenueCat(() async {
    try {
      await read(purchaseRepositoryProvider).logout();
      // An init queued before this logout may have set "ready"; logout runs last, so it
      // has the final word: not ready until the next sign-in initializes again.
      read(isRevenueCatInitializedProvider.notifier).state = false;
      debugPrint('RevenueCat user logged out');
    } catch (e) {
      debugPrint('Failed to logout from RevenueCat: $e');
    }
  });
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
