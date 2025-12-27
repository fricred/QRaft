import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qraft/features/ads/constants/ad_unit_ids.dart';
import 'package:qraft/features/ads/data/services/admob_service.dart';
import 'package:qraft/features/ads/domain/entities/ad_config.dart';
import 'package:qraft/features/subscription/presentation/providers/subscription_providers.dart';

/// Provider for AdMob service instance
final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

/// Provider for initializing AdMob
final adMobInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(adMobServiceProvider);
  await service.initialize();
});

/// Provider that indicates whether ads should be shown
/// Returns true only for free tier users
final shouldShowAdsProvider = Provider<bool>((ref) {
  // Use isFreeUserProvider which properly handles the AsyncValue
  return ref.watch(isFreeUserProvider);
});

/// Provider for loading dashboard banner ad
final dashboardBannerAdProvider = FutureProvider<BannerAd?>((ref) async {
  final shouldShow = ref.watch(shouldShowAdsProvider);
  if (!shouldShow) return null;

  // Ensure AdMob is initialized
  await ref.watch(adMobInitProvider.future);

  final service = ref.read(adMobServiceProvider);
  return service.loadBannerAd(
    adUnitId: AdUnitIds.bannerDashboard,
    size: AdSize.banner,
  );
});

/// Provider for loading library banner ad
final libraryBannerAdProvider = FutureProvider<BannerAd?>((ref) async {
  final shouldShow = ref.watch(shouldShowAdsProvider);
  if (!shouldShow) return null;

  await ref.watch(adMobInitProvider.future);

  final service = ref.read(adMobServiceProvider);
  return service.loadBannerAd(
    adUnitId: AdUnitIds.bannerLibrary,
    size: AdSize.banner,
  );
});

/// State notifier for managing ad rewards
class AdRewardNotifier extends StateNotifier<List<AdReward>> {
  AdRewardNotifier() : super([]);

  /// Add a reward from watching an ad
  void addReward(AdRewardType type, {int amount = 1}) {
    final expiresAt = type == AdRewardType.historyUnlock
        ? DateTime.now().add(AdConfig.historyUnlockDuration)
        : DateTime.now().add(AdConfig.rewardDuration);

    state = [
      ...state.where((r) => r.type != type), // Remove existing same type
      AdReward(type: type, expiresAt: expiresAt, amount: amount),
    ];
  }

  /// Remove expired rewards
  void cleanupExpired() {
    state = state.where((r) => r.isActive).toList();
  }

  /// Check if a specific reward is active
  bool hasActiveReward(AdRewardType type) {
    cleanupExpired();
    return state.any((r) => r.type == type && r.isActive);
  }

  /// Get active reward of a specific type
  AdReward? getActiveReward(AdRewardType type) {
    cleanupExpired();
    try {
      return state.firstWhere((r) => r.type == type && r.isActive);
    } catch (_) {
      return null;
    }
  }

  /// Get extra QR slots from rewards
  int getExtraQRSlots() {
    cleanupExpired();
    final reward = getActiveReward(AdRewardType.extraQRSlot);
    return reward?.amount ?? 0;
  }
}

/// Provider for ad rewards state
final adRewardProvider =
    StateNotifierProvider<AdRewardNotifier, List<AdReward>>((ref) {
  return AdRewardNotifier();
});

/// Provider to check if user has extra QR slots from ads
final hasExtraQRSlotProvider = Provider<bool>((ref) {
  final notifier = ref.watch(adRewardProvider.notifier);
  return notifier.hasActiveReward(AdRewardType.extraQRSlot);
});

/// Provider to check if user has color unlock from ads
final hasColorUnlockProvider = Provider<bool>((ref) {
  final notifier = ref.watch(adRewardProvider.notifier);
  return notifier.hasActiveReward(AdRewardType.colorUnlock);
});

/// Provider to check if user has history unlock from ads
final hasHistoryUnlockProvider = Provider<bool>((ref) {
  final notifier = ref.watch(adRewardProvider.notifier);
  return notifier.hasActiveReward(AdRewardType.historyUnlock);
});

/// Provider for extra QR slots count from rewards
final extraQRSlotsProvider = Provider<int>((ref) {
  final notifier = ref.watch(adRewardProvider.notifier);
  return notifier.getExtraQRSlots();
});
