import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';

String _formatCop(int price) =>
    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0)
        .format(price);

class ProductDetailScreen extends ConsumerWidget {
  final ProductVariantEntity variant;

  /// Optional QR code ID — wired in plan 07-04; null shows placeholder prompt.
  final String? qrCodeId;

  const ProductDetailScreen({
    super.key,
    required this.variant,
    this.qrCodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          variant.productNameEs,
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
                // 1. QR Preview placeholder — plan 07-03 will replace this
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: MaterialGradients.forCategory(
                            variant.material.id),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Vista previa del QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Anchor key for plan 07-03 to locate and replace this widget
                    const SizedBox.shrink(key: Key('qr_preview_placeholder')),
                  ],
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
                          _InfoChip(label: variant.material.displayNameEs),
                          _InfoChip(label: variant.sizeLabel),
                          _InfoChip(
                            label:
                                '${variant.widthMm}×${variant.heightMm} mm',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 3. COP Price
                      Text(
                        _formatCop(variant.priceCop),
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Description
                      if (variant.productDescriptionEs != null &&
                          variant.productDescriptionEs!.isNotEmpty) ...[
                        Text(
                          variant.productDescriptionEs!,
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

                      // 6. CTA button (Phase 8 placeholder)
                      PrimaryGlassButton(
                        text: 'Agregar al carrito',
                        width: double.infinity,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Carrito disponible en la próxima actualización',
                              ),
                            ),
                          );
                        },
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
