import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/plan_limits.dart';
import '../../../profile/data/providers/profile_stats_providers.dart' hide userQRCodesProvider;
import '../../../qr_library/presentation/providers/qr_library_providers.dart' show userQRCodesProvider;
import '../../../qr_scanner/providers/qr_scanner_provider.dart';
import '../../../qr_scanner/models/scan_result.dart';

/// Provider for current user's subscription plan
final subscriptionPlanProvider = FutureProvider<SubscriptionPlan>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);

  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        return const SubscriptionPlan(); // defaults to free
      }
      return SubscriptionPlan.fromMap(profile);
    },
    loading: () => const SubscriptionPlan(),
    error: (_, __) => const SubscriptionPlan(),
  );
});

/// Provider for plan limits based on current subscription
final planLimitsProvider = Provider<PlanLimits>((ref) {
  final subscriptionAsync = ref.watch(subscriptionPlanProvider);

  return subscriptionAsync.when(
    data: (subscription) => subscription.hasProAccess ? PlanLimits.pro : PlanLimits.free,
    loading: () => PlanLimits.free,
    error: (_, __) => PlanLimits.free,
  );
});

/// Provider to check if user has Pro access
final hasProAccessProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionPlanProvider);
  return subscriptionAsync.when(
    data: (subscription) => subscription.hasProAccess,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider to check if user is on free plan
final isFreeUserProvider = Provider<bool>((ref) {
  return !ref.watch(hasProAccessProvider);
});

/// Provider for current QR code count
final currentQRCountProvider = Provider<int>((ref) {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  return qrCodesAsync.when(
    data: (qrCodes) => qrCodes.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider to get remaining QR codes count
/// Returns -1 for unlimited (Pro users)
final remainingQRCodesProvider = Provider<int>((ref) {
  final limits = ref.watch(planLimitsProvider);
  final currentCount = ref.watch(currentQRCountProvider);

  return limits.getRemainingQRCodes(currentCount);
});

/// Provider to check if user can create more QR codes
final canCreateQRProvider = Provider<bool>((ref) {
  final limits = ref.watch(planLimitsProvider);
  final currentCount = ref.watch(currentQRCountProvider);

  return limits.canCreateQR(currentCount);
});

/// Provider for scan history limit
/// Returns -1 for unlimited (Pro users), 10 for free users
final scanHistoryLimitProvider = Provider<int>((ref) {
  final limits = ref.watch(planLimitsProvider);
  return limits.maxScanHistory;
});

/// Provider for subscription tier display name
final subscriptionTierNameProvider = Provider<String>((ref) {
  final subscriptionAsync = ref.watch(subscriptionPlanProvider);

  return subscriptionAsync.when(
    data: (subscription) {
      if (subscription.isTrialActive) return 'Trial';
      if (subscription.isPro) return 'Pro';
      return 'Free';
    },
    loading: () => 'Free',
    error: (_, __) => 'Free',
  );
});

/// Provider for limited scan history based on subscription
/// Free users see only last 10, Pro users see all
final limitedScanHistoryProvider = Provider<List<ScanResult>>((ref) {
  final fullHistory = ref.watch(scanHistoryProvider);
  final limit = ref.watch(scanHistoryLimitProvider);

  if (limit == -1) {
    // Pro users: unlimited
    return fullHistory;
  }

  // Free users: limit to specified amount
  if (fullHistory.length <= limit) {
    return fullHistory;
  }

  return fullHistory.take(limit).toList();
});

/// Provider to check if there are hidden scan history items (for free users)
final hasHiddenScanHistoryProvider = Provider<bool>((ref) {
  final fullHistory = ref.watch(scanHistoryProvider);
  final limit = ref.watch(scanHistoryLimitProvider);

  if (limit == -1) return false; // Pro users have no hidden items

  return fullHistory.length > limit;
});

/// Provider for count of hidden scan history items
final hiddenScanHistoryCountProvider = Provider<int>((ref) {
  final fullHistory = ref.watch(scanHistoryProvider);
  final limit = ref.watch(scanHistoryLimitProvider);

  if (limit == -1) return 0;

  final hiddenCount = fullHistory.length - limit;
  return hiddenCount > 0 ? hiddenCount : 0;
});
