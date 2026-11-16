import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../domain/services/qr_decoration_builder.dart';
import '../../domain/value_objects/qr_profile.dart';
import '../controllers/qr_customization_controller.dart';

/// A 2-column grid of curated QR template cards.
///
/// Each card shows a mini QR preview (64×64), the template name, and a profile
/// badge (printSafe=blue, digitalOnly=green, tattooSafe=purple). Tapping a
/// card calls [onTemplateSelected] with the chosen [QrFullTemplate].
///
/// The selected card is highlighted with a neon green (#00FF88) border.
///
/// Maestro key: `qr_template_gallery` (set via [Semantics.identifier]).
class QrTemplateGalleryWidget extends StatelessWidget {
  /// The id of the currently selected template, or null if none is selected.
  final String? selectedTemplateId;

  /// Called when the user taps a template card.
  final ValueChanged<QrFullTemplate> onTemplateSelected;

  const QrTemplateGalleryWidget({
    super.key,
    this.selectedTemplateId,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_template_gallery',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: kQrTemplates.length,
        itemBuilder: (context, index) {
          final template = kQrTemplates[index];
          final isSelected = template.id == selectedTemplateId;
          return _TemplateCard(
            template: template,
            isSelected: isSelected,
            onTap: () => onTemplateSelected(template),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _TemplateCard extends StatelessWidget {
  static const _neonGreen = Color(0xFF00FF88);
  static const _cardBackground = Color(0xFF2E2E2E);

  final QrFullTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _neonGreen : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mini QR preview
            SizedBox(
              width: 64,
              height: 64,
              child: _MiniQrView(customization: template.customization),
            ),
            const SizedBox(height: 8),
            // Template name
            Text(
              template.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? _neonGreen : Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Profile badge
            _ProfileBadge(profile: QrProfile.values[template.customization.profile]),
          ],
        ),
      ),
    );
  }
}

/// Colour-coded chip showing the QR profile name.
///
/// printSafe = blue, digitalOnly = green, tattooSafe = purple
class _ProfileBadge extends StatelessWidget {
  final QrProfile profile;

  const _ProfileBadge({required this.profile});

  Color get _badgeColor => switch (profile) {
        QrProfile.printSafe => const Color(0xFF1A73E8),
        QrProfile.digitalOnly => const Color(0xFF00FF88),
        QrProfile.tattooSafe => const Color(0xFF6366F1),
      };

  String get _label => switch (profile) {
        QrProfile.printSafe => 'Print',
        QrProfile.digitalOnly => 'Digital',
        QrProfile.tattooSafe => 'Tattoo',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _badgeColor, width: 1),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 9,
          color: _badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A tiny [PrettyQrView] rendered from [QrDecorationBuilder] using sample data.
class _MiniQrView extends StatelessWidget {
  static const String _sampleData = 'https://scanqraft.app';

  final dynamic customization;

  const _MiniQrView({required this.customization});

  @override
  Widget build(BuildContext context) {
    final qrImage = QrDecorationBuilder.buildQrImage(
      _sampleData,
      customization,
    );
    final decoration = QrDecorationBuilder.buildDecoration(customization);

    return PrettyQrView(
      qrImage: qrImage,
      decoration: decoration,
    );
  }
}
