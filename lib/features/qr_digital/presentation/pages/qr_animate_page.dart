import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../../qr_generator/domain/services/qr_decoration_builder.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../controllers/qr_digital_controller.dart';

/// Screen that previews an animated QR code and allows the user to export
/// it as an animated GIF via the system share sheet.
///
/// Only available for [QRCustomization.profile] == 1 (digitalOnly). The export
/// button is disabled and a banner is shown for other profiles (T-06-06).
class QrAnimatePage extends ConsumerStatefulWidget {
  /// The QR code entity to animate and export.
  final QRCodeEntity entity;

  const QrAnimatePage({super.key, required this.entity});

  @override
  ConsumerState<QrAnimatePage> createState() => _QrAnimatePageState();
}

class _QrAnimatePageState extends ConsumerState<QrAnimatePage> {
  late final PrettyQrDecoration _decoration;
  bool _snackShown = false;

  @override
  void initState() {
    super.initState();
    _decoration =
        QrDecorationBuilder.buildDecoration(widget.entity.customization);
  }

  bool get _isDigitalOnly => widget.entity.customization.profile == 1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrDigitalControllerProvider(widget.entity));

    // Show SnackBar on export error (once per error value).
    ref.listen<QrDigitalState>(qrDigitalControllerProvider(widget.entity),
        (prev, next) {
      if (next.exportError != null && next.exportError != prev?.exportError) {
        _snackShown = false;
      }
      if (next.exportError != null && !_snackShown) {
        _snackShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.exportError!),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Animate QR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // ---------------------------------------------------------------
              // Preview card with flutter_animate opacity pulse
              // ---------------------------------------------------------------
              Semantics(
                identifier: 'qr_animate_preview',
                label: 'Animated QR preview',
                child: Center(
                  child: Container(
                    width: 312, // 280 + 16*2 padding
                    height: 312,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: PrettyQrView.data(
                        data: widget.entity.data,
                        decoration: _decoration,
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 800.ms)
                          .then()
                          .fadeOut(duration: 800.ms),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ---------------------------------------------------------------
              // Profile guard banner
              // ---------------------------------------------------------------
              if (!_isDigitalOnly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[900]!.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red[700]!.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Text(
                      'Animated GIF requires Digital-Only profile. '
                      'Switch profile in editor.',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // ---------------------------------------------------------------
              // Export GIF button
              // ---------------------------------------------------------------
              Semantics(
                identifier: 'qr_animate_export_button',
                label: 'Export animated GIF',
                button: true,
                enabled: _isDigitalOnly && !state.isExporting,
                child: GlassButton(
                  text: 'Export GIF',
                  isLoading: state.isExporting,
                  width: double.infinity,
                  onPressed: _isDigitalOnly && !state.isExporting
                      ? () => ref
                          .read(
                            qrDigitalControllerProvider(widget.entity).notifier,
                          )
                          .exportGif()
                      : null,
                  gradientColors: _isDigitalOnly
                      ? [const Color(0xFF00FF88), const Color(0xFF1A73E8)]
                      : [
                          Colors.grey[800]!.withValues(alpha: 0.4),
                          Colors.grey[900]!.withValues(alpha: 0.5),
                        ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
