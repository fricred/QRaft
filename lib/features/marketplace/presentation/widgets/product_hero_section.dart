import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/product_entity.dart';

/// Hero section with parallax SliverAppBar for product details.
/// Features persistent navigation, collapsed title, and glassmorphism effects.
class ProductHeroSection extends StatefulWidget {
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
  State<ProductHeroSection> createState() => _ProductHeroSectionState();
}

class _ProductHeroSectionState extends State<ProductHeroSection> {
  double _scrollProgress = 0.0;

  static const double _expandedHeight = 320.0;
  static const double _collapsedHeight = kToolbarHeight;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final topPadding = MediaQuery.of(context).padding.top;
    final maxScroll = _expandedHeight - _collapsedHeight - topPadding;
    final scrollOffset = widget.scrollController.offset;

    final newProgress = (scrollOffset / maxScroll).clamp(0.0, 1.0);
    if ((newProgress - _scrollProgress).abs() > 0.01) {
      setState(() {
        _scrollProgress = newProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: _expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      // Collapsed title (fades in on scroll)
      title: _buildCollapsedTitle(),
      titleSpacing: 0,
      centerTitle: true,
      // Persistent leading button
      leading: _buildLeadingButton(),
      leadingWidth: 60,
      // Persistent action buttons
      actions: _buildActions(),
      flexibleSpace: _buildFlexibleSpace(topPadding),
    );
  }

  /// Collapsed title with product name and price
  Widget _buildCollapsedTitle() {
    // Only show when scrolled past 60%
    final titleOpacity = ((_scrollProgress - 0.6) / 0.4).clamp(0.0, 1.0);

    if (titleOpacity <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: titleOpacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini product icon with gradient
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: widget.product.gradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.product.icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // Product name and price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.product.formattedPrice,
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Persistent back button
  Widget _buildLeadingButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: widget.onBack,
          backgroundOpacity: 0.3 + (0.4 * _scrollProgress),
        ),
      ),
    );
  }

  /// Persistent action buttons
  List<Widget> _buildActions() {
    return [
      if (widget.onFavorite != null)
        Center(
          child: _GlassIconButton(
            icon: widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: widget.isFavorite ? const Color(0xFFEF4444) : null,
            onPressed: widget.onFavorite!,
            backgroundOpacity: 0.3 + (0.4 * _scrollProgress),
          ),
        ),
      if (widget.onShare != null) ...[
        const SizedBox(width: 8),
        Center(
          child: _GlassIconButton(
            icon: Icons.share_rounded,
            onPressed: widget.onShare!,
            backgroundOpacity: 0.3 + (0.4 * _scrollProgress),
          ),
        ),
      ],
      const SizedBox(width: 8),
    ];
  }

  /// Flexible space with hero background and glassmorphism overlay
  Widget _buildFlexibleSpace(double topPadding) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero background
        FlexibleSpaceBar(
          stretchModes: const [
            StretchMode.zoomBackground,
            StretchMode.blurBackground,
          ],
          background: _buildHeroBackground(),
        ),

        // Glassmorphism overlay that increases with scroll
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topPadding + kToolbarHeight,
          child: _buildGlassmorphismBar(),
        ),
      ],
    );
  }

  /// Hero background with gradient, icon, and material badge
  Widget _buildHeroBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient with product icon
        Container(
          decoration: BoxDecoration(
            gradient: widget.product.gradient,
          ),
          child: Center(
            child: Icon(
              widget.product.icon,
              color: Colors.white.withValues(alpha: 0.3),
              size: 180,
            ).animate()
              .fadeIn(duration: 400.ms)
              .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 400.ms,
                  curve: Curves.easeOutBack),
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

        // Material badge (fades out on scroll)
        Positioned(
          bottom: 24,
          left: 24,
          child: Opacity(
            opacity: (1.0 - _scrollProgress * 1.5).clamp(0.0, 1.0),
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
                      gradient: MaterialGradients.forCategory(
                          widget.product.materialCategory),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.product.material,
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
              .slideX(
                  begin: -0.2,
                  duration: 300.ms,
                  delay: 250.ms,
                  curve: Curves.easeOutQuart),
          ),
        ),
      ],
    );
  }

  /// Glassmorphism bar overlay with dynamic blur
  Widget _buildGlassmorphismBar() {
    if (_scrollProgress < 0.1) return const SizedBox.shrink();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15 * _scrollProgress,
          sigmaY: 15 * _scrollProgress,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E2E2E).withValues(alpha: 0.7 * _scrollProgress),
                Color(0xFF1A1A1A).withValues(alpha: 0.85 * _scrollProgress),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1 * _scrollProgress),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass morphism icon button with dynamic opacity
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final double backgroundOpacity;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.backgroundOpacity = 0.6,
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
                color: Color(0xFF2E2E2E).withValues(alpha: backgroundOpacity),
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
