import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/features/ads/constants/ad_unit_ids.dart';
import 'package:qraft/features/ads/domain/entities/ad_config.dart';
import 'package:qraft/features/ads/presentation/providers/ad_providers.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// A button that shows a rewarded ad and grants a reward
class RewardedAdButton extends ConsumerStatefulWidget {
  final String adUnitId;
  final AdRewardType rewardType;
  final String label;
  final String? description;
  final VoidCallback? onRewardEarned;
  final bool showIcon;
  final bool compact;

  const RewardedAdButton({
    super.key,
    required this.adUnitId,
    required this.rewardType,
    required this.label,
    this.description,
    this.onRewardEarned,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  ConsumerState<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends ConsumerState<RewardedAdButton> {
  bool _isLoading = false;

  Future<void> _showRewardedAd() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    // Ensure AdMob is initialized
    await ref.read(adMobInitProvider.future);

    final service = ref.read(adMobServiceProvider);
    final success = await service.showRewardedAd(
      adUnitId: widget.adUnitId,
      onUserEarnedReward: (_, reward) {
        // Grant the reward
        ref.read(adRewardProvider.notifier).addReward(widget.rewardType);
        widget.onRewardEarned?.call();

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.adRewardGranted),
              backgroundColor: const Color(0xFF00FF88),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      onAdFailedToShow: (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.adLoadingError),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    if (!success && mounted) {
      setState(() => _isLoading = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adLoadingError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = ref.watch(shouldShowAdsProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      return _buildCompactButton();
    }

    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _showRewardedAd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else if (widget.showIcon)
              const Icon(
                Icons.play_circle_outline,
                size: 16,
                color: Colors.white,
              ),
            if (widget.showIcon) const SizedBox(width: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _showRewardedAd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else if (widget.showIcon)
              const Icon(
                Icons.play_circle_outline,
                size: 20,
                color: Colors.white,
              ),
            if (widget.showIcon) const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.description != null)
                  Text(
                    widget.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-configured rewarded ad button for getting extra QR slot
class ExtraQRSlotAdButton extends ConsumerWidget {
  final VoidCallback? onRewardEarned;
  final bool compact;

  const ExtraQRSlotAdButton({
    super.key,
    this.onRewardEarned,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return RewardedAdButton(
      adUnitId: AdUnitIds.rewardedQRSave,
      rewardType: AdRewardType.extraQRSlot,
      label: l10n.watchAdForBonus,
      description: compact ? null : l10n.getExtraQRSlot,
      onRewardEarned: onRewardEarned,
      compact: compact,
    );
  }
}

/// Pre-configured rewarded ad button for unlocking colors
class ColorUnlockAdButton extends ConsumerWidget {
  final VoidCallback? onRewardEarned;
  final bool compact;

  const ColorUnlockAdButton({
    super.key,
    this.onRewardEarned,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return RewardedAdButton(
      adUnitId: AdUnitIds.rewardedQRSave,
      rewardType: AdRewardType.colorUnlock,
      label: l10n.unlockWithAd,
      description: compact ? null : l10n.watchAdToUnlock,
      onRewardEarned: onRewardEarned,
      compact: compact,
    );
  }
}

/// Pre-configured rewarded ad button for unlocking history
class HistoryUnlockAdButton extends ConsumerWidget {
  final VoidCallback? onRewardEarned;
  final bool compact;

  const HistoryUnlockAdButton({
    super.key,
    this.onRewardEarned,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return RewardedAdButton(
      adUnitId: AdUnitIds.rewardedScan,
      rewardType: AdRewardType.historyUnlock,
      label: l10n.unlockWithAd,
      description: compact ? null : l10n.watchAdToUnlock,
      onRewardEarned: onRewardEarned,
      compact: compact,
    );
  }
}
