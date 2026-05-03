import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status_timeline.dart';

/// Detail screen for a single order.
///
/// Subscribes to [orderDetailStreamProvider] backed by Supabase Realtime
/// so status changes from server-side RPCs appear in <2s without refresh.
///
/// Sections rendered:
/// 1. OrderStatusTimeline — full FSM progression
/// 2. Line items — thumbnail + label + qty + line total
/// 3. Totals card — subtotal / IVA 19% / envío / total
/// 4. Shipping address card
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  static final _copFormatter =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailStreamProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: orderAsync.maybeWhen(
          data: (order) => Text(
            order?.orderNumber ?? 'Orden',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          orElse: () => const Text(
            'Detalle de orden',
            style: TextStyle(color: Colors.white),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: orderAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildError(e),
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text(
                'Orden no encontrada',
                style: TextStyle(color: Color(0xFF999999)),
              ),
            );
          }
          return _buildContent(context, order, itemsAsync);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderEntity order,
    AsyncValue<List<OrderItemEntity>> itemsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status timeline
          _SectionCard(
            title: 'Estado del pedido',
            child: OrderStatusTimeline(currentStatus: order.status),
          ),
          const SizedBox(height: 16),

          // 2. Line items
          _SectionCard(
            title: 'Productos',
            child: itemsAsync.when(
              loading: () => _buildItemsShimmer(),
              error: (e, _) => Text(
                'Error cargando productos: $e',
                style: const TextStyle(color: Color(0xFFFF6B6B)),
              ),
              data: (items) => items.isEmpty
                  ? const Text(
                      'Sin artículos',
                      style: TextStyle(color: Color(0xFF999999)),
                    )
                  : Column(
                      children: items
                          .map((item) => _OrderItemRow(
                                item: item,
                                copFormatter: _copFormatter,
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Totals card
          _SectionCard(
            title: 'Resumen de pago',
            child: _TotalsCard(order: order, copFormatter: _copFormatter),
          ),
          const SizedBox(height: 16),

          // 4. Shipping address
          _SectionCard(
            title: 'Dirección de envío',
            child: _ShippingCard(order: order),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2E2E2E),
      highlightColor: const Color(0xFF3E3E3E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E2E),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF3E3E3E),
      highlightColor: const Color(0xFF4E4E4E),
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E3E),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
            const SizedBox(height: 12),
            Text(
              'Error al cargar la orden',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Line item row
// ---------------------------------------------------------------------------

class _OrderItemRow extends StatelessWidget {
  final OrderItemEntity item;
  final NumberFormat copFormatter;

  const _OrderItemRow({required this.item, required this.copFormatter});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.qrPngUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // QR PNG thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: item.qrPngUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFF3E3E3E),
                      highlightColor: const Color(0xFF4E4E4E),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFF3E3E3E),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFF3E3E3E),
                      child: const Icon(
                        Icons.qr_code,
                        color: Color(0xFF666666),
                        size: 28,
                      ),
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFF3E3E3E),
                    child: const Icon(
                      Icons.qr_code,
                      color: Color(0xFF666666),
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grabado personalizado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cant: ${item.quantity} × ${copFormatter.format(item.unitPriceCop)}',
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Line total
          Text(
            copFormatter.format(item.lineTotalCop),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Totals card
// ---------------------------------------------------------------------------

class _TotalsCard extends StatelessWidget {
  final OrderEntity order;
  final NumberFormat copFormatter;

  const _TotalsCard({required this.order, required this.copFormatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TotalsRow(
          label: 'Subtotal',
          value: copFormatter.format(order.subtotalCop),
        ),
        _TotalsRow(
          label: 'IVA 19%',
          value: copFormatter.format(order.taxCop),
        ),
        _TotalsRow(
          label: 'Envío',
          value: copFormatter.format(order.shippingCop),
        ),
        const Divider(color: Color(0xFF444444), height: 20),
        _TotalsRow(
          label: 'Total',
          value: copFormatter.format(order.totalCop),
          isTotal: true,
        ),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _TotalsRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: isTotal ? const Color(0xFF00FF88) : Colors.white,
      fontSize: isTotal ? 15 : 13,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shipping address card
// ---------------------------------------------------------------------------

class _ShippingCard extends StatelessWidget {
  final OrderEntity order;

  const _ShippingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(icon: Icons.person_outline, text: order.shippingRecipientName),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.phone_outlined, text: order.shippingPhone),
        const SizedBox(height: 6),
        _InfoRow(
          icon: Icons.location_on_outlined,
          text:
              '${order.shippingCity}, ${order.shippingDepartment}',
        ),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.home_outlined, text: order.shippingAddress),
        if (order.shippingNotes != null &&
            order.shippingNotes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.notes_outlined,
            text: order.shippingNotes!,
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF999999)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
