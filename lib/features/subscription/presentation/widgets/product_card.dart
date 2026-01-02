import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/entities/purchase_product.dart';

/// Card displaying a purchasable product
class ProductCard extends StatelessWidget {
  final PurchaseProduct product;
  final bool isSelected;
  final bool isRecommended;
  final int? savingsPercent;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isSelected,
    this.isRecommended = false,
    this.savingsPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00FF88).withValues(alpha: 0.1)
              : const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF88)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getProductTitle(),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00FF88) : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF88),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.priceString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.periodText.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          product.periodText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.hasFreeTrial) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${product.trialDays} days free trial',
                      style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Badges
            if (isRecommended || savingsPercent != null)
              Positioned(
                top: -8,
                right: -8,
                child: _buildBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (savingsPercent != null && savingsPercent! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Save $savingsPercent%',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ).animate().fadeIn().scale();
    }

    if (isRecommended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Best Value',
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ).animate().fadeIn().scale();
    }

    return const SizedBox.shrink();
  }

  String _getProductTitle() {
    switch (product.type) {
      case ProductType.monthly:
        return 'Monthly';
      case ProductType.annual:
        return 'Annual';
      case ProductType.lifetime:
        return 'Lifetime';
    }
  }
}
