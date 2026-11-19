import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/supabase_auth_provider.dart' show authStateProvider;
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/plan_limits.dart';
import '../../../profile/data/providers/profile_stats_providers.dart' hide userQRCodesProvider;
import '../../../qr_library/presentation/providers/qr_library_providers.dart' show userQRCodesProvider;
import '../../../qr_scanner/providers/qr_scanner_provider.dart';
import '../../../qr_scanner/models/scan_result.dart';

/// Provider for current user's subscription plan
/// Last good profile seen by [subscriptionPlanProvider] (only reused for the same user).
Map<String, dynamic>? _lastProfile;

/// True when a profile for [userId] has been loaded before in this session, so a failed
/// refresh can safely fall back to that last known plan.
bool hasKnownPlanFor(String? userId) =>
    userId != null && _lastProfile != null && _lastProfile!['id']?.toString() == userId;

final subscriptionPlanProvider = FutureProvider<SubscriptionPlan>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);

  // Use the last known profile while it reloads or after a failed refresh, so a Pro user
  // is never downgraded to free in between. Only with no profile at all -> free.
  final userId = ref.watch(authStateProvider)?.id;
  var profile = profileAsync.value;
  // Never reuse another account's profile (values survive a user switch while reloading).
  if (profile != null && profile['id']?.toString() != userId) profile = null;
  // userProfileProvider turns fetch errors into null: keep this user's last good profile
  // so a failed refresh never downgrades a paying user to free.
  if (profile == null && _lastProfile != null && _lastProfile!['id']?.toString() == userId) {
    profile = _lastProfile;
  }
  if (profile == null) return const SubscriptionPlan(); // defaults to free
  _lastProfile = profile;
  return SubscriptionPlan.fromMap(profile);
});

/// Provider for plan limits based on current subscription
final planLimitsProvider = Provider<PlanLimits>((ref) {
  if (kDebugMode && ref.watch(debugPremiumOverrideProvider)) return PlanLimits.pro;
  final subscriptionAsync = ref.watch(subscriptionPlanProvider);
  // Keep the last known plan while it reloads (e.g. after a purchase/sync), so a Pro
  // user is never treated as free mid-refresh. No value yet / error -> free.
  final plan = subscriptionAsync.value;
  if (plan != null) return plan.hasProAccess ? PlanLimits.pro : PlanLimits.free;
  return PlanLimits.free;
});

/// Provider to check if user has Pro access
final hasProAccessProvider = Provider<bool>((ref) {
  if (kDebugMode && ref.watch(debugPremiumOverrideProvider)) return true;
  final subscriptionAsync = ref.watch(subscriptionPlanProvider);
  // Last known plan while reloading (no flicker to free for a Pro user).
  return subscriptionAsync.value?.hasProAccess ?? false;
});

/// Provider to check if user is on free plan
final isFreeUserProvider = Provider<bool>((ref) {
  return !ref.watch(hasProAccessProvider);
});

/// Provider for current QR code count
final currentQRCountProvider = Provider<int>((ref) {
  final qrCodesAsync = ref.watch(userQRCodesProvider);
  // Last known count while reloading.
  // Paid dynamic QRs never count toward the plan limit (same rule as the server).
  return qrCodesAsync.value?.where((q) => !q.isDynamic).length ?? 0;
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
  // Only during the very first load (no value yet) do we not block, so a Pro user is not
  // refused before their plan arrives. Refreshes keep the last known values; a failed QR
  // list or missing profile fails closed (free limits, count treated as unknown = full).
  final profile = ref.watch(userProfileProvider);
  final qrs = ref.watch(userQRCodesProvider);
  if ((profile.isLoading && !profile.hasValue) || (qrs.isLoading && !qrs.hasValue)) {
    return true;
  }
  final limits = ref.watch(planLimitsProvider);
  // Paid dynamic QRs never count toward the free limit (same rule as the server).
  final count = qrs.value?.where((q) => !q.isDynamic).length;
  if (count == null) return limits.maxQRCodes < 0; // list failed: only unlimited plans pass
  return limits.canCreateQR(count);
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

/// Debug-only override: set to true after a simulated purchase in debug mode
/// so premium features unlock without real App Store / RevenueCat integration.
final debugPremiumOverrideProvider = StateProvider<bool>((ref) => false);

/// Provider that returns true when the user has an active Pro subscription.
/// In debug mode also respects debugPremiumOverrideProvider for simulator testing.
final isPremiumProvider = Provider<bool>((ref) {
  // In debug mode, a simulated purchase sets this override to true.
  if (kDebugMode && ref.watch(debugPremiumOverrideProvider)) return true;

  final subscriptionAsync = ref.watch(subscriptionPlanProvider);
  // Last known plan while reloading (no flicker to free for a Pro user).
  return subscriptionAsync.value?.hasProAccess ?? false;
});

/// Provider for the effective QR creation limit.
/// Returns null (unlimited) for premium users, 5 for free users.
final qrLimitProvider = Provider<int?>((ref) {
  // Single source of truth: the same plan limits canCreateQRProvider enforces.
  final max = ref.watch(planLimitsProvider).maxQRCodes;
  return max < 0 ? null : max;
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
