import 'package:flutter/material.dart';

/// A color picker widget for QR code foreground/gradient color selection.
///
/// Shows 8 Carden Pro preset color swatches and a hex input field for
/// custom colors. The active swatch is highlighted with a 2 px white border.
///
/// Security note (T-05-03-01): hex input is validated with
/// `^[0-9A-Fa-f]{6}$` before parsing — invalid input shows a validation
/// error and no [Color] is constructed.
class QrColorPickerWidget extends StatefulWidget {
  /// The color to show as initially selected.
  final Color initialColor;

  /// Called whenever a new color is selected — from a preset or via hex input.
  final ValueChanged<Color> onColorSelected;

  /// A human-readable label shown above the swatches
  /// (e.g. 'Foreground color', 'Gradient start').
  final String label;

  const QrColorPickerWidget({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    required this.label,
  });

  @override
  State<QrColorPickerWidget> createState() => _QrColorPickerWidgetState();

  // ---------------------------------------------------------------------------
  // Preset palette — Carden Pro design system (CLAUDE.md)
  // ---------------------------------------------------------------------------

  /// 8 preset swatches matching the Carden Pro color palette.
  static const List<Color> presets = [
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFF1A73E8), // Primary Blue
    Color(0xFF00FF88), // Neon Green
    Color(0xFF6366F1), // Elegant Purple
    Color(0xFFFF6B6B), // Sunset Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFF2E2E2E), // Charcoal
  ];
}

class _QrColorPickerWidgetState extends State<QrColorPickerWidget> {
  late Color _selectedColor;
  final TextEditingController _hexController = TextEditingController();
  final GlobalKey<FormFieldState<String>> _hexFieldKey =
      GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  void didUpdateWidget(QrColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      setState(() => _selectedColor = widget.initialColor);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _onPresetTap(Color color) {
    setState(() => _selectedColor = color);
    widget.onColorSelected(color);
  }

  void _onHexSubmit(String? value) {
    if (value == null) return;
    final hex = value.replaceFirst('#', '').trim();
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) return;
    final color = Color(int.parse('FF$hex', radix: 16));
    setState(() => _selectedColor = color);
    widget.onColorSelected(color);
  }

  /// Validates the raw hex string typed by the user.
  String? _validateHex(String? value) {
    if (value == null || value.isEmpty) return null; // optional field
    final hex = value.replaceFirst('#', '').trim();
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      return 'Enter a 6-digit hex color (e.g. 1A73E8)';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'qr_color_picker_${widget.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Preset swatch row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: QrColorPickerWidget.presets
                .map((color) => _SwatchCircle(
                      color: color,
                      isSelected: color.toARGB32() == _selectedColor.toARGB32(),
                      onTap: () => _onPresetTap(color),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          // Custom hex input
          TextFormField(
            key: _hexFieldKey,
            controller: _hexController,
            style: const TextStyle(color: Colors.white),
            maxLength: 7, // '#' + 6 hex chars
            decoration: InputDecoration(
              labelText: 'Custom hex (e.g. 1A73E8)',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixText: '#',
              prefixStyle: const TextStyle(color: Colors.white70),
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00FF88)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
              ),
              filled: true,
              fillColor: const Color(0xFF2E2E2E),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateHex,
            onFieldSubmitted: _onHexSubmit,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private swatch widget
// ---------------------------------------------------------------------------

/// A single 32×32 px color swatch circle with an active state border ring.
class _SwatchCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SwatchCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
