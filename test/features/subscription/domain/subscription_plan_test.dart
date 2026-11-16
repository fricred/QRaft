import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/subscription/domain/entities/subscription_plan.dart';

// Pins the client Pro rule to the server one (enforce_qr_code_limit trigger).
void main() {
  final future = DateTime.now().add(const Duration(days: 10));
  final longAgo = DateTime.now().subtract(const Duration(days: 10));

  SubscriptionPlan pro(SubscriptionStatus status, DateTime? expires) =>
      SubscriptionPlan(tier: SubscriptionTier.pro, status: status, expiresAt: expires);

  test('active pro has access', () {
    expect(pro(SubscriptionStatus.active, future).hasProAccess, isTrue);
    expect(pro(SubscriptionStatus.active, null).hasProAccess, isTrue);
  });

  test('cancelled or billing issue keeps access until it expires', () {
    expect(pro(SubscriptionStatus.cancelled, future).hasProAccess, isTrue);
    expect(pro(SubscriptionStatus.billingIssue, future).hasProAccess, isTrue);
  });

  test('a renewal synced late still has a 3-day grace', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(pro(SubscriptionStatus.active, yesterday).hasProAccess, isTrue);
  });

  test('expired subscriptions lose access', () {
    expect(pro(SubscriptionStatus.active, longAgo).hasProAccess, isFalse);
    expect(pro(SubscriptionStatus.cancelled, longAgo).hasProAccess, isFalse);
    expect(pro(SubscriptionStatus.expired, future).hasProAccess, isFalse);
  });

  test('free plan has no access', () {
    expect(const SubscriptionPlan().hasProAccess, isFalse);
  });
}
