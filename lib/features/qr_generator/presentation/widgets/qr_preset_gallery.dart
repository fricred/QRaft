import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../domain/entities/qr_code_entity.dart';
import '../../domain/services/qr_decoration_builder.dart';

/// A widget that displays two horizontal scrollable rows of preset thumbnails:
/// one for module shapes and one for eye styles.
///
/// Each thumbnail renders a 64×64 mini [PrettyQrView] using a sample QR URL
/// with the given preset applied. The active card shows a neon green (#00FF88)
/// border; inactive cards have a transparent border.
///
/// Maestro key: `qr_preset_gallery` (set via [Semantics.identifier]).
class QrPresetGalleryWidget extends StatelessWidget {
  /// The currently selected module shape preset (0–7).
  final int selectedModulePreset;

  /// The currently selected eye style preset (0–7).
  final int selectedEyePreset;

  /// Called with the new preset index when the user taps a module card.
  final ValueChanged<int> onModulePresetSelected;

  /// Called with the new preset index when the user taps an eye card.
  final ValueChanged<int> onEyePresetSelected;

  static const int _presetCount = 8;
  static const String _sampleData = 'https://qraft.co';

  /// Labels shown in the gallery header row for each module preset.
  static const List<String> _moduleLabels = [
    'Classic',
    'Rounded',
    'Soft',
    'Flow',
    'Smooth',
    'Dense',
    'Light',
    'Compact',
  ];

  /// Labels shown in the gallery header row for each eye preset.
  static const List<String> _eyeLabels = [
    'Square',
    'Rounded',
    'Circle',
    'Soft',
    'Smooth',
    'Sharp',
    'Bold',
    'Minimal',
  ];

  const QrPresetGalleryWidget({
    super.key,
    required this.selectedModulePreset,
    required this.selectedEyePreset,
    required this.onModulePresetSelected,
    required this.onEyePresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_preset_gallery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(label: 'Module shape'),
          const SizedBox(height: 8),
          _PresetRow(
            presetCount: _presetCount,
            selectedIndex: selectedModulePreset,
            labels: _moduleLabels,
            buildCustomization: (index) => QRCustomization(
              modulePreset: index,
              eyePreset: 0, // neutral eye for module preview
            ),
            onSelected: onModulePresetSelected,
          ),
          const SizedBox(height: 16),
          _SectionLabel(label: 'Eye style'),
          const SizedBox(height: 8),
          _PresetRow(
            presetCount: _presetCount,
            selectedIndex: selectedEyePreset,
            labels: _eyeLabels,
            buildCustomization: (index) => QRCustomization(
              modulePreset: 0, // neutral module for eye preview
              eyePreset: index,
            ),
            onSelected: onEyePresetSelected,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// Horizontal scrollable row of preset thumbnail cards.
class _PresetRow extends StatelessWidget {
  final int presetCount;
  final int selectedIndex;
  final List<String> labels;
  final QRCustomization Function(int index) buildCustomization;
  final ValueChanged<int> onSelected;

  const _PresetRow({
    required this.presetCount,
    required this.selectedIndex,
    required this.labels,
    required this.buildCustomization,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(presetCount, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PresetCard(
              index: index,
              label: labels[index],
              customization: buildCustomization(index),
              isSelected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
          );
        }),
      ),
    );
  }
}

/// A single 64×64 preset thumbnail card with label below.
class _PresetCard extends StatelessWidget {
  static const _cardSize = 64.0;
  static const _neonGreen = Color(0xFF00FF88);
  static const _inactiveBorder = Colors.transparent;
  static const _cardBackground = Color(0xFF2E2E2E);

  final int index;
  final String label;
  final QRCustomization customization;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.index,
    required this.label,
    required this.customization,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _cardSize,
            height: _cardSize,
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _neonGreen : _inactiveBorder,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: _MiniQrView(customization: customization),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isSelected ? _neonGreen : Colors.white54,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tiny PrettyQrView built from [QrDecorationBuilder] using sample data.
///
/// Renders inline using a [QrImage] built once in [build] — the parent
/// [_PresetCard] is rebuilt only when [customization] changes, which happens
/// only when the user switches presets. No throttling needed for static
/// gallery cards.
class _MiniQrView extends StatelessWidget {
  static const String _sampleData = QrPresetGalleryWidget._sampleData;

  final QRCustomization customization;

  const _MiniQrView({required this.customization});

  @override
  Widget build(BuildContext context) {
    // Build QrImage inline — acceptable for static preview cards.
    final qrImage = QrDecorationBuilder.buildQrImage(_sampleData, customization);
    final decoration = QrDecorationBuilder.buildDecoration(customization);

    return PrettyQrView(
      qrImage: qrImage,
      decoration: decoration,
    );
  }
}
