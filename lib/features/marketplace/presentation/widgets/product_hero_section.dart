import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/product_entity.dart';

/// Hero section with parallax SliverAppBar for product details.
/// Displays product image with material gradient, back button, and actions.
class ProductHeroSection extends StatelessWidget {
  final ProductEntity product;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final bool isFavorite;

  const ProductHeroSection({
    super.key,
    required this.product,
    required this.scrollController,
    required this.onBack,
    this.onFavorite,
    this.onShare,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1A1A1A),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient with product icon
            Container(
              decoration: BoxDecoration(
                gradient: product.gradient,
              ),
              child: Center(
                child: Icon(
                  product.icon,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 180,
                ).animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutBack),
              ),
            ),

            // Gradient overlay for legibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFF1A1A1A).withValues(alpha: 0.3),
                      const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                      const Color(0xFF1A1A1A),
                    ],
                    stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // Top actions row
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button with glass effect
                  _GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBack,
                  ).animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, delay: 100.ms),

                  // Action buttons
                  Row(
                    children: [
                      if (onFavorite != null)
                        _GlassIconButton(
                          icon: isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: isFavorite ? const Color(0xFFEF4444) : null,
                          onPressed: onFavorite!,
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 150.ms)
                          .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, delay: 150.ms),
                      if (onShare != null) ...[
                        const SizedBox(width: 12),
                        _GlassIconButton(
                          icon: Icons.share_rounded,
                          onPressed: onShare!,
                        ).animate()
                          .fadeIn(duration: 300.ms, delay: 200.ms)
                          .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, delay: 200.ms),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Material badge
            Positioned(
              bottom: 24,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E2E2E).withValues(alpha: 0.9),
                      const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: MaterialGradients.forCategory(product.materialCategory),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.material,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 300.ms, delay: 250.ms)
                .slideX(begin: -0.2, duration: 300.ms, delay: 250.ms, curve: Curves.easeOutQuart),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass morphism icon button used in hero section
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
