import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Premium "Coming Soon" overlay with glassmorphism design.
/// Shows blurred content behind with an elegant announcement panel.
class ComingSoonOverlay extends StatelessWidget {
  final IconData icon;
  final List<ComingSoonFeature> features;

  const ComingSoonOverlay({
    super.key,
    this.icon = Icons.storefront_rounded,
    this.features = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Blur effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: const SizedBox.expand(),
        ).animate().fadeIn(duration: 300.ms),

        // Layer 2: Dark radial gradient veil
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                const Color(0xFF1A1A1A).withValues(alpha: 0.75),
                const Color(0xFF1A1A1A).withValues(alpha: 0.85),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Layer 3: Glassmorphism panel
        Center(
          child: _buildGlassPanel(context, l10n),
        ),
      ],
    );
  }

  Widget _buildGlassPanel(BuildContext context, AppLocalizations l10n) {
    final defaultFeatures = features.isNotEmpty
        ? features
        : [
            ComingSoonFeature(
              icon: Icons.qr_code_2_rounded,
              label: l10n.marketplaceFeature1,
            ),
            ComingSoonFeature(
              icon: Icons.diamond_rounded,
              label: l10n.marketplaceFeature2,
            ),
            ComingSoonFeature(
              icon: Icons.local_shipping_rounded,
              label: l10n.marketplaceFeature3,
            ),
          ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.15),
            blurRadius: 60,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container with gradient
          _buildIconContainer()
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                delay: 200.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 24),

          // Title
          Text(
            l10n.marketplaceComingSoon,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.3, duration: 400.ms, delay: 400.ms),

          const SizedBox(height: 12),

          // Description
          Text(
            l10n.marketplaceComingSoonDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              height: 1.4,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

          const SizedBox(height: 28),

          // Feature pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < defaultFeatures.length; i++)
                _buildFeaturePill(defaultFeatures[i])
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (800 + i * 100).ms)
                    .slideX(
                      begin: -0.2,
                      duration: 300.ms,
                      delay: (800 + i * 100).ms,
                      curve: Curves.easeOutQuart,
                    ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 400.ms,
          delay: 100.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildIconContainer() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00FF88), Color(0xFF1A73E8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 40,
      ),
    )
        .animate(
          onComplete: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildFeaturePill(ComingSoonFeature feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            feature.icon,
            color: const Color(0xFF00FF88),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature item for the Coming Soon overlay.
class ComingSoonFeature {
  final IconData icon;
  final String label;

  const ComingSoonFeature({
    required this.icon,
    required this.label,
  });
}
