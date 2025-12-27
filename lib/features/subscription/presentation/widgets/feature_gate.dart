import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/feature_access.dart';
import 'feature_locked_overlay.dart';
import 'upgrade_bottom_sheet.dart';

/// Wrapper widget that gates content based on feature access
/// Shows locked overlay if feature is not allowed
class FeatureGate extends StatelessWidget {
  final FeatureAccess access;
  final Widget child;
  final bool showOverlay;
  final VoidCallback? onLockedTap;

  const FeatureGate({
    super.key,
    required this.access,
    required this.child,
    this.showOverlay = true,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (access.isAllowed) {
      return child;
    }

    if (!showOverlay) {
      return GestureDetector(
        onTap: onLockedTap ?? () => UpgradeBottomSheet.show(context),
        child: Opacity(
          opacity: 0.5,
          child: AbsorbPointer(child: child),
        ),
      );
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            onTap: onLockedTap ?? () => UpgradeBottomSheet.show(context),
            child: FeatureLockedOverlay(
              featureName: access.feature.displayName,
              description: access.lockedReason,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gate that uses a provider directly
class ProviderFeatureGate extends ConsumerWidget {
  final Provider<FeatureAccess> accessProvider;
  final Widget child;
  final bool showOverlay;
  final VoidCallback? onLockedTap;

  const ProviderFeatureGate({
    super.key,
    required this.accessProvider,
    required this.child,
    this.showOverlay = true,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider);

    return FeatureGate(
      access: access,
      showOverlay: showOverlay,
      onLockedTap: onLockedTap,
      child: child,
    );
  }
}

/// Simple locked card for feature selection grids
/// Shows the content with a lock badge and triggers upgrade on tap
class LockedFeatureCard extends StatelessWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onTap;

  const LockedFeatureCard({
    super.key,
    required this.child,
    required this.featureName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => UpgradeBottomSheet.show(context),
      child: Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: AbsorbPointer(child: child),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: LockedBadge(),
          ),
        ],
      ),
    );
  }
}

/// Conditional builder based on feature access
class FeatureAccessBuilder extends StatelessWidget {
  final FeatureAccess access;
  final Widget Function(BuildContext context) allowedBuilder;
  final Widget Function(BuildContext context, String? reason) lockedBuilder;

  const FeatureAccessBuilder({
    super.key,
    required this.access,
    required this.allowedBuilder,
    required this.lockedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (access.isAllowed) {
      return allowedBuilder(context);
    }
    return lockedBuilder(context, access.lockedReason);
  }
}
