import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ColorPickerWidget extends StatefulWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final String title;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.title,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  static const List<Color> _predefinedColors = [
    // Basic colors
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFF808080), // Gray
    
    // Brand colors
    Color(0xFF1A73E8), // Primary Blue
    Color(0xFF00FF88), // Accent Green
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    
    // Vibrant colors
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Orange
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
    
    // Dark colors
    Color(0xFF1A1A1A), // Dark Gray
    Color(0xFF2E2E2E), // Medium Gray
    Color(0xFF374151), // Cool Gray
    Color(0xFF1F2937), // Blue Gray
  ];


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Current color display
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: widget.selectedColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '#${_colorToHex(widget.selectedColor)}',
              style: TextStyle(
                color: _getContrastColor(widget.selectedColor),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ).animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.95, 0.95), duration: 400.ms),
        
        const SizedBox(height: 12),
        
        // Predefined colors grid
        Text(
          'Predefined Colors',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: _predefinedColors.length,
          itemBuilder: (context, index) {
            final color = _predefinedColors[index];
            final isSelected = _colorToInt(color) == _colorToInt(widget.selectedColor);
            
            return GestureDetector(
              onTap: () => widget.onColorChanged(color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF00FF88)
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: isSelected ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ) : null,
              ).animate(
                target: isSelected ? 1.0 : 0.0,
              ).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 200.ms,
              ),
            );
          },
        ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate relative luminance using modern color component accessors
    final luminance = (0.299 * backgroundColor.r + 
                     0.587 * backgroundColor.g + 
                     0.114 * backgroundColor.b);
    
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Helper method to convert Color to hex string
  String _colorToHex(Color color) {
    return '${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}'
           '${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}'
           '${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  // Helper method to convert Color to int
  int _colorToInt(Color color) {
    return (color.a * 255).round() << 24 |
           (color.r * 255).round() << 16 |
           (color.g * 255).round() << 8 |
           (color.b * 255).round();
  }
}