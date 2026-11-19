import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qraft/features/ads/presentation/providers/ad_providers.dart';
import '../../../consent/presentation/providers/consent_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

/// A widget that displays a banner ad
/// Only shows for free tier users
class BannerAdWidget extends ConsumerStatefulWidget {
  final String adUnitId;
  final AdSize size;
  final EdgeInsets padding;

  const BannerAdWidget({
    super.key,
    required this.adUnitId,
    this.size = AdSize.banner,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    final shouldShow = ref.read(shouldShowAdsProvider);
    if (!shouldShow) return;

    // Do not load before UMP resolves. (D-04)
    final consentReady = ref.read(umpConsentReadyProvider);
    if (!consentReady) return;

    if (_isLoading) return;
    _isLoading = true;

    // Ensure AdMob is initialized
    await ref.read(adMobInitProvider.future);

    // Pass npa flag based on consent. (D-06)
    final personalizedAllowed = ref.read(consentGrantedProvider);
    final service = ref.read(adMobServiceProvider);
    final ad = await service.loadBannerAd(
      adUnitId: widget.adUnitId,
      size: widget.size,
      nonPersonalizedAds: !personalizedAllowed,
      onAdLoaded: (_) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        }
      },
      onAdFailedToLoad: (_, __) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );

    if (mounted && ad != null) {
      setState(() {
        _bannerAd = ad;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium users never see ads (Phase 12 — MKT-10 ad suppression).
    if (ref.watch(isPremiumProvider)) return const SizedBox.shrink();

    final shouldShow = ref.watch(shouldShowAdsProvider);
    final consentReady = ref.watch(umpConsentReadyProvider);

    // Re-trigger load when consent flips ready post-construction. (D-04)
    ref.listen<bool>(umpConsentReadyProvider, (prev, next) {
      if (next == true && prev != true && !_isLoaded && !_isLoading) {
        _loadAd();
      }
    });

    if (!shouldShow || !consentReady || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Container(
        alignment: Alignment.center,
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

/// A centered banner ad with a subtle container background
class StyledBannerAd extends ConsumerWidget {
  final String adUnitId;
  final AdSize size;

  const StyledBannerAd({
    super.key,
    required this.adUnitId,
    this.size = AdSize.banner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowAdsProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BannerAdWidget(
          adUnitId: adUnitId,
          size: size,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}
