import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qraft/features/ads/presentation/providers/ad_providers.dart';
import 'package:qraft/l10n/app_localizations.dart';

/// A widget that displays a native ad styled to match the app's design
/// Note: Native ads require platform-specific setup. This widget provides
/// a fallback card design that integrates naturally with the UI.
class NativeAdWidget extends ConsumerWidget {
  final String adUnitId;
  final EdgeInsets padding;

  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowAdsProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    // For now, display a styled "sponsored" card that blends with the UI
    // Full native ad implementation requires platform-specific factories
    return Padding(
      padding: padding,
      child: const _SponsoredCard(),
    );
  }
}

/// A styled card that indicates sponsored content
/// This serves as a placeholder until native ads are fully configured
class _SponsoredCard extends StatelessWidget {
  const _SponsoredCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Ad icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3E3E3E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Ad content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.sponsoredAd,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.supportWithAds,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A native ad widget specifically designed for list views
/// Shows between items in a list without disrupting the flow
class NativeListAdWidget extends ConsumerWidget {
  final String adUnitId;

  const NativeListAdWidget({
    super.key,
    required this.adUnitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowAdsProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: const _SponsoredCard(),
    );
  }
}

/// A compact inline ad indicator for tight spaces
class InlineAdIndicator extends ConsumerWidget {
  const InlineAdIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowAdsProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.sponsoredAd,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
