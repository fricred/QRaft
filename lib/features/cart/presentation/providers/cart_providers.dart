import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/auth/data/providers/supabase_auth_provider.dart';
import '../../data/datasources/cart_supabase_data_source.dart';
import '../../data/datasources/order_assets_storage_data_source.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/cart_totals_entity.dart';
import '../../domain/repositories/cart_repository.dart';

/// Provides the concrete [CartRepository] backed by Supabase.
///
/// Inject a fake [CartSupabaseDataSource] in tests via `ProviderContainer`
/// overrides — mirrors the [supabaseClientProvider] override pattern from
/// plan 04-01.
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(
    CartSupabaseDataSource(Supabase.instance.client),
  );
});

/// Streams the current user's cart items in real time.
///
/// Returns [Stream.empty()] for unauthenticated users so widgets receive an
/// empty [AsyncValue.data([])] instead of an error state.
final cartItemsProvider = StreamProvider<List<CartItemEntity>>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null) return const Stream.empty();
  return ref.read(cartRepositoryProvider).watchCart(user.id);
});

/// Provides [OrderAssetsStorageDataSource] backed by the Supabase singleton.
///
/// Separated from [cartRepositoryProvider] so callers that only need Storage
/// access do not need the full cart data-source.
final orderAssetsStorageDsProvider =
    Provider<OrderAssetsStorageDataSource>((ref) {
  return OrderAssetsStorageDataSource(Supabase.instance.client);
});

/// Calls [server_compute_order_totals] RPC whenever [cartItemsProvider] emits.
///
/// Returns [CartTotalsEntity.zero] for:
/// - Unauthenticated users
/// - Empty cart (avoids an unnecessary RPC round-trip)
///
/// Uses server-side computation exclusively — Anti-Pattern 5 mitigation.
final cartTotalsProvider = FutureProvider<CartTotalsEntity>((ref) async {
  final cartAsync = ref.watch(cartItemsProvider);
  final user = ref.watch(authStateProvider);
  if (user == null) return CartTotalsEntity.zero;
  final items = cartAsync.value ?? [];
  if (items.isEmpty) return CartTotalsEntity.zero;
  return ref.read(cartRepositoryProvider).computeTotals(user.id);
});
