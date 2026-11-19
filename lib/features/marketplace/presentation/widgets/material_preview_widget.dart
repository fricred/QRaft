import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shimmer/shimmer.dart';

import '../../../marketplace/domain/entities/material_entity.dart';
import '../../../marketplace/domain/entities/product_entity.dart'
    show MaterialGradients;
import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';

/// Composites a live QR code preview on top of a material texture image.
///
/// Layer 1 (bottom): CachedNetworkImage showing material texture (full bleed).
///   - Falls back to MaterialGradients.forCategory gradient when textureUrl is
///     empty OR when the image load fails.
///   - Shows a shimmer placeholder while loading.
///
/// Layer 2 (top): PrettyQrView inside a white-background container (72% of
///   previewSize), centered over the texture. White background is FORCED via
///   decoration.copyWith(background: Colors.white) — mirrors QrExportService
///   contract so preview and export are visually consistent.
///
/// Why Stack + white label instead of BlendMode:
///   BlendMode.multiply would merge QR modules with wood grain, degrading
///   scannability. Physical laser-engraved products use a white pad approach.
class MaterialPreviewWidget extends StatelessWidget {
  final QRCodeEntity qrCode;
  final MaterialEntity material;
  final double previewSize;

  const MaterialPreviewWidget({
    super.key,
    required this.qrCode,
    required this.material,
    this.previewSize = 280,
  });

  @override
  Widget build(BuildContext context) {
    // Build QR decoration once. Force white background regardless of customization.
    final rawDecoration = QrDecorationBuilder.buildDecoration(qrCode.customization);
    final previewDecoration = rawDecoration.copyWith(background: Colors.white);
    final qrImage = QrDecorationBuilder.buildQrImage(qrCode.data, qrCode.customization);

    final labelSize = previewSize * 0.72;

    return Container(
      width: previewSize,
      height: previewSize,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: material texture (full bleed)
            Positioned.fill(
              child: _MaterialTexture(
                textureUrl: material.textureUrl,
                materialId: material.id,
                previewSize: previewSize,
              ),
            ),
            // Layer 2: white QR label centered on texture
            Container(
              width: labelSize,
              height: labelSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: PrettyQrView(
                qrImage: qrImage,
                decoration: previewDecoration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Private widget handling texture URL load + gradient fallback.
class _MaterialTexture extends StatelessWidget {
  final String textureUrl;
  final String materialId;
  final double previewSize;

  const _MaterialTexture({
    required this.textureUrl,
    required this.materialId,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: empty URL goes straight to gradient fallback (avoids CachedNetworkImage crash).
    if (textureUrl.isEmpty || !textureUrl.startsWith('https://')) {
      return _GradientFallback(materialId: materialId);
    }
    return CachedNetworkImage(
      imageUrl: textureUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => _ShimmerBox(size: previewSize),
      errorWidget: (_, __, ___) => _GradientFallback(materialId: materialId),
    );
  }
}

/// Gradient fallback when texture image is unavailable.
class _GradientFallback extends StatelessWidget {
  final String materialId;
  const _GradientFallback({required this.materialId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: MaterialGradients.forCategory(materialId),
      ),
    );
  }
}

/// Shimmer placeholder matching texture container dimensions.
class _ShimmerBox extends StatelessWidget {
  final double size;
  const _ShimmerBox({required this.size});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2E2E2E),
      highlightColor: const Color(0xFF3E3E3E),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2E2E2E),
      ),
    );
  }
}
