import 'package:flutter/material.dart';

import '../providers/operator_providers.dart';

/// Card widget displayed in the operator order queue.
///
/// Shows: order number, recipient name + city, total COP, time since creation,
/// and a red flag icon when [OperatorOrderRow.isStale] is true.
class OperatorOrderCard extends StatelessWidget {
  final OperatorOrderRow order;
  final VoidCallback onTap;

  const OperatorOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('operator_order_card_${order.id}'),
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: order.isStale
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order number + stale flag
                    Row(
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (order.isStale) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Recipient name + city
                    Text(
                      '${order.shippingRecipientName} · ${order.shippingCity}',
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status chip + item count
                    Row(
                      children: [
                        _StatusChip(status: order.status),
                        const SizedBox(width: 8),
                        Text(
                          '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right column: price + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCop(order.totalCop),
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(order.createdAt),
                    style: TextStyle(
                      color: order.isStale
                          ? Colors.red[300]
                          : const Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCop(int amount) {
    // Format as COP: $ 1.250.000
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return '\$ $formatted';
  }

  String _timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}m';
    return 'ahora';
  }
}

/// Small pill chip showing current order status.
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  static const _labels = {
    'payment_pending': 'Pago pendiente',
    'payment_failed': 'Pago fallido',
    'paid': 'Pagado',
    'received_by_ops': 'Recibido',
    'engraving': 'Grabando',
    'engraving_failed': 'Error grabado',
    'engraving_done': 'Grabado listo',
    'shipped': 'Enviado',
    'delivered': 'Entregado',
    'cancelled': 'Cancelado',
    'refunded': 'Reembolsado',
  };

  static const _colors = {
    'payment_pending': Color(0xFFFFB300),
    'payment_failed': Colors.red,
    'paid': Color(0xFF00FF88),
    'received_by_ops': Color(0xFF1A73E8),
    'engraving': Color(0xFF9C27B0),
    'engraving_failed': Colors.red,
    'engraving_done': Color(0xFF00E5FF),
    'shipped': Color(0xFF00BCD4),
    'delivered': Color(0xFF00FF88),
    'cancelled': Color(0xFF888888),
    'refunded': Color(0xFF888888),
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
