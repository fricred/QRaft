import 'dart:ui';
import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradientColors = gradientColors ?? [
      const Color(0xFF00FF88),
      const Color(0xFF1A73E8),
    ];
    
    final loadingGradientColors = [
      Colors.grey[600]!.withValues(alpha: 0.8),
      Colors.grey[700]!.withValues(alpha: 0.9),
    ];

    final effectiveGradientColors = isLoading ? loadingGradientColors : [
      defaultGradientColors[0].withValues(alpha: 0.8),
      defaultGradientColors[1].withValues(alpha: 0.9),
    ];

    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        // Glow exterior que no afecta el tamaño del botón
        boxShadow: isLoading ? [] : [
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
        ],
      ),
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : onPressed,
                    borderRadius: effectiveBorderRadius,
                    child: Container(
                      width: double.infinity,
                      height: height,
                      alignment: Alignment.center,
                      child: isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(textColor!),
                              ),
                            )
                          : Text(
                              text,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: fontWeight,
                                color: textColor,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  const PrimaryGlassButton({
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

  const SecondaryGlassButton({
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