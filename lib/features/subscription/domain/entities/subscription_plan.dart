import 'package:equatable/equatable.dart';

/// Subscription tier levels
enum SubscriptionTier {
  free,
  pro,
  trial
}

/// Subscription status
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  trial
}

/// Represents a user's subscription plan
class SubscriptionPlan extends Equatable {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;

  const SubscriptionPlan({
    this.tier = SubscriptionTier.free,
    this.status = SubscriptionStatus.active,
    this.expiresAt,
    this.trialStartedAt,
    this.trialEndsAt,
  });

  /// Check if user has active Pro subscription
  bool get isPro =>
      tier == SubscriptionTier.pro && status == SubscriptionStatus.active;

  /// Check if user is on free plan
  bool get isFree => tier == SubscriptionTier.free;

  /// Check if trial is active and not expired
  bool get isTrialActive =>
      tier == SubscriptionTier.trial &&
      status == SubscriptionStatus.trial &&
      trialEndsAt != null &&
      DateTime.now().isBefore(trialEndsAt!);

  /// Check if user has Pro-level access (Pro or active trial)
  bool get hasProAccess => isPro || isTrialActive;

  /// Get days remaining in trial
  int? get trialDaysRemaining {
    if (!isTrialActive || trialEndsAt == null) return null;
    return trialEndsAt!.difference(DateTime.now()).inDays;
  }

  /// Create from database map
  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlan(
      tier: _parseTier(map['subscription_plan'] as String? ?? 'free'),
      status: _parseStatus(map['subscription_status'] as String? ?? 'active'),
      expiresAt: map['subscription_expires_at'] != null
          ? DateTime.parse(map['subscription_expires_at'] as String)
          : null,
      trialStartedAt: map['trial_started_at'] != null
          ? DateTime.parse(map['trial_started_at'] as String)
          : null,
      trialEndsAt: map['trial_ends_at'] != null
          ? DateTime.parse(map['trial_ends_at'] as String)
          : null,
    );
  }

  static SubscriptionTier _parseTier(String tier) {
    switch (tier) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'trial':
        return SubscriptionTier.trial;
      default:
        return SubscriptionTier.free;
    }
  }

  static SubscriptionStatus _parseStatus(String status) {
    switch (status) {
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'trial':
        return SubscriptionStatus.trial;
      default:
        return SubscriptionStatus.active;
    }
  }

  @override
  List<Object?> get props => [tier, status, expiresAt, trialStartedAt, trialEndsAt];
}
