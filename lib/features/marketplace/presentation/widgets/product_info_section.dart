import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';
import '../../domain/entities/product_entity.dart';

/// Product information section with name, price, and status badges.
class ProductInfoSection extends StatelessWidget {
  final ProductEntity product;

  const ProductInfoSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate()
            .fadeIn(duration: 300.ms, delay: 100.ms)
            .slideY(begin: 0.2, duration: 300.ms, delay: 100.ms, curve: Curves.easeOutQuart),

          const SizedBox(height: 8),

          // Price and badges - using Wrap for overflow safety
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Price
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate()
                .fadeIn(duration: 300.ms, delay: 150.ms)
                .slideX(begin: -0.2, duration: 300.ms, delay: 150.ms, curve: Curves.easeOutQuart),

              // Stock badge
              _StatusBadge(
                text: product.inStock ? l10n.inStock : l10n.outOfStock,
                isPositive: product.inStock,
              ).animate()
                .fadeIn(duration: 250.ms, delay: 200.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 250.ms, delay: 200.ms),

              // Material category badge
              _MaterialBadge(
                category: product.materialCategory,
                gradient: product.gradient,
              ).animate()
                .fadeIn(duration: 250.ms, delay: 220.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 250.ms, delay: 220.ms),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            product.description.isNotEmpty
                ? product.description
                : l10n.defaultProductDescription,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
              height: 1.5,
            ),
          ).animate()
            .fadeIn(duration: 300.ms, delay: 250.ms),
        ],
      ),
    );
  }
}

/// Status badge widget (in stock / out of stock)
class _StatusBadge extends StatelessWidget {
  final String text;
  final bool isPositive;

  const _StatusBadge({
    required this.text,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isPositive
            ? const LinearGradient(
                colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
              )
            : null,
        color: isPositive ? null : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Material category badge with gradient indicator
class _MaterialBadge extends StatelessWidget {
  final String category;
  final LinearGradient gradient;

  const _MaterialBadge({
    required this.category,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _capitalizeCategory(category),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeCategory(String category) {
    if (category.isEmpty) return '';
    return category[0].toUpperCase() + category.substring(1);
  }
}
