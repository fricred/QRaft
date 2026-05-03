---
phase: 12-premium-polish-ga
plan: "01"
subsystem: subscription
tags: [revenuecat, paywall, premium, feature-gating, ads]
dependency_graph:
  requires: []
  provides: [PaywallScreen, isPremiumProvider, qrLimitProvider, aiStyleGateProvider, bulkImportGateProvider]
  affects: [banner_ad_widget, feature_gate_providers]
tech_stack:
  added: []
  patterns: [riverpod-provider, tdd, revenuecat-offerings]
key_files:
  created:
    - lib/features/subscription/presentation/pages/paywall_screen.dart
    - test/features/subscription/feature_gate_providers_test.dart
  modified:
    - lib/features/subscription/domain/entities/feature_access.dart
    - lib/features/subscription/presentation/providers/subscription_providers.dart
    - lib/features/subscription/presentation/providers/feature_gate_providers.dart
    - lib/features/ads/presentation/widgets/banner_ad_widget.dart
decisions:
  - isPremiumProvider derives from existing subscriptionPlanProvider.hasProAccess for single source of truth
  - PaywallScreen uses existing revenueCatDataSourceProvider from purchase_providers.dart (already wired)
  - BannerAdWidget import added from subscription/presentation/providers/subscription_providers.dart
metrics:
  duration: "8 minutes"
  completed: "2026-05-03"
  tasks: 2
  files: 6
---

# Phase 12 Plan 01: RevenueCat Paywall + Premium Entitlements Summary

**One-liner:** RevenueCat paywall screen with 3 new FeatureType entitlements (unlimitedQrs, aiStylePremium, bulkImport), isPremiumProvider gate, and ad suppression for premium subscribers.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (TDD) | Extend FeatureType + gate providers + ad suppression | 2cd0a24 | feature_access.dart, subscription_providers.dart, feature_gate_providers.dart, banner_ad_widget.dart, feature_gate_providers_test.dart |
| 2 | PaywallScreen — entitlements, price, purchase flow | 2cd0a24 | paywall_screen.dart |

## Decisions Made

- **isPremiumProvider** wraps `subscriptionPlanProvider.hasProAccess` via `.when()` to ensure false during loading/error states (fail-closed security).
- **PaywallScreen** uses `Purchases.getOfferings()` directly via a local `_currentOfferingProvider` FutureProvider for simplicity; falls back gracefully with shimmer placeholder during load and disabled button on error.
- **BannerAdWidget** check is at the top of `build()` — premium check precedes all ad loading/rendering logic, ensuring no ad network requests for premium users.
- `revenueCatDataSourceProvider` already existed in `purchase_providers.dart` — no new provider needed for paywall's `purchasePackage` call.

## Test Results

11 tests passing in `test/features/subscription/feature_gate_providers_test.dart`:
- isPremiumProvider: free=false, pro=true, trial=true
- qrLimitProvider: free=5, pro=null (unlimited)
- aiStyleGateProvider: free=locked, pro=allowed
- bulkImportGateProvider: free=locked, pro=allowed
- unlimitedQrsGateProvider: free=locked, pro=allowed

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. PaywallScreen loads live RevenueCat offerings; price falls back to "Precio no disponible" when RevenueCat Dashboard is not configured (expected in sandbox mode without products).

## Threat Flags

None beyond those documented in the plan's threat register.

## Self-Check: PASSED

- `lib/features/subscription/presentation/pages/paywall_screen.dart` — FOUND
- `test/features/subscription/feature_gate_providers_test.dart` — FOUND
- Commit 2cd0a24 — FOUND
- 11 tests PASS
- `flutter analyze lib/features/subscription/ lib/features/ads/` — 0 issues
- Debug APK build — succeeds
