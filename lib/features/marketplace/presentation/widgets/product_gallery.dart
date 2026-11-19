import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../domain/entities/product_image_entity.dart';

const _kAccent = Color(0xFF00FF88);
const _kSurface = Color(0xFF2E2E2E);

/// One swipeable strip holding the live QR preview *and* the real product
/// photos, plus a thumbnail rail to jump between them.
///
/// **Slide 0 is always [preview].** Two independent reasons, both hard:
///
///   - `PageView` only builds the current page and its neighbours. The purchase
///     flow taps `product_select_qr_button`, which lives inside the preview. On
///     a later slide that widget would not exist until the user swiped, so the
///     E2E flow — and anyone navigating with a screen reader from the top —
///     would never reach it.
///   - The preview is what the app sells: the buyer's own QR composited on the
///     material. Demoting it behind marketing photos inverts the value prop.
///
/// Every slide carries a caption chip — "Vista previa · tu QR" against "Foto
/// real del producto". That distinction is not decoration: under Ley 1480 de
/// 2011 art. 30 a simulation presented as the delivered article is misleading
/// advertising, so the render itself has to say which one the buyer is seeing.
///
/// With no photos the widget returns [preview] untouched — no `PageView`, no
/// chips, no rail — so a catalog without photography renders exactly as before.
class ProductGallery extends StatefulWidget {
  /// The live composite (or its shimmer / error / "pick a QR" stand-ins). Taken
  /// as a widget so the gallery stays free of Riverpod and QR resolution.
  final Widget preview;

  /// Photos for the current variant, already ordered most-specific-first.
  final List<ProductImageEntity> images;

  /// Side of the square slide. Matches `MaterialPreviewWidget.previewSize`.
  final double size;

  /// Caption for slide 0. The caller varies it because "tu QR" is only true
  /// once a QR has actually been picked.
  final String previewCaption;

  /// Used as the accessible label of a photo whose row has no `alt_text_es`.
  final String photoSemanticsLabel;

  const ProductGallery({
    super.key,
    required this.preview,
    required this.images,
    this.size = 280,
    this.previewCaption = 'Vista previa · tu QR',
    this.photoSemanticsLabel = 'Foto del producto',
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching size swaps the variant, which may carry fewer photos. Without
    // this the controller would sit on a page that no longer exists.
    final lastPage = widget.images.length;
    if (_page > lastPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(lastPage);
        setState(() => _page = lastPage);
      });
    }
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to carousel through: hand back the preview as-is.
    if (widget.images.isEmpty) return widget.preview;

    final pageCount = widget.images.length + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          // Extra room so the slides' drop shadow isn't clipped by the viewport.
          height: widget.size + 24,
          child: PageView.builder(
            controller: _controller,
            itemCount: pageCount,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => Center(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: index == 0
                          ? Center(child: widget.preview)
                          : _GalleryPhoto(
                              image: widget.images[index - 1],
                              size: widget.size,
                              fallbackLabel: widget.photoSemanticsLabel,
                            ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _CaptionChip(
                        label: index == 0
                            ? widget.previewCaption
                            : 'Foto real del producto',
                        isPreview: index == 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ThumbRail(
          images: widget.images,
          activeIndex: _page,
          onTap: _goTo,
        ),
      ],
    );
  }
}

/// A single real photograph, sized and shadowed to sit flush with the live
/// preview so swiping between them doesn't jump.
class _GalleryPhoto extends StatelessWidget {
  final ProductImageEntity image;
  final double size;
  final String fallbackLabel;

  const _GalleryPhoto({
    required this.image,
    required this.size,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: image.altTextEs.isEmpty ? fallbackLabel : image.altTextEs,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: image.url,
            fit: BoxFit.cover,
            width: size,
            height: size,
            memCacheWidth: 900,
            placeholder: (_, __) => _SquareShimmer(size: size),
            errorWidget: (_, __, ___) => _PhotoUnavailable(size: size),
          ),
        ),
      ),
    );
  }
}

/// Legend that tells the buyer whether they are looking at a simulation or at
/// the physical article. Neon for the preview, neutral for a photo.
class _CaptionChip extends StatelessWidget {
  final String label;
  final bool isPreview;

  const _CaptionChip({required this.label, required this.isPreview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPreview
              ? _kAccent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPreview
                ? Icons.auto_awesome_rounded
                : Icons.photo_camera_outlined,
            size: 13,
            color: isPreview ? _kAccent : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thumbnail rail. Tile 0 stands for the live preview, the rest are photos.
///
/// Centred while the tiles fit and scrollable once they don't, so a product
/// with two photos doesn't look left-adrift under a centred carousel.
class _ThumbRail extends StatelessWidget {
  final List<ProductImageEntity> images;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _ThumbRail({
    required this.images,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Unbounded width would make minWidth infinite; fall back to letting
          // the row size itself.
          final available = constraints.maxWidth.isFinite
              ? (constraints.maxWidth - 48).clamp(0.0, double.infinity)
              : 0.0;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: available),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= images.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _Thumb(
                      index: i,
                      image: i == 0 ? null : images[i - 1],
                      isActive: i == activeIndex,
                      onTap: () => onTap(i),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final int index;

  /// null marks the live-preview tile.
  final ProductImageEntity? image;
  final bool isActive;
  final VoidCallback onTap;

  const _Thumb({
    required this.index,
    required this.image,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'product_gallery_thumb_$index',
      button: true,
      selected: isActive,
      label: image == null ? 'Vista previa con tu QR' : 'Foto $index',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? _kAccent
                  : Colors.white.withValues(alpha: 0.12),
              width: isActive ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: image == null
                ? const Icon(
                    Icons.qr_code_2_rounded,
                    color: _kAccent,
                    size: 26,
                  )
                : CachedNetworkImage(
                    imageUrl: image!.gridUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 160,
                    placeholder: (_, __) => const _SquareShimmer(size: 52),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SquareShimmer extends StatelessWidget {
  final double size;
  const _SquareShimmer({required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kSurface,
      highlightColor: const Color(0xFF3E3E3E),
      child: Container(width: size, height: size, color: _kSurface),
    );
  }
}

class _PhotoUnavailable extends StatelessWidget {
  final double size;
  const _PhotoUnavailable({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: _kSurface,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey[500],
          size: 44,
        ),
      ),
    );
  }
}
