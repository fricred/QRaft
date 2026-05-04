import 'dart:async' show unawaited;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../widgets/material_preview_widget.dart';
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

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductVariantEntity variant;

  /// Optional QR code ID passed from the QR library "Engrabar" action.
  /// null = show "Selecciona tu QR" prompt.
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

  Future<void> _addToCart() async {
    // Guard: no QR selected
    if (widget.qrCodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un QR para agregar al carrito'),
        ),
      );
      return;
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
    final matches = qrCodes.where((qr) => qr.id == widget.qrCodeId);
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

      // 2. Add item to cart (pngStorageUrl initially null — patched below)
      await ref.read(cartRepositoryProvider).addItem(
            userId: user.id,
            productVariantId: widget.variant.id,
            qrCodeId: widget.qrCodeId!,
            customizationSnapshot: snapshot.customizationJson,
          );

      // 3. Upload PNG to order-assets/ and patch the cart item's pngStorageUrl.
      //    Runs in background — cart item is already live; PNG is belt-and-suspenders.
      //    Failure here is non-fatal: JSONB snapshot is sufficient for the engraver.
      unawaited(
        _uploadSnapshotPng(
          userId: user.id,
          qrCodeId: widget.qrCodeId!,
          variantId: widget.variant.id,
          pngBytes: snapshot.pngBytes,
        ),
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CartScreen()),
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
          widget.variant.productNameEs,
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
                // 1. QR Preview — wired in plan 07-04
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildPreview(context, ref),
                  ),
                ),

                // 1b. Tattoo-Safe enforcement banner (TAT-02)
                if (widget.variant.isTattooCategory)
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
                      // 2. Product info section
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: widget.variant.material.displayNameEs),
                          _InfoChip(label: widget.variant.sizeLabel),
                          _InfoChip(
                            label:
                                '${widget.variant.widthMm}×${widget.variant.heightMm} mm',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 3. COP Price
                      Text(
                        _formatCop(widget.variant.priceCop),
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Description
                      if (widget.variant.productDescriptionEs != null &&
                          widget.variant.productDescriptionEs!.isNotEmpty) ...[
                        Text(
                          widget.variant.productDescriptionEs!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 5. scanqraft.app info banner
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

                      const SizedBox(height: 32),

                      // 6. CTA button — Phase 8 wired
                      PrimaryGlassButton(
                        text: 'Agregar al carrito',
                        width: double.infinity,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _addToCart,
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
    if (widget.qrCodeId == null) {
      return _SelectQrPrompt(variant: widget.variant);
    }

    final qrCodesAsync = ref.watch(userQRCodesProvider);

    return qrCodesAsync.when(
      loading: () => const _PreviewShimmer(),
      error: (_, __) => const _PreviewError(),
      data: (qrCodes) {
        final matches = qrCodes.where((qr) => qr.id == widget.qrCodeId);
        if (matches.isEmpty) {
          return _SelectQrPrompt(variant: widget.variant);
        }

        return MaterialPreviewWidget(
          qrCode: matches.first,
          material: widget.variant.material,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

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

class _SelectQrPrompt extends StatelessWidget {
  final ProductVariantEntity variant;

  const _SelectQrPrompt({required this.variant});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            color: Color(0xFF00FF88),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Selecciona tu QR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un QR de tu biblioteca\npara ver la vista previa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ir a mi biblioteca'),
          ),
        ],
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
