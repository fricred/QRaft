import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../providers/cart_providers.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary_widget.dart';
import '../../../checkout/presentation/pages/shipping_screen.dart';

String _formatCop(int pesos) =>
    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0)
        .format(pesos);

/// Full cart screen showing the current user's cart items with quantity
/// controls, remove action, empty state, and a loading shimmer.
///
/// The "Proceed to Checkout" placeholder button will be replaced by Phase 9.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartItemsProvider);
    final totalsAsync = ref.watch(cartTotalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Mi Carrito',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: cartAsync.when(
        loading: () => _buildShimmer(),
        error: (error, _) => _buildError(context, ref, error),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          // Determine if the checkout button should be enabled:
          // disabled while totals are still loading to prevent tapping
          // before server-computed amounts are confirmed.
          final totalsReady = totalsAsync.hasValue && !totalsAsync.isLoading;
          final totalCop = totalsAsync.value?.totalCop;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => CartItemTile(
                    key: ValueKey(items[index].id),
                    item: items[index],
                    index: index,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CartSummaryWidget(),
                    const SizedBox(height: 12),
                    Semantics(
                      identifier: 'cart_proceed_to_checkout_button',
                      child: PrimaryGlassButton(
                        // Surface the total in the CTA so the user confirms
                        // the amount with the action itself.
                        text: totalsReady && totalCop != null
                            ? 'Pagar ${_formatCop(totalCop)}'
                            : 'Proceder al pago',
                        width: double.infinity,
                        isLoading: false,
                        // Disabled when totals not yet loaded or cart is empty.
                        onPressed: totalsReady
                            ? () => _onProceedToCheckout(context)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onProceedToCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ShippingScreen(),
      ),
    );
  }

  /// Three shimmer rectangles mimicking cart item tiles.
  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF2E2E2E),
        highlightColor: const Color(0xFF3E3E3E),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el carrito',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cartItemsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF00FF88),
                size: 48,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.05,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Graba tus QR en madera, metal, acrílico y más',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 28),
            PrimaryGlassButton(
              text: 'Explorar catálogo',
              width: 220,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOutQuart),
      ),
    );
  }
}

