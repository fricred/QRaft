import '../../domain/entities/cart_item_entity.dart';

/// Data-layer model that maps a Supabase cart_items row (snake_case) to
/// [CartItemEntity].
///
/// Extends [CartItemEntity] so it can be passed directly to domain-layer
/// consumers without explicit conversion.
class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.userId,
    required super.productVariantId,
    required super.qrCodeId,
    required super.customizationSnapshot,
    super.pngStorageUrl,
    required super.quantity,
    required super.addedAt,
  });

  /// Construct from a raw Supabase PostgREST response row.
  ///
  /// The [added_at] column is always an ISO-8601 string from Postgres.
  /// [customization_snapshot] is returned as a [Map<String, dynamic>] by
  /// the Supabase Flutter client when the column type is JSONB.
  factory CartItemModel.fromSupabaseRow(Map<String, dynamic> row) =>
      CartItemModel(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        productVariantId: row['product_variant_id'] as String,
        qrCodeId: row['qr_code_id'] as String,
        customizationSnapshot:
            (row['customization_snapshot'] as Map<String, dynamic>?) ?? {},
        pngStorageUrl: row['png_storage_url'] as String?,
        quantity: row['quantity'] as int,
        addedAt: DateTime.parse(row['added_at'] as String),
      );
}
