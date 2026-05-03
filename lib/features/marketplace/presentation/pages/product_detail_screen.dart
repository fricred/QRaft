import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../widgets/material_preview_widget.dart';
import '../../../qr_library/presentation/providers/qr_library_providers.dart';
import '../../../cart/presentation/pages/cart_screen.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/data/repositories/cart_repository_impl.dart';
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

    // Resolve QRCodeEntity from library
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
    final customizationSnapshot = qrCode.customization.toJson();

    setState(() => _isLoading = true);
    try {
      await ref.read(cartRepositoryProvider).addItem(
            userId: user.id,
            productVariantId: widget.variant.id,
            qrCodeId: widget.qrCodeId!,
            customizationSnapshot: customizationSnapshot,
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

                      // 5. qraft.link info banner
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
                                'qraft.link/xxxxxx — podrás cambiar el destino '
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
