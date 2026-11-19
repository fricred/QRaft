import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/cart_totals_entity.dart';
import '../providers/cart_providers.dart';

/// Displays server-authoritative cart totals (subtotal, IVA 19%, envío, total)
/// in COP currency format.
///
/// Watches [cartTotalsProvider] which calls the [server_compute_order_totals]
/// Postgres RPC — totals are NEVER computed client-side (Anti-Pattern 5).
///
/// Auto-refreshes whenever [cartItemsProvider] emits a new list.
class CartSummaryWidget extends ConsumerWidget {
  const CartSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(cartTotalsProvider);

    return Semantics(
      identifier: 'cart_summary_widget',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: totalsAsync.when(
          loading: _buildShimmer,
          error: (_, __) => _buildError(),
          data: (totals) => _buildTotalsColumn(totals),
        ),
      ),
    );
  }

  Widget _buildTotalsColumn(CartTotalsEntity totals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TotalRow(label: 'Subtotal', value: totals.subtotalCop),
        const SizedBox(height: 6),
        _TotalRow(label: 'IVA 19%', value: totals.ivaCop),
        const SizedBox(height: 6),
        _TotalRow(
          label: 'Envío',
          value: totals.envioCop,
          semanticsId: 'cart_summary_envio',
        ),
        Divider(
          color: Colors.white.withValues(alpha: 0.12),
          height: 24,
        ),
        _TotalRow(
          label: 'Total',
          value: totals.totalCop,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF3A3A3A),
      highlightColor: const Color(0xFF4A4A4A),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Text(
      'No se pudo calcular el total',
      style: TextStyle(color: Colors.grey[500], fontSize: 14),
      textAlign: TextAlign.center,
    );
  }
}

/// A single row in the cart summary with a label and COP-formatted value.
class _TotalRow extends StatelessWidget {
  final String label;
  final int value;
  final bool isTotal;
  final String? semanticsId;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final String semanticId = semanticsId ?? _defaultSemanticsId(label);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.grey[400],
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Semantics(
          identifier: semanticId,
          child: Text(
            _formatCop(value),
            style: TextStyle(
              color: isTotal ? const Color(0xFF00FF88) : Colors.white,
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _defaultSemanticsId(String label) {
    switch (label) {
      case 'Subtotal':
        return 'cart_summary_subtotal';
      case 'IVA 19%':
        return 'cart_summary_iva';
      case 'Total':
        return 'cart_summary_total';
      default:
        return 'cart_summary_row';
    }
  }
}

String _formatCop(int pesos) =>
    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0)
        .format(pesos);
