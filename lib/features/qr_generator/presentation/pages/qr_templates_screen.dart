// Screen 2 of the QR creation flow: pick a visual template.
// TypePicker → [this screen] → QRCanvasEditorScreen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../domain/entities/qr_code_entity.dart';
import '../../domain/entities/qr_type.dart';
import '../../domain/services/qr_decoration_builder.dart';
import '../controllers/qr_customization_controller.dart';
import 'qr_canvas_editor_screen.dart';

const _kBg = Color(0xFF1A1A1A);
const _kSurface = Color(0xFF2E2E2E);
const _kNeon = Color(0xFF00FF88);
const _kLine = Color(0xFF3A3A3A);

const _templateTags = {
  'classic': 'Most scannable',
  'ocean_blue': 'Corporate',
  'neon_green': 'Digital only',
  'elegant_purple': 'Premium',
  'charcoal': 'Print safe',
  'sunset_gradient': 'Gradient',
  'corporate': 'Minimal',
  'tattoo_safe': 'Permanent',
};

class QRTemplatesScreen extends ConsumerStatefulWidget {
  final QRType qrType;
  const QRTemplatesScreen({super.key, required this.qrType});

  @override
  ConsumerState<QRTemplatesScreen> createState() => _QRTemplatesScreenState();
}

class _QRTemplatesScreenState extends ConsumerState<QRTemplatesScreen> {
  QrFullTemplate _selected = kQrTemplates.first;

  void _onContinue() {
    ref.read(qrCustomizationControllerProvider.notifier).applyFullTemplate(_selected);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QRCanvasEditorScreen(qrType: widget.qrType, template: _selected),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text(
                    'Step 2 of 2',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF888888)),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                      children: [
                        const TextSpan(text: 'Pick a '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [_kNeon, Color(0xFF1A73E8)],
                            ).createShader(r),
                            child: const Text(
                              'style',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TypeIcon(qrType: widget.qrType),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For ${widget.qrType.getDisplayName(context)} · You can change anything next',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Template grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: kQrTemplates.length,
                itemBuilder: (context, i) {
                  final tpl = kQrTemplates[i];
                  final isSel = _selected.id == tpl.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = tpl),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel ? _kNeon : _kLine,
                          width: isSel ? 2 : 1,
                        ),
                        boxShadow: isSel
                            ? [BoxShadow(color: _kNeon.withValues(alpha: 0.22), blurRadius: 14, spreadRadius: 2)]
                            : null,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(8),
                                    child: _QRThumbnail(customization: tpl.customization),
                                  ),
                                ),
                                if (isSel)
                                  Positioned(
                                    top: 6, right: 6,
                                    child: Container(
                                      width: 22, height: 22,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _kNeon),
                                      child: const Icon(Icons.check, size: 14, color: Color(0xFF0A1810)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(tpl.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            _templateTags[tpl.id] ?? '',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 280.ms, delay: Duration(milliseconds: i * 35));
                },
              ),
            ),

            // Footer CTA
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: GestureDetector(
                onTap: _onContinue,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kNeon, Color(0xFF1A73E8)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0A1810))),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF0A1810)),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kSurface,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final QRType qrType;
  const _TypeIcon({required this.qrType});

  @override
  Widget build(BuildContext context) {
    final accent = Color(qrType.gradientColors.first);
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: accent.withValues(alpha: 0.15),
      ),
      child: Icon(_iconForType(qrType), size: 13, color: accent),
    );
  }

  IconData _iconForType(QRType t) => switch (t) {
        QRType.personalInfo => Icons.person_rounded,
        QRType.url => Icons.link_rounded,
        QRType.wifi => Icons.wifi_rounded,
        QRType.text => Icons.text_fields_rounded,
        QRType.email => Icons.email_rounded,
        QRType.location => Icons.location_on_rounded,
        QRType.event => Icons.event_rounded,
      };
}

class _QRThumbnail extends StatefulWidget {
  final QRCustomization customization;
  const _QRThumbnail({required this.customization});

  @override
  State<_QRThumbnail> createState() => _QRThumbnailState();
}

class _QRThumbnailState extends State<_QRThumbnail> {
  QrImage? _qrImage;

  @override
  void initState() {
    super.initState();
    try {
      _qrImage = QrDecorationBuilder.buildQrImage('https://qraft.app', widget.customization);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_qrImage == null) {
      return const Center(child: Icon(Icons.qr_code_rounded, color: Color(0xFF888888), size: 32));
    }
    return PrettyQrView(
      qrImage: _qrImage!,
      decoration: QrDecorationBuilder.buildDecoration(
        widget.customization,
        quietZone: const PrettyQrQuietZone.pixels(2),
      ),
    );
  }
}
