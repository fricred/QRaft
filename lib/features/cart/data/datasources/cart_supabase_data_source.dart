import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item_model.dart';
import '../../domain/entities/cart_totals_entity.dart';

/// Thin Supabase client wrapper for the cart_items table.
///
/// Responsibilities:
/// - CRUD on cart_items (all operations scoped by user_id via RLS)
/// - watchCart: Supabase realtime stream filtered by user_id
/// - computeTotals: RPC call to server_compute_order_totals
///
/// Does NOT catch exceptions — [CartRepositoryImpl] owns error mapping.
class CartSupabaseDataSource {
  final SupabaseClient _supabase;

  const CartSupabaseDataSource(this._supabase);

  /// Streams live cart rows for [userId] using Supabase's typed stream API.
  ///
  /// The `.stream(primaryKey: ['id'])` combined with `.eq('user_id', userId)`
  /// delivers an initial snapshot then pushes subsequent updates in real time.
  /// RLS on cart_items ensures rows from other users are never returned even if
  /// the userId filter is accidentally omitted on the server side.
  Stream<List<CartItemModel>> watchCart(String userId) {
    return _supabase
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('added_at')
        .map(
          (rows) => rows
              .map((row) => CartItemModel.fromSupabaseRow(row))
              .toList(),
        );
  }

  /// Upserts a cart item.
  ///
  /// Supabase upsert with [ignoreDuplicates: false] will UPDATE the existing
  /// row when the UNIQUE(user_id, product_variant_id, qr_code_id) key matches,
  /// effectively incrementing/replacing quantity.
  Future<void> upsertItem({
    required String userId,
    required String productVariantId,
    required String qrCodeId,
    required Map<String, dynamic> customizationSnapshot,
    String? pngStorageUrl,
    required int quantity,
  }) async {
    await _supabase.from('cart_items').upsert(
      {
        'user_id': userId,
        'product_variant_id': productVariantId,
        'qr_code_id': qrCodeId,
        'customization_snapshot': customizationSnapshot,
        if (pngStorageUrl != null) 'png_storage_url': pngStorageUrl,
        'quantity': quantity,
      },
      onConflict: 'user_id,product_variant_id,qr_code_id',
    );
  }

  /// Updates only the quantity field for a known cart item [id].
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  /// Deletes a single cart item by primary key.
  Future<void> deleteItem(String cartItemId) async {
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  /// Deletes all cart items for [userId].
  ///
  /// Called after successful order creation to clear the cart.
  Future<void> clearCart(String userId) async {
    await _supabase.from('cart_items').delete().eq('user_id', userId);
  }

  /// Calls the [server_compute_order_totals] Postgres function.
  ///
  /// Returns a single row map with keys:
  ///   subtotal_cop, iva_cop, envio_cop, total_cop (all INT).
  Future<CartTotalsEntity> computeTotals(String userId) async {
    final result = await _supabase.rpc(
      'server_compute_order_totals',
      params: {'p_user_id': userId},
    ) as List<dynamic>;

    if (result.isEmpty) return CartTotalsEntity.zero;

    return CartTotalsEntity.fromRpcRow(
      result.first as Map<String, dynamic>,
    );
  }
}
