import 'package:equatable/equatable.dart';

/// Domain entity representing a single line item within an order.
///
/// [customizationSnapshot] is a frozen copy of the QR customization as it
/// existed at order-creation time (Pattern 1: Customization Snapshot).
/// [qrPngUrl] is the pre-rasterized 2160px PNG stored in Supabase Storage.
class OrderItemEntity extends Equatable {
  final String id;
  final String orderId;
  final String productVariantId;
  final String? qrCodeId;
  final Map<String, dynamic> customizationSnapshot;
  final String qrPngUrl;
  final int unitPriceCop;
  final int quantity;
  final int lineTotalCop;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.productVariantId,
    this.qrCodeId,
    required this.customizationSnapshot,
    required this.qrPngUrl,
    required this.unitPriceCop,
    required this.quantity,
    required this.lineTotalCop,
  });

  factory OrderItemEntity.fromMap(Map<String, dynamic> m) => OrderItemEntity(
    id: m['id'] as String,
    orderId: m['order_id'] as String,
    productVariantId: m['product_variant_id'] as String,
    qrCodeId: m['qr_code_id'] as String?,
    customizationSnapshot:
        (m['customization_snapshot'] as Map<String, dynamic>?) ?? {},
    qrPngUrl: m['qr_png_url'] as String? ?? '',
    unitPriceCop: m['unit_price_cop'] as int,
    quantity: m['quantity'] as int,
    lineTotalCop: m['line_total_cop'] as int,
  );

  @override
  List<Object?> get props => [id, orderId, quantity, lineTotalCop];
}
