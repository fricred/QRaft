import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shimmer/shimmer.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../../../qr_generator/qr_generator_screen.dart';
import '../../../qr_library/presentation/providers/qr_library_providers.dart';

/// Opens the QR picker as a modal bottom sheet and resolves with the chosen
/// [QRCodeEntity], or null when dismissed without choosing.
///
/// [selectedQrId] highlights the currently applied QR (if any).
Future<QRCodeEntity?> showQrPickerSheet(
  BuildContext context, {
  String? selectedQrId,
}) {
  return showModalBottomSheet<QRCodeEntity>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => QrPickerSheet(selectedQrId: selectedQrId),
  );
}

/// Bottom sheet listing the user's QR library as selectable mini previews.
///
/// Fixes the marketplace dead-end where the only way to attach a QR to a
/// purchase was leaving the store and starting over from the QR library.
class QrPickerSheet extends ConsumerWidget {
  final String? selectedQrId;

  const QrPickerSheet({super.key, this.selectedQrId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrCodesAsync = ref.watch(userQRCodesProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elige tu QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este QR será grabado en tu producto',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Flexible(
              child: qrCodesAsync.when(
                loading: () => _buildShimmerGrid(),
                error: (_, __) => _buildMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'No pudimos cargar tus QRs',
                  subtitle: 'Revisa tu conexión e intenta de nuevo',
                ),
                data: (allQrCodes) {
                  // Only codes that scan to real content can be engraved.
                  final qrCodes = allQrCodes.where((q) => q.isPrintable).toList();
                  if (qrCodes.isEmpty) {
                    return _EmptyLibrary(
                      onCreate: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QRGeneratorScreen(),
                          ),
                        );
                      },
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: qrCodes.length,
                    itemBuilder: (_, i) => Semantics(
                      identifier: 'qr_picker_tile_$i',
                      child: _QrTile(
                        qrCode: qrCodes[i],
                        isSelected: qrCodes[i].id == selectedQrId,
                        onTap: () => Navigator.of(context).pop(qrCodes[i]),
                      ),
                    )
                        .animate(delay: (35 * (i % 9)).ms)
                        .fadeIn(duration: 250.ms, curve: Curves.easeOutCubic)
                        .scaleXY(begin: 0.95, duration: 250.ms),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF2E2E2E),
        highlightColor: const Color(0xFF3E3E3E),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: 44),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// A single selectable QR tile: white plate with the real QR render + name.
class _QrTile extends StatelessWidget {
  final QRCodeEntity qrCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _QrTile({
    required this.qrCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = QrDecorationBuilder.buildDecoration(qrCode.customization)
        .copyWith(background: Colors.white);
    final qrImage =
        QrDecorationBuilder.buildQrImage(qrCode.data, qrCode.customization);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF88)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: PrettyQrView(
                      qrImage: qrImage,
                      decoration: decoration,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF88),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF1A1A1A),
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              qrCode.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty-library state: invites the user to create their first QR without
/// abandoning the purchase context further than necessary.
class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyLibrary({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00FF88).withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Color(0xFF00FF88),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes QRs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea tu primer QR y vuelve para grabarlo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: const Color(0xFF1A1A1A),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Crear mi primer QR',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
