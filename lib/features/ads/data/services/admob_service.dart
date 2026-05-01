import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qraft/features/ads/domain/entities/ad_config.dart';

/// Service for managing Google AdMob ads
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  DateTime? _lastInterstitialTime;
  int _interstitialsShownThisSession = 0;

  /// Whether AdMob has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    }
  }

  /// Load a banner ad
  ///
  /// Per D-06: callers pass `nonPersonalizedAds: !consentGranted` derived from
  /// `consentGrantedProvider` so the npa=1 flag is set when the user denied
  /// personalized ads (banner still renders).
  Future<BannerAd?> loadBannerAd({
    required String adUnitId,
    AdSize size = AdSize.banner,
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
    bool nonPersonalizedAds = false,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdMob not initialized. Call initialize() first.');
      return null;
    }

    final completer = Completer<BannerAd?>();

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onAdLoaded?.call(ad);
          completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          onAdFailedToLoad?.call(ad, error);
          ad.dispose();
          completer.complete(null);
        },
      ),
    );

    await bannerAd.load();
    return completer.future;
  }

  /// Show a rewarded ad
  ///
  /// Per D-06: callers pass `nonPersonalizedAds: !consentGranted` derived from
  /// `consentGrantedProvider`.
  Future<bool> showRewardedAd({
    required String adUnitId,
    required void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    void Function()? onAdDismissed,
    void Function(AdError error)? onAdFailedToShow,
    bool nonPersonalizedAds = false,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdMob not initialized. Call initialize() first.');
      return false;
    }

    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              onAdDismissed?.call();
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: ${error.message}');
              onAdFailedToShow?.call(error);
              ad.dispose();
              completer.complete(false);
            },
          );

          ad.show(onUserEarnedReward: (ad, reward) {
            onUserEarnedReward(ad, reward);
            completer.complete(true);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Check if interstitial ad can be shown (respecting cooldown)
  bool canShowInterstitial() {
    if (_interstitialsShownThisSession >= AdConfig.maxInterstitialsPerSession) {
      return false;
    }

    if (_lastInterstitialTime == null) return true;

    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime!);
    return timeSinceLastAd >= AdConfig.interstitialCooldown;
  }

  /// Show an interstitial ad (if cooldown allows)
  ///
  /// Per D-06: callers pass `nonPersonalizedAds: !consentGranted` derived from
  /// `consentGrantedProvider`. Library-ready for Phase 9 marketplace upsells;
  /// no in-app callers yet, default `false` is currently safe.
  Future<bool> showInterstitialAd({
    required String adUnitId,
    void Function()? onAdDismissed,
    void Function(AdError error)? onAdFailedToShow,
    bool nonPersonalizedAds = false,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdMob not initialized. Call initialize() first.');
      return false;
    }

    if (!canShowInterstitial()) {
      debugPrint('Interstitial ad on cooldown or max reached');
      return false;
    }

    final completer = Completer<bool>();

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _lastInterstitialTime = DateTime.now();
              _interstitialsShownThisSession++;
              onAdDismissed?.call();
              ad.dispose();
              completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              onAdFailedToShow?.call(error);
              ad.dispose();
              completer.complete(false);
            },
          );

          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Load a native ad
  ///
  /// Per D-06: callers pass `nonPersonalizedAds: !consentGranted` derived from
  /// `consentGrantedProvider`. Library-ready for future phases; no in-app
  /// callers yet, default `false` is currently safe.
  Future<NativeAd?> loadNativeAd({
    required String adUnitId,
    required String factoryId,
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
    bool nonPersonalizedAds = false,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdMob not initialized. Call initialize() first.');
      return null;
    }

    final completer = Completer<NativeAd?>();

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: AdRequest(nonPersonalizedAds: nonPersonalizedAds),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          onAdLoaded?.call(ad);
          completer.complete(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: ${error.message}');
          onAdFailedToLoad?.call(ad, error);
          ad.dispose();
          completer.complete(null);
        },
      ),
    );

    await nativeAd.load();
    return completer.future;
  }

  /// Reset session counters (call when app resumes from background)
  void resetSessionCounters() {
    _interstitialsShownThisSession = 0;
    _lastInterstitialTime = null;
  }
}
