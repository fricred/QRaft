import 'package:equatable/equatable.dart';

/// FSM states for an order, matching the DB `order_status` ENUM exactly.
///
/// Order of values matters — [stepIndex] uses [OrderStatus.values.indexOf]
/// so do NOT reorder without updating tests.
enum OrderStatus {
  paymentPending,   // payment_pending
  paymentFailed,    // payment_failed
  paid,             // paid
  receivedByOps,    // received_by_ops
  engraving,        // engraving
  engravingFailed,  // engraving_failed
  engravingDone,    // engraving_done
  shipped,          // shipped
  delivered,        // delivered
  cancelled,        // cancelled
  refunded,         // refunded
}

extension OrderStatusX on OrderStatus {
  /// Human-readable Spanish label for timeline display.
  String get label => switch (this) {
    OrderStatus.paymentPending  => 'Pago pendiente',
    OrderStatus.paymentFailed   => 'Pago fallido',
    OrderStatus.paid            => 'Pagado',
    OrderStatus.receivedByOps   => 'Recibido por ops',
    OrderStatus.engraving       => 'Grabando',
    OrderStatus.engravingFailed => 'Error de grabado',
    OrderStatus.engravingDone   => 'Grabado listo',
    OrderStatus.shipped         => 'Enviado',
    OrderStatus.delivered       => 'Entregado',
    OrderStatus.cancelled       => 'Cancelado',
    OrderStatus.refunded        => 'Reembolsado',
  };

  /// True only for terminal states (no further transitions possible).
  bool get isFinal =>
      this == OrderStatus.cancelled || this == OrderStatus.refunded;

  /// Position in the FSM progression — used by [OrderStatusTimeline] to
  /// determine which steps are completed vs pending.
  int get stepIndex => OrderStatus.values.indexOf(this);

  /// Parses a DB ENUM string to the corresponding [OrderStatus] value.
  ///
  /// Throws [ArgumentError] if [raw] is not a known value.
  static OrderStatus fromString(String raw) {
    const map = {
      'payment_pending': OrderStatus.paymentPending,
      'payment_failed': OrderStatus.paymentFailed,
      'paid': OrderStatus.paid,
      'received_by_ops': OrderStatus.receivedByOps,
      'engraving': OrderStatus.engraving,
      'engraving_failed': OrderStatus.engravingFailed,
      'engraving_done': OrderStatus.engravingDone,
      'shipped': OrderStatus.shipped,
      'delivered': OrderStatus.delivered,
      'cancelled': OrderStatus.cancelled,
      'refunded': OrderStatus.refunded,
    };
    final result = map[raw];
    if (result == null) throw ArgumentError('Unknown OrderStatus: $raw');
    return result;
  }
}

/// Domain entity representing a single order.
///
/// Monetary amounts are stored as whole COP pesos (Int) — same convention as
/// [CartTotalsEntity] and the DB schema.
class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final int subtotalCop;
  final int taxCop;
  final int shippingCop;
  final int totalCop;
  final String shippingRecipientName;
  final String shippingPhone;
  final String shippingDepartment;
  final String shippingCity;
  final String shippingAddress;
  final String? shippingNotes;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? receivedAt;
  final DateTime? engravingStartedAt;
  final DateTime? engravingDoneAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotalCop,
    required this.taxCop,
    required this.shippingCop,
    required this.totalCop,
    required this.shippingRecipientName,
    required this.shippingPhone,
    required this.shippingDepartment,
    required this.shippingCity,
    required this.shippingAddress,
    this.shippingNotes,
    required this.createdAt,
    this.paidAt,
    this.receivedAt,
    this.engravingStartedAt,
    this.engravingDoneAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  factory OrderEntity.fromMap(Map<String, dynamic> m) => OrderEntity(
    id: m['id'] as String,
    orderNumber: m['order_number'] as String,
    status: OrderStatusX.fromString(m['status'] as String),
    subtotalCop: m['subtotal_cop'] as int,
    taxCop: m['tax_cop'] as int,
    shippingCop: m['shipping_cop'] as int,
    totalCop: m['total_cop'] as int,
    shippingRecipientName: m['shipping_recipient_name'] as String,
    shippingPhone: m['shipping_phone'] as String,
    shippingDepartment: m['shipping_department'] as String,
    shippingCity: m['shipping_city'] as String,
    shippingAddress: m['shipping_address'] as String,
    shippingNotes: m['shipping_notes'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
    paidAt: m['paid_at'] != null
        ? DateTime.parse(m['paid_at'] as String).toLocal()
        : null,
    receivedAt: m['received_at'] != null
        ? DateTime.parse(m['received_at'] as String).toLocal()
        : null,
    engravingStartedAt: m['engraving_started_at'] != null
        ? DateTime.parse(m['engraving_started_at'] as String).toLocal()
        : null,
    engravingDoneAt: m['engraving_done_at'] != null
        ? DateTime.parse(m['engraving_done_at'] as String).toLocal()
        : null,
    shippedAt: m['shipped_at'] != null
        ? DateTime.parse(m['shipped_at'] as String).toLocal()
        : null,
    deliveredAt: m['delivered_at'] != null
        ? DateTime.parse(m['delivered_at'] as String).toLocal()
        : null,
    cancelledAt: m['cancelled_at'] != null
        ? DateTime.parse(m['cancelled_at'] as String).toLocal()
        : null,
  );

  @override
  List<Object?> get props => [id, status, totalCop];
}
