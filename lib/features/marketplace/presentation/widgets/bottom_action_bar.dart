import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Fixed bottom action bar with quantity selector and add to cart button.
/// Features animated loading and success states.
class BottomActionBar extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final double totalPrice;
  final String currency;
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback onAddToCart;

  const BottomActionBar({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
    required this.totalPrice,
    required this.currency,
    required this.isLoading,
    required this.isSuccess,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                const Color(0xFF1A1A1A).withValues(alpha: 0.95),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Total price - prominent on left
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currency${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.total,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity selector
              _QuantitySelector(
                quantity: quantity,
                onQuantityChanged: onQuantityChanged,
              ),

              const SizedBox(width: 12),

              // Add to cart button
              _AddToCartButton(
                isLoading: isLoading,
                isSuccess: isSuccess,
                onPressed: onAddToCart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quantity selector with increment/decrement buttons
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const _QuantitySelector({
    required this.quantity,
    required this.onQuantityChanged,
  });

  void _decrement() {
    if (quantity > 1) {
      HapticFeedback.selectionClick();
      onQuantityChanged(quantity - 1);
    }
  }

  void _increment() {
    if (quantity < 99) {
      HapticFeedback.selectionClick();
      onQuantityChanged(quantity + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          _QuantityButton(
            icon: Icons.remove_rounded,
            onPressed: _decrement,
            enabled: quantity > 1,
          ),

          // Quantity display
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Increment button
          _QuantityButton(
            icon: Icons.add_rounded,
            onPressed: _increment,
            enabled: quantity < 99,
          ),
        ],
      ),
    );
  }
}

/// Individual quantity button with press animation
class _QuantityButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
  });

  @override
  State<_QuantityButton> createState() => _QuantityButtonState();
}

class _QuantityButtonState extends State<_QuantityButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              widget.icon,
              color: widget.enabled ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Add to cart button with loading and success states
class _AddToCartButton extends StatefulWidget {
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback onPressed;

  const _AddToCartButton({
    required this.isLoading,
    required this.isSuccess,
    required this.onPressed,
  });

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading || widget.isSuccess) return;
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: widget.isSuccess ? null : 52,
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: widget.isSuccess ? 16 : 0),
          decoration: BoxDecoration(
            gradient: widget.isSuccess
                ? const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ] else if (widget.isSuccess) ...[
                const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24,
                ).animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  ),
                const SizedBox(width: 8),
                Text(
                  l10n.added,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate()
                  .fadeIn(duration: 200.ms, delay: 100.ms),
              ] else ...[
                const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
