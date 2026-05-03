import 'package:equatable/equatable.dart';

/// Domain entity representing a single item in the user's cart.
///
/// [customizationSnapshot] is a frozen copy of [QRCustomization] serialized
/// to JSON at the moment the user taps "Add to cart". The QR library entry
/// may change afterward — the snapshot ensures the engraver receives what
/// the customer ordered (Pattern 1: Customization Snapshot, ARCHITECTURE.md).
class CartItemEntity extends Equatable {
  final String id;
  final String userId;
  final String productVariantId;
  final String qrCodeId;

  /// Frozen QRCustomization JSON — serialized at add-to-cart time.
  final Map<String, dynamic> customizationSnapshot;

  /// Supabase Storage URL for the pre-rasterized 2160px PNG.
  /// Null until Phase 8 Plan 03 uploads the engraver-quality image.
  final String? pngStorageUrl;

  final int quantity;
  final DateTime addedAt;

  const CartItemEntity({
    required this.id,
    required this.userId,
    required this.productVariantId,
    required this.qrCodeId,
    required this.customizationSnapshot,
    this.pngStorageUrl,
    required this.quantity,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'product_variant_id': productVariantId,
        'qr_code_id': qrCodeId,
        'customization_snapshot': customizationSnapshot,
        'png_storage_url': pngStorageUrl,
        'quantity': quantity,
        'added_at': addedAt.toIso8601String(),
      };

  factory CartItemEntity.fromJson(Map<String, dynamic> json) => CartItemEntity(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        productVariantId: json['product_variant_id'] as String,
        qrCodeId: json['qr_code_id'] as String,
        customizationSnapshot:
            (json['customization_snapshot'] as Map<String, dynamic>?) ?? {},
        pngStorageUrl: json['png_storage_url'] as String?,
        quantity: json['quantity'] as int,
        addedAt: DateTime.parse(json['added_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        productVariantId,
        qrCodeId,
        customizationSnapshot,
        pngStorageUrl,
        quantity,
        addedAt,
      ];
}
