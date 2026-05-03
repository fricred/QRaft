import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../providers/cart_providers.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary_widget.dart';

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

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      CartItemTile(item: items[index]),
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
                        text: 'Proceder al pago',
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
    // Placeholder — Phase 9 will replace this SnackBar with navigation
    // to CheckoutScreen, passing the server-computed order total.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Checkout disponible en la proxima actualizacion',
        ),
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
            Icon(
              Icons.shopping_cart_outlined,
              color: Colors.grey[600],
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu carrito está vacio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos desde el catalogo',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 28),
            PrimaryGlassButton(
              text: 'Ver catalogo',
              width: 200,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

