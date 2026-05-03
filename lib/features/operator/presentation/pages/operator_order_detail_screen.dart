import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/operator_providers.dart';
import '../widgets/operator_status_action_bar.dart';

/// Operator order detail screen.
///
/// Displays full order information: customer details, line items with QR PNG
/// thumbnails, price breakdown, and a status action bar for transitioning
/// the order through the FSM.
class OperatorOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  final String orderNumber;

  const OperatorOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(operatorOrderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E2E2E),
        title: Text(
          orderNumber,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF88)),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Color(0xFFAAAAAA)),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text(
                'Pedido no encontrado',
                style: TextStyle(color: Color(0xFFAAAAAA)),
              ),
            );
          }
          return _OrderDetailBody(orderId: orderId, data: data);
        },
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderDetailBody({required this.orderId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? '';
    final items = (data['order_items'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    final subtotal = data['subtotal_cop'] as int? ?? 0;
    final tax = data['tax_cop'] as int? ?? 0;
    final shipping = data['shipping_cop'] as int? ?? 0;
    final total = data['total_cop'] as int? ?? 0;

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status pill
                _SectionHeader('Estado del pedido'),
                const SizedBox(height: 8),
                _StatusBadge(status: status),
                const SizedBox(height: 20),

                // Customer info
                _SectionHeader('Cliente'),
                const SizedBox(height: 8),
                _InfoCard(children: [
                  _InfoRow(
                    'Nombre',
                    data['shipping_recipient_name'] as String? ?? '-',
                  ),
                  _InfoRow(
                    'Telefono',
                    data['shipping_phone'] as String? ?? '-',
                  ),
                  _InfoRow(
                    'Departamento',
                    data['shipping_department'] as String? ?? '-',
                  ),
                  _InfoRow(
                    'Ciudad',
                    data['shipping_city'] as String? ?? '-',
                  ),
                  _InfoRow(
                    'Direccion',
                    data['shipping_address'] as String? ?? '-',
                  ),
                  if ((data['shipping_notes'] as String?) != null)
                    _InfoRow('Notas', data['shipping_notes'] as String),
                ]),
                const SizedBox(height: 20),

                // Order items
                _SectionHeader('Items (${items.length})'),
                const SizedBox(height: 8),
                ...items.map((item) => _OrderItemCard(item: item)),

                const SizedBox(height: 20),

                // Price breakdown
                _SectionHeader('Resumen de pago'),
                const SizedBox(height: 8),
                _InfoCard(children: [
                  _InfoRow('Subtotal', _formatCop(subtotal)),
                  _InfoRow('IVA (19%)', _formatCop(tax)),
                  _InfoRow('Envio', _formatCop(shipping)),
                  const Divider(color: Color(0xFF444444), height: 20),
                  _InfoRow(
                    'TOTAL',
                    _formatCop(total),
                    highlighted: true,
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Action bar — pinned at bottom
        OperatorStatusActionBar(
          currentStatus: status,
          orderId: orderId,
          onSuccess: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  static String _formatCop(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return '\$ $formatted COP';
  }
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF888888),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _InfoRow(this.label, this.value, {this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlighted ? const Color(0xFF00FF88) : Colors.white,
                fontSize: 13,
                fontWeight:
                    highlighted ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final qrPngUrl = item['qr_png_url'] as String?;
    final unitPrice = item['unit_price_cop'] as int? ?? 0;
    final quantity = item['quantity'] as int? ?? 1;
    final lineTotal = item['line_total_cop'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR PNG thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: qrPngUrl != null && qrPngUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: qrPngUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFF1A1A1A),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00FF88),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _qrPlaceholder(),
                  )
                : _qrPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Price + quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCop(unitPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: $quantity',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${_formatCop(lineTotal)}',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: const Icon(Icons.qr_code, color: Color(0xFF444444), size: 32),
    );
  }

  static String _formatCop(int amount) {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return '\$ $formatted';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'payment_pending': 'Pago pendiente',
    'payment_failed': 'Pago fallido',
    'paid': 'Pagado',
    'received_by_ops': 'Recibido por operaciones',
    'engraving': 'En grabado',
    'engraving_failed': 'Error de grabado',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
