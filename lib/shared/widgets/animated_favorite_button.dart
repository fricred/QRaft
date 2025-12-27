import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated favorite button with professional 3-phase animation system:
/// 1. Immediate: Scale pop + haptic on press
/// 2. Processing: Pulsing glow while async operation runs
/// 3. Confirmation: Settle bounce + particle burst (add only)
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final bool isProcessing;
  final VoidCallback onToggle;
  final double size;
  final Color favoriteColor;
  final Color unfavoriteColor;
  final Color glowColor;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.isProcessing,
    required this.onToggle,
    this.size = 18,
    this.favoriteColor = const Color(0xFFEF4444),
    this.unfavoriteColor = const Color(0xFF9E9E9E),
    this.glowColor = const Color(0xFF00FF88),
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _glowAnimation;

  bool _wasProcessing = false;
  bool _wasFavorite = false;
  bool _showParticles = false;

  // Key for triggering press animation
  UniqueKey _animationKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _wasFavorite = widget.isFavorite;

    // Glow pulsing animation (800ms cycle)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Particle burst animation (400ms)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _particleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showParticles = false);
        _particleController.reset();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle processing state changes
    if (widget.isProcessing && !_wasProcessing) {
      // Started processing - begin glow pulse
      _glowController.repeat(reverse: true);
    } else if (!widget.isProcessing && _wasProcessing) {
      // Finished processing - stop glow, trigger completion animation
      _glowController.stop();
      _glowController.value = 0;

      // Trigger settle animation
      setState(() => _animationKey = UniqueKey());

      // Show particles only when adding to favorites (guard against duplicates)
      if (widget.isFavorite && !_wasFavorite && !_particleController.isAnimating) {
        setState(() => _showParticles = true);
        _particleController.forward();
      }
    }

    _wasProcessing = widget.isProcessing;
    _wasFavorite = widget.isFavorite;
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Trigger press animation
    setState(() => _animationKey = UniqueKey());

    // Call the toggle callback
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isFavorite
        ? widget.favoriteColor
        : widget.unfavoriteColor;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size + 16, // Extra space for glow and particles
        height: widget.size + 16,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Particle burst layer (behind icon)
            if (_showParticles)
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size + 24, widget.size + 24),
                    painter: _ParticlePainter(
                      progress: _particleController.value,
                      color1: widget.glowColor,
                      color2: widget.favoriteColor,
                    ),
                  );
                },
              ),

            // Glow layer (behind icon)
            if (widget.isProcessing)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  final glowColor = widget.isFavorite
                      ? widget.glowColor
                      : widget.favoriteColor;
                  return Container(
                    width: widget.size + 8,
                    height: widget.size + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: _glowAnimation.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Icon with scale animation
            Icon(
              widget.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: iconColor,
              size: widget.size,
            )
                .animate(key: _animationKey)
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.3, 1.3),
                  duration: 100.ms,
                  curve: Curves.easeOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.3, 1.3),
                  end: const Offset(1.0, 1.0),
                  duration: 150.ms,
                  curve: Curves.elasticOut,
                ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for particle burst effect
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  static const int particleCount = 6;

  _ParticlePainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = maxRadius * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleSize = 3.0 * (1.0 - progress * 0.5);

      final color = i.isEven ? color1 : color2;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      canvas.drawCircle(particleCenter, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
