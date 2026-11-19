import 'package:equatable/equatable.dart';

/// Exception thrown when operator operations fail (FSM violations, network errors).
class OperatorException implements Exception {
  final String message;
  final Object? cause;

  const OperatorException(this.message, {this.cause});

  @override
  String toString() => 'OperatorException: $message';
}

/// SLA thresholds for stale-order detection (in hours).
///
/// An order is flagged stale when it has been in the given status
/// for longer than the threshold without progressing.
const Map<String, Duration> kSlaThresholds = {
  'paid': Duration(hours: 1),
  'received_by_ops': Duration(hours: 4),
  'engraving': Duration(hours: 24),
  'engraving_done': Duration(hours: 4),
};

/// Lightweight DTO used exclusively by the operator queue and card widget.
///
/// Contains only the fields needed for list rendering + stale alerting.
/// Full order detail uses [OrderEntity] + [OrderItemEntity] from the
/// orders feature.
class OperatorOrderRow extends Equatable {
  final String id;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final int totalCop;
  final String shippingRecipientName;
  final String shippingCity;

  /// True when the order has been in [status] longer than the SLA threshold.
  final bool isStale;

  /// URL of the first order_item's QR PNG (may be null if no items yet).
  final String? qrPngUrl;

  /// Number of line items in the order.
  final int itemCount;

  const OperatorOrderRow({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.totalCop,
    required this.shippingRecipientName,
    required this.shippingCity,
    required this.isStale,
    this.qrPngUrl,
    required this.itemCount,
  });

  /// Builds an [OperatorOrderRow] from a raw Supabase map, computing [isStale]
  /// client-side against [kSlaThresholds].
  factory OperatorOrderRow.fromMap(Map<String, dynamic> m) {
    final status = m['status'] as String? ?? '';
    final createdAt = DateTime.parse(m['created_at'] as String).toLocal();
    final age = DateTime.now().difference(createdAt);
    final sla = kSlaThresholds[status];
    final isStale = sla != null && age > sla;

    // qr_png_url comes from the first nested order_items row (or direct field).
    String? qrPngUrl;
    final items = m['order_items'];
    if (items is List && items.isNotEmpty) {
      qrPngUrl = items.first['qr_png_url'] as String?;
    } else {
      qrPngUrl = m['qr_png_url'] as String?;
    }

    final itemCount = () {
      if (items is List) return items.length;
      return (m['item_count'] as int?) ?? 0;
    }();

    return OperatorOrderRow(
      id: m['id'] as String,
      orderNumber: m['order_number'] as String,
      status: status,
      createdAt: createdAt,
      totalCop: m['total_cop'] as int,
      shippingRecipientName: m['shipping_recipient_name'] as String? ?? '',
      shippingCity: m['shipping_city'] as String? ?? '',
      isStale: isStale,
      qrPngUrl: qrPngUrl,
      itemCount: itemCount,
    );
  }

  @override
  List<Object?> get props => [id, status, isStale];
}
