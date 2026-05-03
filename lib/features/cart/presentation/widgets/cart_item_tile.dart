import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../providers/cart_providers.dart';

/// A single row widget representing one item in the user's cart.
///
/// Layout:
///   [QR icon] | [product info + variant id] | [quantity controls] [delete]
///
/// Security:
/// - Quantity is capped at 99 client-side (T-08-02-01).
/// - Decrement to 0 triggers removeItem instead (preventing ghost items).
/// - removeItem delegates to CartRepository whose RLS enforces user ownership
///   (T-08-02-03).
class CartItemTile extends ConsumerWidget {
  final CartItemEntity item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      identifier: 'cart_item_tile_${item.id}',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QR icon placeholder (png_storage_url is null until Plan 03)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF00FF88),
                size: 32,
              ),
            ),

            const SizedBox(width: 12),

            // Product / variant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product display name from snapshot, or fallback
                  Text(
                    _productName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${item.productVariantId.substring(0, 8)}…',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Quantity controls + delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Delete button
                Semantics(
                  identifier: 'cart_item_remove_${item.id}',
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _removeItem(context, ref),
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),

                // Quantity row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onPressed: () => _decrement(context, ref),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onPressed: item.quantity >= 99
                          ? null
                          : () => _increment(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Derives a display name from the customization snapshot, with fallback.
  String _productName() {
    final snap = item.customizationSnapshot;
    // The snapshot may carry a 'product_name' key if provided by future plans.
    if (snap.containsKey('product_name') && snap['product_name'] != null) {
      return snap['product_name'] as String;
    }
    return 'Producto';
  }

  Future<void> _increment(BuildContext context, WidgetRef ref) async {
    // Cap enforced here too (T-08-02-01); repository impl also clamps.
    if (item.quantity >= 99) return;
    await _safeCall(
      context,
      () => ref
          .read(cartRepositoryProvider)
          .updateQuantity(item.id, item.quantity + 1),
    );
  }

  Future<void> _decrement(BuildContext context, WidgetRef ref) async {
    if (item.quantity <= 1) {
      // Going to 0 — remove instead (T-08-02-01).
      await _removeItem(context, ref);
    } else {
      await _safeCall(
        context,
        () => ref
            .read(cartRepositoryProvider)
            .updateQuantity(item.id, item.quantity - 1),
      );
    }
  }

  Future<void> _removeItem(BuildContext context, WidgetRef ref) async {
    await _safeCall(
      context,
      () => ref.read(cartRepositoryProvider).removeItem(item.id),
    );
  }

  Future<void> _safeCall(
    BuildContext context,
    Future<void> Function() fn,
  ) async {
    try {
      await fn();
    } on CartException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el carrito')),
      );
    }
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onPressed == null
              ? const Color(0xFF1A1A1A)
              : const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null ? Colors.grey[600] : Colors.white,
        ),
      ),
    );
  }
}
