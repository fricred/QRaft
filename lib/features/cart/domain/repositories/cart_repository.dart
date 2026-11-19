import '../entities/cart_item_entity.dart';
import '../entities/cart_totals_entity.dart';

/// Abstract contract for the cart feature's persistence layer.
///
/// The concrete implementation ([CartRepositoryImpl]) delegates to
/// [CartSupabaseDataSource] for remote persistence in the cart_items table.
abstract class CartRepository {
  /// Streams live cart contents for [userId] via Supabase realtime channel.
  ///
  /// Emits an empty list when the cart is empty or the user is signed out.
  /// The stream completes when the repository is disposed.
  Stream<List<CartItemEntity>> watchCart(String userId);

  /// Inserts a new cart item.
  ///
  /// If the (userId, productVariantId, qrCodeId) triple already exists the
  /// remote row is updated instead (upsert semantics), matching the
  /// UNIQUE constraint on cart_items.
  ///
  /// [quantity] is clamped to 1..99 in [CartRepositoryImpl] (T-08-01-02).
  Future<void> addItem({
    required String userId,
    required String productVariantId,
    required String qrCodeId,
    required Map<String, dynamic> customizationSnapshot,
    String? pngStorageUrl,
    int quantity = 1,
  });

  /// Updates the quantity for an existing cart item identified by [cartItemId].
  ///
  /// [quantity] must be > 0; the Postgres CHECK constraint enforces this on
  /// the server side; [CartRepositoryImpl] also rejects ≤ 0 locally.
  Future<void> updateQuantity(String cartItemId, int quantity);

  /// Removes a single cart item by [cartItemId].
  Future<void> removeItem(String cartItemId);

  /// Deletes all cart items for [userId] (e.g., after successful order creation).
  Future<void> clearCart(String userId);

  /// Calls the [server_compute_order_totals] Postgres RPC.
  ///
  /// Returns [CartTotalsEntity.zero] when the cart is empty so callers need
  /// not check nullability. The RPC itself uses SECURITY DEFINER + p_user_id
  /// guard to prevent cross-user data leakage.
  Future<CartTotalsEntity> computeTotals(String userId);
}
