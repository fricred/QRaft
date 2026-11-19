import 'package:flutter/foundation.dart';

/// AdMob Ad Unit IDs
///
/// Contains test IDs for development and production IDs for release.
/// IMPORTANT: Replace production IDs with your actual AdMob ad unit IDs before release.
class AdUnitIds {
  AdUnitIds._();

  // ===========================================
  // Test Ad Unit IDs (Google's official test IDs)
  // Use these during development to avoid invalid traffic
  // ===========================================

  /// Test Banner Ad Unit ID
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// Test Interstitial Ad Unit ID
  static const String testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  /// Test Rewarded Ad Unit ID
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  /// Test Native Ad Unit ID
  static const String testNative = 'ca-app-pub-3940256099942544/2247696110';

  // ===========================================
  // Production Ad Unit IDs
  // ===========================================

  /// Production Banner Ad for Dashboard
  static const String prodBannerDashboard = 'ca-app-pub-9213497138890427/5750052792';

  /// Production Banner Ad for Library
  static const String prodBannerLibrary = 'ca-app-pub-9213497138890427/5916749349';

  /// Production Rewarded Ad for QR Save bonus
  static const String prodRewardedQRSave = 'ca-app-pub-9213497138890427/4744092884';

  /// Production Rewarded Ad for Scan bonus
  static const String prodRewardedScan = 'ca-app-pub-9213497138890427/8179950602';

  // ===========================================
  // Dynamic Ad Unit ID getters
  // Automatically selects test or production IDs
  // ===========================================

  /// Returns true if running in debug/test mode
  static bool get isTestMode => kDebugMode;

  /// Banner Ad Unit ID (Dashboard)
  static String get bannerDashboard =>
      isTestMode ? testBanner : prodBannerDashboard;

  /// Banner Ad Unit ID (Library)
  static String get bannerLibrary =>
      isTestMode ? testBanner : prodBannerLibrary;

  /// Rewarded Ad Unit ID (QR Save)
  static String get rewardedQRSave =>
      isTestMode ? testRewarded : prodRewardedQRSave;

  /// Rewarded Ad Unit ID (Scan)
  static String get rewardedScan =>
      isTestMode ? testRewarded : prodRewardedScan;

  /// Native Ad Unit ID (Scan History) - uses test ID until production unit is created
  static String get nativeHistory => testNative;

  /// Interstitial Ad Unit ID - uses test ID until production unit is created
  static String get interstitial => testInterstitial;
}
