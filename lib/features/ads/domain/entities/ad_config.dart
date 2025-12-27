import 'package:qraft/features/subscription/domain/entities/subscription_plan.dart';

/// Configuration for ad display behavior
class AdConfig {
  AdConfig._();

  /// Minimum time between interstitial ads (5 minutes)
  static const Duration interstitialCooldown = Duration(minutes: 5);

  /// Maximum interstitial ads per session
  static const int maxInterstitialsPerSession = 3;

  /// Maximum rewarded ads per hour
  static const int maxRewardedPerHour = 5;

  /// Duration of temporary rewards from watching ads
  static const Duration rewardDuration = Duration(hours: 24);

  /// Duration for temporary history unlock
  static const Duration historyUnlockDuration = Duration(hours: 1);

  /// Whether to show ads based on subscription tier
  static bool shouldShowAds(SubscriptionTier tier) {
    return tier == SubscriptionTier.free;
  }
}

/// Types of rewards that can be earned from watching ads
enum AdRewardType {
  /// Extra QR code slot for 24 hours
  extraQRSlot,

  /// Unlock color customization for 24 hours
  colorUnlock,

  /// View full scan history for 1 hour
  historyUnlock,
}

/// Represents a reward earned from watching an ad
class AdReward {
  final AdRewardType type;
  final DateTime expiresAt;
  final int amount;

  const AdReward({
    required this.type,
    required this.expiresAt,
    this.amount = 1,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isActive => !isExpired;

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
}
