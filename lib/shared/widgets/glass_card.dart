import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphism card widget with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? glowColor;
  final double glowOpacity;
  final double backgroundOpacity;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 10,
    this.glowColor,
    this.glowOpacity = 0.1,
    this.backgroundOpacity = 0.7,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? const Color(0xFF00FF88);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: effectiveGlowColor.withValues(alpha: glowOpacity),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withValues(alpha: backgroundOpacity),
                  const Color(0xFF1A1A1A).withValues(alpha: backgroundOpacity + 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// A smaller variant for stat cards with icon and value
class GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  const GlassStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowOpacity: 0.05,
      blurSigma: 8,
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? const Color(0xFF00FF88),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab bar container with glass effect
class GlassTabContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassTabContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding ?? const EdgeInsets.all(4),
      borderRadius: 16,
      blurSigma: 8,
      glowOpacity: 0.05,
      backgroundOpacity: 0.5,
      child: child,
    );
  }
}
