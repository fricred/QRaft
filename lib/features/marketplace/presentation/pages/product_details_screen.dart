import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/product_entity.dart';
import '../widgets/product_hero_section.dart';
import '../widgets/product_info_section.dart';
import '../widgets/customization_section.dart';
import '../widgets/product_gallery.dart';
import '../widgets/features_section.dart';
import '../widgets/bottom_action_bar.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Full-screen product details page with parallax hero, customization options,
/// and animated add-to-cart functionality.
class ProductDetailsScreen extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  // Customization state
  String _selectedSize = 'M';
  ProductFinish? _selectedFinish;
  int _quantity = 1;

  // UI state
  bool _isAddingToCart = false;
  bool _addedToCart = false;

  // Scroll controller for parallax effects
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedFinish = widget.product.availableFinishes.isNotEmpty
        ? widget.product.availableFinishes.first
        : ProductFinish.defaultFinishes.first;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Calculate total price including finish modifier
  double get _totalPrice {
    final basePrice = widget.product.price;
    final finishModifier = _selectedFinish?.priceModifier ?? 0.0;
    return (basePrice + finishModifier) * _quantity;
  }

  void _onSizeChanged(String size) {
    HapticFeedback.selectionClick();
    setState(() => _selectedSize = size);
  }

  void _onFinishChanged(ProductFinish finish) {
    HapticFeedback.selectionClick();
    setState(() => _selectedFinish = finish);
  }

  void _onQuantityChanged(int quantity) {
    if (quantity < 1 || quantity > 99) return;
    HapticFeedback.selectionClick();
    setState(() => _quantity = quantity);
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      HapticFeedback.mediumImpact();
      setState(() => _isAddingToCart = true);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      setState(() {
        _isAddingToCart = false;
        _addedToCart = true;
      });

      HapticFeedback.heavyImpact();

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: widget.product.gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.product.icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${widget.product.name} ${l10n.addedToCart}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E2E2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: l10n.viewCart,
            textColor: const Color(0xFF00FF88),
            onPressed: () {
              // TODO: Navigate to cart
            },
          ),
        ),
      );

      // Reset state after animation
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _addedToCart = false);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isAddingToCart = false);

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.errorAddingToCart),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero section with parallax
              ProductHeroSection(
                product: widget.product,
                scrollController: _scrollController,
                onBack: () => Navigator.of(context).pop(),
              ),

              // Content sections
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info section
                    ProductInfoSection(
                      product: widget.product,
                    ).animate()
                      .fadeIn(duration: 300.ms, delay: 100.ms)
                      .slideY(begin: 0.1, duration: 300.ms, delay: 100.ms, curve: Curves.easeOutQuart),

                    const SizedBox(height: 24),

                    // Customization section
                    CustomizationSection(
                      availableSizes: widget.product.availableSizes,
                      selectedSize: _selectedSize,
                      onSizeChanged: _onSizeChanged,
                      availableFinishes: widget.product.availableFinishes.isNotEmpty
                          ? widget.product.availableFinishes
                          : ProductFinish.defaultFinishes,
                      selectedFinish: _selectedFinish,
                      onFinishChanged: _onFinishChanged,
                    ).animate()
                      .fadeIn(duration: 350.ms, delay: 200.ms)
                      .slideY(begin: 0.1, duration: 350.ms, delay: 200.ms, curve: Curves.easeOutQuart),

                    const SizedBox(height: 24),

                    // Gallery section (if images available)
                    if (widget.product.galleryImages.isNotEmpty)
                      ProductGallery(
                        images: widget.product.galleryImages,
                        gradient: widget.product.gradient,
                      ).animate()
                        .fadeIn(duration: 350.ms, delay: 250.ms)
                        .slideY(begin: 0.1, duration: 350.ms, delay: 250.ms, curve: Curves.easeOutQuart),

                    // Placeholder gallery if no images
                    if (widget.product.galleryImages.isEmpty)
                      ProductGallery(
                        images: const [],
                        gradient: widget.product.gradient,
                        icon: widget.product.icon,
                      ).animate()
                        .fadeIn(duration: 350.ms, delay: 250.ms)
                        .slideY(begin: 0.1, duration: 350.ms, delay: 250.ms, curve: Curves.easeOutQuart),

                    const SizedBox(height: 24),

                    // Features section
                    FeaturesSection(
                      features: widget.product.features.isNotEmpty
                          ? widget.product.features
                          : [
                              l10n.featurePrecisionEngraving,
                              '${l10n.featureHighQuality} ${widget.product.material}',
                              l10n.featureCustomQRDesign,
                              l10n.featureDurable,
                            ],
                    ).animate()
                      .fadeIn(duration: 350.ms, delay: 300.ms)
                      .slideY(begin: 0.1, duration: 350.ms, delay: 300.ms, curve: Curves.easeOutQuart),

                    // Bottom padding for action bar
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),

          // Fixed bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomActionBar(
              quantity: _quantity,
              onQuantityChanged: _onQuantityChanged,
              totalPrice: _totalPrice,
              currency: widget.product.currency,
              isLoading: _isAddingToCart,
              isSuccess: _addedToCart,
              onAddToCart: _handleAddToCart,
            ).animate()
              .fadeIn(duration: 400.ms, delay: 350.ms)
              .slideY(begin: 0.3, duration: 400.ms, delay: 350.ms, curve: Curves.easeOutQuart),
          ),
        ],
      ),
    );
  }
}
