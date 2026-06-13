import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';

String _formatCop(int priceCop) =>
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)
        .format(priceCop);

/// A dark glassmorphism card for a single [ProductVariantEntity].
///
/// Thumbnail composites the real material texture ([MaterialEntity.textureUrl],
/// gradient fallback) with a white "laser-engraved QR" plate — same visual
/// language as [MaterialPreviewWidget] on the detail screen.
///
/// [index] drives the staggered entrance animation (capped so lazily-built
/// items deep in the grid don't wait on long delays).
class ProductVariantCard extends StatefulWidget {
  final ProductVariantEntity variant;
  final VoidCallback onTap;
  final int index;

  const ProductVariantCard({
    super.key,
    required this.variant,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<ProductVariantCard> createState() => _ProductVariantCardState();
}

class _ProductVariantCardState extends State<ProductVariantCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.variant;

    return Semantics(
      identifier: 'marketplace_product_card_${widget.index}',
      child: GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? const Color(0xFF00FF88).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              if (_pressed)
                BoxShadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material texture + engraved QR plate
              Expanded(
                flex: 11,
                child: _MaterialThumbnail(variant: variant),
              ),

              // Card body
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.productNameEs,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            color: Colors.grey[500],
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              variant.sizeLabel,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _formatCop(variant.priceCop),
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: _pressed
                                  ? const Color(0xFF00FF88)
                                  : Colors.grey[400],
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    )
        .animate(delay: (60 * (widget.index % 6)).ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.12, duration: 350.ms, curve: Curves.easeOutQuart)
        .scaleXY(begin: 0.97, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

/// Texture image (gradient fallback) + scrim + white engraved-QR plate +
/// material chip. Mirrors the MaterialPreviewWidget composite at card scale.
class _MaterialThumbnail extends StatelessWidget {
  final ProductVariantEntity variant;

  const _MaterialThumbnail({required this.variant});

  @override
  Widget build(BuildContext context) {
    final material = variant.material;
    final hasTexture =
        material.textureUrl.isNotEmpty && material.textureUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: material texture or gradient fallback
          if (hasTexture)
            CachedNetworkImage(
              imageUrl: material.textureUrl,
              fit: BoxFit.cover,
              memCacheWidth: 480,
              placeholder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: MaterialGradients.forCategory(material.id),
                ),
              ),
              errorWidget: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: MaterialGradients.forCategory(material.id),
                ),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: MaterialGradients.forCategory(material.id),
              ),
            ),

          // Layer 2: bottom scrim so the chip stays legible on any texture
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),

          // Layer 3: white engraved-QR plate, centered
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF1A1A1A),
                size: 40,
              ),
            ),
          ),

          // Layer 4: material chip, bottom-left
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                material.displayNameEs,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton matching [ProductVariantCard] layout.
class ProductVariantCardShimmer extends StatelessWidget {
  const ProductVariantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2E2E2E),
      highlightColor: const Color(0xFF3E3E3E),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texture placeholder — matches the 11/9 flex split of the card
            Expanded(
              flex: 11,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF3E3E3E),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(15)),
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3E3E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3E3E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 15,
                          width: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E3E3E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3E3E3E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
