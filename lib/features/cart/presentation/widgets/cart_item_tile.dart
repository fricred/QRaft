import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../providers/cart_providers.dart';

String _formatCop(int pesos) =>
    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0)
        .format(pesos);

/// A single row widget representing one item in the user's cart.
///
/// Layout:
///   [QR thumbnail] | [name + material·size + unit price] | [qty stepper]
///
/// Swipe left to remove (Dismissible) — the trash affordance is revealed
/// behind the tile. Display metadata (product_name, material_name,
/// size_label, unit_price_cop) comes from the customization snapshot when
/// present; items added before snapshot enrichment fall back gracefully.
///
/// Security:
/// - Quantity is capped at 99 client-side (T-08-02-01).
/// - Decrement to 0 triggers removeItem instead (preventing ghost items).
/// - removeItem delegates to CartRepository whose RLS enforces user ownership
///   (T-08-02-03).
class CartItemTile extends ConsumerWidget {
  final CartItemEntity item;
  final int index;

  const CartItemTile({super.key, required this.item, this.index = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      identifier: 'cart_item_tile_${item.id}',
      child: Dismissible(
        key: ValueKey('dismiss_${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _removeItem(context, ref),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFB3261E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _QrThumbnail(pngStorageUrl: item.pngStorageUrl),
              const SizedBox(width: 12),

              // Product / variant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_detailLine() != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _detailLine()!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (_unitPriceCop() != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatCop(_unitPriceCop()! * item.quantity),
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Quantity stepper (vertical pill: + / qty / −)
              _QuantityStepper(
                quantity: item.quantity,
                onIncrement:
                    item.quantity >= 99 ? null : () => _increment(context, ref),
                onDecrement: () => _decrement(context, ref),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (50 * (index % 8)).ms)
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
        .slideX(begin: 0.06, duration: 300.ms, curve: Curves.easeOutQuart);
  }

  /// Derives a display name from the customization snapshot, with fallback.
  String _productName() {
    final snap = item.customizationSnapshot;
    if (snap['product_name'] is String) return snap['product_name'] as String;
    return 'QR personalizado';
  }

  /// "Material · tamaño" line when the snapshot carries the metadata.
  String? _detailLine() {
    final snap = item.customizationSnapshot;
    final material = snap['material_name'];
    final size = snap['size_label'];
    final parts = [
      if (material is String && material.isNotEmpty) material,
      if (size is String && size.isNotEmpty) size,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  int? _unitPriceCop() {
    final price = item.customizationSnapshot['unit_price_cop'];
    return price is int ? price : null;
  }

  Future<void> _increment(BuildContext context, WidgetRef ref) async {
    // Cap enforced here too (T-08-02-01); repository impl also clamps.
    if (item.quantity >= 99) return;
    await _safeCall(
      context,
      ref,
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
        ref,
        () => ref
            .read(cartRepositoryProvider)
            .updateQuantity(item.id, item.quantity - 1),
      );
    }
  }

  Future<void> _removeItem(BuildContext context, WidgetRef ref) async {
    await _safeCall(
      context,
      ref,
      () => ref.read(cartRepositoryProvider).removeItem(item.id),
    );
  }

  Future<void> _safeCall(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() fn,
  ) async {
    try {
      await fn();
      // cart_items lacks a realtime publication (migration 20260612000000
      // pending) — restart the stream so quantity/remove changes reflect.
      ref.invalidate(cartItemsProvider);
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

/// Shows a 64×64 thumbnail of the cart item's QR code.
///
/// Uses [CachedNetworkImage] when [pngStorageUrl] is populated (Plan 03 and
/// later), falls back to the QR icon placeholder for items added before the
/// snapshot upload completed.
class _QrThumbnail extends StatelessWidget {
  final String? pngStorageUrl;

  const _QrThumbnail({this.pngStorageUrl});

  @override
  Widget build(BuildContext context) {
    const fallback = Center(
      child: Icon(
        Icons.qr_code_2_rounded,
        color: Color(0xFF00FF88),
        size: 36,
      ),
    );

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: pngStorageUrl != null
          ? CachedNetworkImage(
              imageUrl: pngStorageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 192,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }
}

/// Vertical quantity stepper: [+] on top, animated count, [−] below.
/// The minus icon becomes a trash icon at quantity 1 (decrement removes).
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const _QuantityStepper({
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.add_rounded,
            onPressed: onIncrement,
            accent: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: quantity <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onPressed: onDecrement,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool accent;

  const _StepperButton({
    required this.icon,
    this.onPressed,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 30,
        child: Icon(
          icon,
          size: 17,
          color: !enabled
              ? Colors.grey[700]
              : accent
                  ? const Color(0xFF00FF88)
                  : Colors.grey[300],
        ),
      ),
    );
  }
}
