import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/cart_totals_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_supabase_data_source.dart';

/// Typed exception for cart operations.
///
/// Wraps [PostgrestException] with a stable code + message contract so that
/// the presentation layer does not need to depend on Supabase internals.
class CartException implements Exception {
  final String code;
  final String message;

  const CartException(this.code, this.message);

  @override
  String toString() => 'CartException($code): $message';
}

/// Supabase-backed implementation of [CartRepository].
///
/// Security notes (STRIDE threat register, plan 08-01):
/// - T-08-01-02: quantity is clamped to 1..99 before reaching the datasource;
///   the Postgres CHECK (quantity > 0) provides a second-layer server-side guard.
/// - T-08-01-01: RLS INSERT policy on cart_items enforces user_id = auth.uid()
///   server-side; passing a spoofed userId would be rejected by Supabase RLS.
class CartRepositoryImpl implements CartRepository {
  final CartSupabaseDataSource _dataSource;

  const CartRepositoryImpl(this._dataSource);

  @override
  Stream<List<CartItemEntity>> watchCart(String userId) {
    return _dataSource.watchCart(userId);
  }

  @override
  Future<void> addItem({
    required String userId,
    required String productVariantId,
    required String qrCodeId,
    required Map<String, dynamic> customizationSnapshot,
    String? pngStorageUrl,
    int quantity = 1,
  }) async {
    // T-08-01-02: client-side quantity cap (server CHECK enforces >0).
    final safeQty = quantity.clamp(1, 99);
    try {
      await _dataSource.upsertItem(
        userId: userId,
        productVariantId: productVariantId,
        qrCodeId: qrCodeId,
        customizationSnapshot: customizationSnapshot,
        pngStorageUrl: pngStorageUrl,
        quantity: safeQty,
      );
    } on PostgrestException catch (e) {
      throw CartException(e.code ?? 'unknown', e.message);
    }
  }

  @override
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      throw const CartException('invalid_quantity', 'Quantity must be > 0');
    }
    final safeQty = quantity.clamp(1, 99);
    try {
      await _dataSource.updateQuantity(cartItemId, safeQty);
    } on PostgrestException catch (e) {
      throw CartException(e.code ?? 'unknown', e.message);
    }
  }

  @override
  Future<void> removeItem(String cartItemId) async {
    try {
      await _dataSource.deleteItem(cartItemId);
    } on PostgrestException catch (e) {
      throw CartException(e.code ?? 'unknown', e.message);
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await _dataSource.clearCart(userId);
    } on PostgrestException catch (e) {
      throw CartException(e.code ?? 'unknown', e.message);
    }
  }

  @override
  Future<CartTotalsEntity> computeTotals(String userId) async {
    try {
      return await _dataSource.computeTotals(userId);
    } on PostgrestException catch (e) {
      throw CartException(e.code ?? 'unknown', e.message);
    }
  }
}
