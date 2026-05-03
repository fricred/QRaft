import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_providers.dart';
import 'order_detail_screen.dart';

/// Screen displaying a paginated list of the current user's orders.
///
/// - Loads page 0 on first build
/// - Pull-to-refresh invalidates provider and reloads
/// - Empty state shows a receipt icon with a friendly message
/// - Shimmer skeleton shown during AsyncLoading
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  static final _dateFormatter = DateFormat('dd MMM yyyy', 'es');
  static final _copFormatter =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);

  Future<void> _refresh() async {
    ref.invalidate(ordersListProvider(0));
    // Wait for provider to settle after invalidation
    await ref
        .read(ordersListProvider(0).future)
        .catchError((_) => <OrderEntity>[]);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersListProvider(0));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Mis Órdenes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00FF88),
        backgroundColor: const Color(0xFF2E2E2E),
        onRefresh: _refresh,
        child: ordersAsync.when(
          loading: () => _buildShimmerList(),
          error: (e, _) => _buildError(e),
          data: (orders) => orders.isEmpty
              ? _buildEmptyState()
              : _buildOrderList(orders),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderEntity> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(
          order: orders[index],
          dateFormatter: _dateFormatter,
          copFormatter: _copFormatter,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Color(0xFF666666),
              ),
              SizedBox(height: 16),
              Text(
                'Aún no tienes órdenes',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Visita el marketplace para crear tu primera orden',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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
              'No se pudieron cargar las órdenes',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
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

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2E2E2E),
      highlightColor: const Color(0xFF3E3E3E),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 5,
        itemBuilder: (context, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final DateFormat dateFormatter;
  final NumberFormat copFormatter;

  const _OrderCard({
    required this.order,
    required this.dateFormatter,
    required this.copFormatter,
  });

  static const _statusColors = <OrderStatus, Color>{
    OrderStatus.paymentPending: Color(0xFFFFA726),
    OrderStatus.paymentFailed: Color(0xFFFF6B6B),
    OrderStatus.paid: Color(0xFF00FF88),
    OrderStatus.receivedByOps: Color(0xFF4FC3F7),
    OrderStatus.engraving: Color(0xFF1A73E8),
    OrderStatus.engravingFailed: Color(0xFFFF6B6B),
    OrderStatus.engravingDone: Color(0xFF00FF88),
    OrderStatus.shipped: Color(0xFF1A73E8),
    OrderStatus.delivered: Color(0xFF00FF88),
    OrderStatus.cancelled: Color(0xFF666666),
    OrderStatus.refunded: Color(0xFF666666),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[order.status] ?? const Color(0xFF666666);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id),
            ),
          );
        },
        child: Container(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(order.createdAt.toLocal()),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    copFormatter.format(order.totalCop),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}
