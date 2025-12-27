import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qraft/l10n/app_localizations.dart';
import 'pro_badge.dart';
import 'upgrade_bottom_sheet.dart';

/// Overlay widget shown on locked features
/// Displays blur effect, lock icon, feature name and upgrade button
class FeatureLockedOverlay extends StatelessWidget {
  final String featureName;
  final String? description;
  final VoidCallback? onUpgradeTap;
  final bool showUpgradeButton;
  final double blurSigma;

  const FeatureLockedOverlay({
    super.key,
    required this.featureName,
    this.description,
    this.onUpgradeTap,
    this.showUpgradeButton = true,
    this.blurSigma = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use compact mode for small spaces (< 250px height)
              final isCompact = constraints.maxHeight < 250;

              return Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 12 : 16,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lock icon with golden glow
                        Container(
                          padding: EdgeInsets.all(isCompact ? 10 : 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2E2E2E),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                blurRadius: isCompact ? 12 : 20,
                                spreadRadius: isCompact ? 1 : 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: isCompact ? 20 : 32,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 16),
                        // PRO badge
                        ProBadge(mini: isCompact),
                        SizedBox(height: isCompact ? 6 : 12),
                        // Feature name
                        Text(
                          featureName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 13 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description != null && !isCompact) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              description!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (showUpgradeButton) ...[
                          SizedBox(height: isCompact ? 10 : 20),
                          _UpgradeButton(
                            onTap: onUpgradeTap ??
                                () => UpgradeBottomSheet.show(context),
                            isCompact: isCompact,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCompact;

  const _UpgradeButton({required this.onTap, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: isCompact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: isCompact ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: isCompact ? 14 : 18,
              color: Colors.white,
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              isCompact ? l10n.upgrade : l10n.upgradeToPro,
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact locked indicator for cards/list items
class LockedBadge extends StatelessWidget {
  const LockedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_rounded,
        size: 14,
        color: Color(0xFFFFD700),
      ),
    );
  }
}
