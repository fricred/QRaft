import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final List<Color>? gradientColors;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final double iconSize;
  final bool iconFirst;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.gradientColors,
    this.textColor = Colors.white,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w600,
    this.margin,
    this.borderRadius,
    this.icon,
    this.iconSize = 20,
    this.iconFirst = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _scaleController.animateTo(0.95,
        duration: const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _scaleController.animateTo(1.0,
        duration: const Duration(milliseconds: 150));
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.animateTo(1.0,
        duration: const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    final defaultGradientColors = widget.gradientColors ?? [
      const Color(0xFF00FF88),
      const Color(0xFF1A73E8),
    ];

    final loadingGradientColors = [
      Colors.grey[600]!.withValues(alpha: 0.8),
      Colors.grey[700]!.withValues(alpha: 0.9),
    ];

    final disabledGradientColors = [
      Colors.grey[800]!.withValues(alpha: 0.4),
      Colors.grey[900]!.withValues(alpha: 0.5),
    ];

    final effectiveGradientColors = widget.isLoading
        ? loadingGradientColors
        : widget.onPressed == null
            ? disabledGradientColors
            : [
                defaultGradientColors[0].withValues(alpha: 0.8),
                defaultGradientColors[1].withValues(alpha: 0.9),
              ];

    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    final boxShadow = widget.isLoading || widget.onPressed == null
        ? <BoxShadow>[]
        : _isPressed
            ? [
                BoxShadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [
                // Glow principal - más sutil
                BoxShadow(
                  color: defaultGradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
                // Glow direccional para dar profundidad
                BoxShadow(
                  color: defaultGradientColors[0].withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: -1,
                  offset: const Offset(0, 6),
                ),
              ];

    // Container is the root widget to preserve testability:
    // tests use find.byType(Container).first and check constraints (width/height).
    // The ScaleTransition wraps the inner content only (does not change outer Container).
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: boxShadow,
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: effectiveGradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    // Sombra interior para efecto glass
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: -3,
                      offset: const Offset(0, -3),
                    ),
                    // Sombra interna inferior
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Highlight superior para efecto glass
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: effectiveBorderRadius.topLeft,
                            topRight: effectiveBorderRadius.topRight,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Contenido del botón
                    Align(
                      alignment: Alignment.center,
                      child: widget.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.textColor!),
                              ),
                            )
                          : _buildButtonContent(widget.onPressed != null),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(bool isEnabled) {
    final effectiveTextColor =
        isEnabled ? widget.textColor : Colors.grey[500];

    if (widget.icon == null) {
      return Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
          color: effectiveTextColor,
        ),
      );
    }

    final iconWidget = Icon(
      widget.icon,
      size: widget.iconSize,
      color: effectiveTextColor,
    );

    final textWidget = Text(
      widget.text,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: effectiveTextColor,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.iconFirst
          ? [
              iconWidget,
              const SizedBox(width: 8),
              textWidget,
            ]
          : [
              textWidget,
              const SizedBox(width: 8),
              iconWidget,
            ],
    );
  }
}

// Variantes predefinidas del botón

class PrimaryGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final double iconSize;
  final bool iconFirst;

  const PrimaryGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.icon,
    this.iconSize = 20,
    this.iconFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: height,
      icon: icon,
      iconSize: iconSize,
      iconFirst: iconFirst,
      gradientColors: const [
        Color(0xFF00FF88),
        Color(0xFF1A73E8),
      ],
    );
  }
}

class SecondaryGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final double iconSize;
  final bool iconFirst;

  const SecondaryGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.icon,
    this.iconSize = 20,
    this.iconFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: height,
      icon: icon,
      iconSize: iconSize,
      iconFirst: iconFirst,
      gradientColors: const [
        Color(0xFF1A73E8),
        Color(0xFF6C5CE7),
      ],
    );
  }
}

class SuccessGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;

  const SuccessGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: height,
      gradientColors: const [
        Color(0xFF00FF88),
        Color(0xFF00CC6A),
      ],
    );
  }
}
