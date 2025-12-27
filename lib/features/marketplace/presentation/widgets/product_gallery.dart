import 'package:flutter/material.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Product gallery with horizontal PageView and dot indicators.
/// Falls back to gradient placeholders if no images are provided.
class ProductGallery extends StatefulWidget {
  final List<String> images;
  final LinearGradient gradient;
  final IconData? icon;

  const ProductGallery({
    super.key,
    required this.images,
    required this.gradient,
    this.icon,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Number of placeholder images to show if no real images
  static const int _placeholderCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _itemCount => widget.images.isNotEmpty ? widget.images.length : _placeholderCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            l10n.productGallery,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Gallery PageView
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _itemCount,
              itemBuilder: (context, index) {
                if (widget.images.isNotEmpty) {
                  return _GalleryImage(
                    imageUrl: widget.images[index],
                    gradient: widget.gradient,
                  );
                } else {
                  return _PlaceholderImage(
                    index: index,
                    gradient: widget.gradient,
                    icon: widget.icon,
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Page indicator dots
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_itemCount, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
                          )
                        : null,
                    color: isActive ? null : Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gallery image with network loading
class _GalleryImage extends StatelessWidget {
  final String imageUrl;
  final LinearGradient gradient;

  const _GalleryImage({
    required this.imageUrl,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
              child: const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder image with gradient and icon
class _PlaceholderImage extends StatelessWidget {
  final int index;
  final LinearGradient gradient;
  final IconData? icon;

  const _PlaceholderImage({
    required this.index,
    required this.gradient,
    this.icon,
  });

  // Icons for each placeholder view
  static const _icons = [
    Icons.view_in_ar_rounded,
    Icons.threed_rotation_rounded,
    Icons.qr_code_2_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Localized labels for each placeholder
    final labels = [
      l10n.galleryFrontView,
      l10n.gallery3DPreview,
      l10n.galleryWithQRCode,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter.instance,
            ),
          ),

          // Icon and label
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon ?? _icons[index % _icons.length],
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 64,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[index % labels.length],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid pattern painter for placeholder background
class _GridPatternPainter extends CustomPainter {
  const _GridPatternPainter();

  // Cached instance to avoid recreation on each build
  static const instance = _GridPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
