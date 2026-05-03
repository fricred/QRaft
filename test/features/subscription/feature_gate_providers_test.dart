import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/subscription/domain/entities/feature_access.dart';
import 'package:qraft/features/subscription/domain/entities/subscription_plan.dart';
import 'package:qraft/features/subscription/presentation/providers/feature_gate_providers.dart';
import 'package:qraft/features/subscription/presentation/providers/subscription_providers.dart';

/// Helper: create a ProviderContainer that overrides [subscriptionPlanProvider]
/// to return [plan] synchronously. This bypasses Supabase / profile lookups.
ProviderContainer _containerWith(SubscriptionPlan plan) {
  return ProviderContainer(
    overrides: [
      subscriptionPlanProvider.overrideWith(
        (ref) async => plan,
      ),
    ],
  );
}

void main() {
  group('isPremiumProvider', () {
    test('returns false for free tier', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      // Allow async providers to settle.
      await container.read(subscriptionPlanProvider.future);
      final isPremium = container.read(isPremiumProvider);

      expect(isPremium, isFalse);
    });

    test('returns true for active pro tier', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final isPremium = container.read(isPremiumProvider);

      expect(isPremium, isTrue);
    });

    test('returns true for active trial', () async {
      final trialEndsAt = DateTime.now().add(const Duration(days: 7));
      final container = _containerWith(SubscriptionPlan(
        tier: SubscriptionTier.trial,
        status: SubscriptionStatus.trial,
        trialEndsAt: trialEndsAt,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final isPremium = container.read(isPremiumProvider);

      expect(isPremium, isTrue);
    });
  });

  group('qrLimitProvider', () {
    test('returns 5 for free users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final limit = container.read(qrLimitProvider);

      expect(limit, equals(5));
    });

    test('returns null (unlimited) for premium users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final limit = container.read(qrLimitProvider);

      expect(limit, isNull);
    });
  });

  group('aiStyleGateProvider', () {
    test('is locked for free users with correct message', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final access = container.read(aiStyleGateProvider);

      expect(access.isAllowed, isFalse);
      expect(access.feature, FeatureType.aiStylePremium);
      expect(access.lockedReason, contains('Premium'));
    });

    test('is allowed for pro users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final access = container.read(aiStyleGateProvider);

      expect(access.isAllowed, isTrue);
      expect(access.feature, FeatureType.aiStylePremium);
    });
  });

  group('bulkImportGateProvider', () {
    test('is locked for free users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final access = container.read(bulkImportGateProvider);

      expect(access.isAllowed, isFalse);
      expect(access.feature, FeatureType.bulkImport);
    });

    test('is allowed for pro users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final access = container.read(bulkImportGateProvider);

      expect(access.isAllowed, isTrue);
      expect(access.feature, FeatureType.bulkImport);
    });
  });

  group('unlimitedQrsGateProvider', () {
    test('is locked for free users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final access = container.read(unlimitedQrsGateProvider);

      expect(access.isAllowed, isFalse);
      expect(access.feature, FeatureType.unlimitedQrs);
    });

    test('is allowed for pro users', () async {
      final container = _containerWith(const SubscriptionPlan(
        tier: SubscriptionTier.pro,
        status: SubscriptionStatus.active,
      ));
      addTearDown(container.dispose);

      await container.read(subscriptionPlanProvider.future);
      final access = container.read(unlimitedQrsGateProvider);

      expect(access.isAllowed, isTrue);
      expect(access.feature, FeatureType.unlimitedQrs);
    });
  });
}
