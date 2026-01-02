import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/purchase_product.dart';

/// Primary button for initiating purchase
class PurchaseButton extends StatelessWidget {
  final PurchaseProduct? product;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PurchaseButton({
    super.key,
    this.product,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = product != null && !isLoading && onPressed != null;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  _getButtonText(),
                  style: TextStyle(
                    color: isEnabled ? Colors.black : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  String _getButtonText() {
    if (product == null) return 'Select a plan';

    if (product!.hasFreeTrial) {
      return 'Start ${product!.trialDays}-Day Free Trial';
    }

    if (product!.isLifetime) {
      return 'Purchase Lifetime Access';
    }

    return 'Subscribe Now';
  }
}

/// Secondary button for restoring purchases
class RestorePurchasesButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const RestorePurchasesButton({
    super.key,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Restoring...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : Text(
              'Restore Purchases',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
    );
  }
}

/// Success animation shown after purchase
class PurchaseSuccessOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const PurchaseSuccessOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00FF88).withValues(alpha: 0.3),
                    const Color(0xFF00CC6A).withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Color(0xFF00FF88),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Pro!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 8),
            Text(
              'All premium features are now unlocked',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
