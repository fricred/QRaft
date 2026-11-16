import 'dart:async' show unawaited;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/material_preview_widget.dart';
import '../widgets/product_gallery.dart';
import '../widgets/qr_picker_sheet.dart';
import '../widgets/tattoo_profile_enforcement_widget.dart';
import '../../../qr_library/presentation/providers/qr_library_providers.dart';
import '../../../cart/presentation/pages/cart_screen.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/data/repositories/cart_repository_impl.dart';
import '../../../cart/data/datasources/order_assets_storage_data_source.dart';
import '../../../cart/domain/services/customization_snapshot_service.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart';

String _formatCop(int price) =>
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)
        .format(price);

/// Product detail with inline purchase customization:
///
///   1. QR selection — picker bottom sheet, changeable at any time (the QR
///      passed from the library "engrave" action is just the initial value).
///   2. Size selection — sibling variants (same product + material) shown as
///      chips; switching updates price, preview and the variant added to cart.
///   3. Quantity — stepper next to the CTA.
///
/// Add to cart keeps the user in the store (snackbar with "Ver carrito"
/// action) instead of force-navigating to the cart.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductVariantEntity variant;

  /// Optional QR code ID passed from the QR library "engrave" action.
  /// null = the user picks one inline via [QrPickerSheet].
  final String? qrCodeId;

  const ProductDetailScreen({
    super.key,
    required this.variant,
    this.qrCodeId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isLoading = false;
  late ProductVariantEntity _variant;
  String? _qrId;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _variant = widget.variant;
    _qrId = widget.qrCodeId;
  }

  Future<void> _pickQr() async {
    final qr = await showQrPickerSheet(context, selectedQrId: _qrId);
    if (qr != null && mounted) {
      setState(() => _qrId = qr.id);
    }
  }

  Future<void> _addToCart() async {
    // No QR yet: open the picker first — never a dead-end error.
    if (_qrId == null) {
      await _pickQr();
      if (_qrId == null || !mounted) return;
    }

    // Guard: not authenticated
    final user = ref.read(authStateProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    // Resolve QRCodeEntity from already-loaded provider
    final qrCodesAsync = ref.read(userQRCodesProvider);
    final qrCodes = qrCodesAsync.value ?? [];
    final matches = qrCodes.where((qr) => qr.id == _qrId && qr.isPrintable);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR no encontrado en tu biblioteca')),
      );
      return;
    }

    final qrCode = matches.first;

    setState(() => _isLoading = true);
    try {
      // 1. Capture frozen snapshot (JSON + 2160px PNG bytes)
      final snapshot =
          await CustomizationSnapshotService.captureSnapshot(qrCode);

      // 2. Add item to cart (pngStorageUrl initially null — patched below).
      //    The snapshot is enriched with display metadata so CartItemTile can
      //    render product name / material / size / unit price without a join
      //    (frozen at add-time, consistent with the snapshot's purpose).
      await ref.read(cartRepositoryProvider).addItem(
            userId: user.id,
            productVariantId: _variant.id,
            qrCodeId: _qrId!,
            quantity: _quantity,
            customizationSnapshot: {
              ...snapshot.customizationJson,
              'product_name': _variant.productNameEs,
              'material_name': _variant.material.displayNameEs,
              'size_label': _variant.sizeLabel,
              'unit_price_cop': _variant.priceCop,
            },
          );

      // 3. Upload PNG to order-assets/ and patch the cart item's pngStorageUrl.
      //    Runs in background — cart item is already live; PNG is belt-and-suspenders.
      //    Failure here is non-fatal: JSONB snapshot is sufficient for the engraver.
      unawaited(
        _uploadSnapshotPng(
          userId: user.id,
          qrCodeId: _qrId!,
          variantId: _variant.id,
          pngBytes: snapshot.pngBytes,
        ),
      );

      // Restart the cart stream: cart_items has no realtime publication yet
      // (see migration 20260612000000), so watchers would otherwise keep a
      // stale snapshot. Invalidate = fresh initial fetch; .when's default
      // skipLoadingOnRefresh keeps previous data visible meanwhile.
      ref.invalidate(cartItemsProvider);

      if (!mounted) return;
      // Keep the user shopping: confirm + offer the cart, don't force it.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _quantity == 1
                ? 'Agregado al carrito'
                : '$_quantity unidades agregadas al carrito',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E2E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFF00FF88).withValues(alpha: 0.4),
            ),
          ),
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: const Color(0xFF00FF88),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
    } on CartException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar al carrito')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Uploads the pre-rasterized PNG to Supabase Storage order-assets/ bucket,
  /// then patches the cart item's png_storage_url column.
  ///
  /// Non-blocking: called via [unawaited] — failures are logged in debug mode
  /// only. The JSONB customization_snapshot is the canonical engraver input.
  Future<void> _uploadSnapshotPng({
    required String userId,
    required String qrCodeId,
    required String variantId,
    required Uint8List pngBytes,
  }) async {
    try {
      final storageDs =
          OrderAssetsStorageDataSource(Supabase.instance.client);
      final pngUrl = await storageDs.upload(
        userId: userId,
        qrCodeId: qrCodeId,
        variantId: variantId,
        pngBytes: pngBytes,
      );

      // Resolve the cart item id by (user_id, product_variant_id, qr_code_id)
      // unique constraint — avoids exposing updatePngUrl in CartRepository.
      final cartItemId =
          await _resolveCartItemId(userId, variantId, qrCodeId);
      await storageDs.patchPngUrl(cartItemId, pngUrl);
    } catch (e) {
      // Non-fatal: JSONB snapshot is the source of truth.
      // Log in debug mode only (never in release).
      assert(() {
        // ignore: avoid_print
        print('[CartSnapshot] PNG upload failed: $e');
        return true;
      }());
    }
  }

  /// Resolves the cart item id from the (userId, variantId, qrCodeId) triple.
  ///
  /// Uses a direct Supabase query rather than going through CartRepository to
  /// keep the repository interface minimal (single-responsibility principle).
  Future<String> _resolveCartItemId(
    String userId,
    String variantId,
    String qrCodeId,
  ) async {
    final row = await Supabase.instance.client
        .from('cart_items')
        .select('id')
        .eq('user_id', userId)
        .eq('product_variant_id', variantId)
        .eq('qr_code_id', qrCodeId)
        .single();
    return row['id'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          _variant.productNameEs,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Gallery — live preview on slide 0, real photos behind it.
                //    With no photos this collapses to exactly the preview that
                //    used to live here.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ProductGallery(
                      images: _variant.images,
                      preview: _buildPreview(context, ref),
                      // "tu QR" is only true once one has been picked.
                      previewCaption: _qrId == null
                          ? 'Vista previa'
                          : 'Vista previa · tu QR',
                      photoSemanticsLabel:
                          '${_variant.productNameEs} en '
                          '${_variant.material.displayNameEs}',
                    ),
                  ),
                ),

                // 1b. Tattoo-Safe enforcement banner (TAT-02)
                if (_variant.isTattooCategory)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: const [
                        TattooProfileEnforcementWidget(),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Product info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: _variant.material.displayNameEs),
                          _InfoChip(
                            label:
                                '${_variant.widthMm}×${_variant.heightMm} mm',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 3. Size selector (sibling variants) — hidden when the
                      // product only comes in one size.
                      _SizeSelector(
                        current: _variant,
                        onChanged: (v) => setState(() => _variant = v),
                      ),

                      // 4. COP price — animates on size change
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _formatCop(_variant.priceCop),
                          key: ValueKey(_variant.id),
                          style: const TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. Description
                      if (_variant.productDescriptionEs != null &&
                          _variant.productDescriptionEs!.isNotEmpty) ...[
                        Text(
                          _variant.productDescriptionEs!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 6. scanqraft.app info banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tu QR será grabado apuntando a: '
                                'scanqraft.app/xxxxxx — podrás cambiar el destino '
                                'después de recibir tu producto.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 7. Quantity stepper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cantidad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _QuantityStepper(
                            quantity: _quantity,
                            onChanged: (q) => setState(() => _quantity = q),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 8. CTA — shows the QR step or the line total
                      Semantics(
                        identifier: 'product_add_to_cart_button',
                        child: PrimaryGlassButton(
                          text: _qrId == null
                              ? 'Elegir QR y agregar'
                              : 'Agregar · ${_formatCop(_variant.priceCop * _quantity)}',
                          width: double.infinity,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _addToCart,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, WidgetRef ref) {
    if (_qrId == null) {
      return _SelectQrPrompt(onPick: _pickQr);
    }

    final qrCodesAsync = ref.watch(userQRCodesProvider);

    return qrCodesAsync.when(
      loading: () => const _PreviewShimmer(),
      error: (_, __) => const _PreviewError(),
      data: (qrCodes) {
        final matches = qrCodes.where((qr) => qr.id == _qrId);
        if (matches.isEmpty) {
          return _SelectQrPrompt(onPick: _pickQr);
        }

        return GestureDetector(
          onTap: _pickQr,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: MaterialPreviewWidget(
                  key: ValueKey(_qrId),
                  qrCode: matches.first,
                  material: _variant.material,
                ),
              ),
              // "Change QR" affordance over the preview
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF00FF88),
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cambiar QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// Chips listing every size of the same product + material; switching size
/// swaps the active variant (price, dimensions, cart payload).
class _SizeSelector extends ConsumerWidget {
  final ProductVariantEntity current;
  final ValueChanged<ProductVariantEntity> onChanged;

  const _SizeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value ?? [];
    final siblings = catalog
        .where((v) =>
            v.productId == current.productId &&
            v.material.id == current.material.id)
        .toList()
      ..sort((a, b) => a.priceCop.compareTo(b.priceCop));

    // Single size: nothing to choose.
    if (siblings.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tamaño',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in siblings)
              GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: v.id == current.id
                        ? const Color(0xFF00FF88).withValues(alpha: 0.12)
                        : const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: v.id == current.id
                          ? const Color(0xFF00FF88)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    v.sizeLabel,
                    style: TextStyle(
                      color: v.id == current.id
                          ? const Color(0xFF00FF88)
                          : Colors.grey[300],
                      fontSize: 13,
                      fontWeight: v.id == current.id
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Horizontal quantity stepper pill: [−] qty [+], capped 1-99.
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            accent: true,
            onTap: quantity < 99 ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;

  const _StepBtn({required this.icon, this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          size: 20,
          color: !enabled
              ? Colors.grey[700]
              : accent
                  ? const Color(0xFF00FF88)
                  : Colors.grey[300],
        ),
      ),
    );
  }
}

class _PreviewShimmer extends StatelessWidget {
  const _PreviewShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2E2E2E),
      highlightColor: const Color(0xFF3E3E3E),
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF2E2E2E),
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey[400],
          size: 48,
        ),
      ),
    );
  }
}

/// Prompt shown while no QR is selected — opens the picker right here
/// instead of bouncing the user out of the purchase flow.
class _SelectQrPrompt extends StatelessWidget {
  final VoidCallback onPick;

  const _SelectQrPrompt({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF00FF88),
                size: 36,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.06,
                  duration: 1800.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 14),
            const Text(
              'Selecciona tu QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Así se verá grabado en el material',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'product_select_qr_button',
              child: ElevatedButton.icon(
                onPressed: onPick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: const Text(
                  'Elegir de mi biblioteca',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 13,
        ),
      ),
    );
  }
}
