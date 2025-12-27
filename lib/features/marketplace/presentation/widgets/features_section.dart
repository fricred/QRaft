import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Features section displaying product benefits with animated checkmarks.
class FeaturesSection extends StatelessWidget {
  final List<String> features;

  const FeaturesSection({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2E2E2E).withValues(alpha: 0.7),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Text(
                  l10n.features,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Feature items
                ...features.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;

                  return _FeatureItem(
                    feature: feature,
                    delay: Duration(milliseconds: 50 * index),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual feature item with checkmark icon
class _FeatureItem extends StatelessWidget {
  final String feature;
  final Duration delay;

  const _FeatureItem({
    required this.feature,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkmark icon with gradient background
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          ).animate(delay: delay)
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.elasticOut,
            ),

          const SizedBox(width: 12),

          // Feature text
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.4,
              ),
            ).animate(delay: delay + 50.ms)
              .fadeIn(duration: 200.ms)
              .slideX(begin: 0.1, duration: 200.ms, curve: Curves.easeOutQuart),
          ),
        ],
      ),
    );
  }
}
