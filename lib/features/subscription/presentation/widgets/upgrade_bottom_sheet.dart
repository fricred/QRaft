import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// Bottom sheet showing Pro features and upgrade option
/// For Phase 1, shows "Coming Soon" message
class UpgradeBottomSheet extends StatelessWidget {
  const UpgradeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpgradeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Header with rocket icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.2),
                  const Color(0xFFF59E0B).withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 40,
              color: Color(0xFFFFD700),
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),

          const SizedBox(height: 16),

          // Title
          Text(
            l10n.upgradeToProTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 8),

          Text(
            l10n.unlockAllPremiumFeatures,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Features list
          ..._buildFeatures(l10n),

          const SizedBox(height: 24),

          // Coming Soon banner
          _buildComingSoonBanner(l10n)
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.2, duration: 400.ms),

          const SizedBox(height: 16),

          // Maybe Later button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.maybeLater,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 300.ms),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(AppLocalizations l10n) {
    final features = [
      (Icons.all_inclusive, l10n.unlimitedQRCodes, l10n.createAsManyAsYouNeed),
      (Icons.qr_code_2, l10n.allQRTypes, l10n.allQRTypesDesc),
      (Icons.palette, l10n.fullCustomization, l10n.fullCustomizationDesc),
      (Icons.history, l10n.unlimitedHistory, l10n.accessAllScanHistory),
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _FeatureRow(
          icon: feature.$1,
          title: feature.$2,
          subtitle: feature.$3,
        ),
      )
          .animate()
          .fadeIn(delay: (200 + index * 100).ms, duration: 300.ms)
          .slideX(begin: -0.1, duration: 300.ms);
    }).toList();
  }

  Widget _buildComingSoonBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF88).withValues(alpha: 0.1),
            const Color(0xFF00CC6A).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 20,
                color: const Color(0xFF00FF88).withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.comingSoonBanner,
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.proSubscriptionsComingSoon,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}
