---
phase: 01-foundation-hardening
plan: 08
status: passed-with-residuals
completed: 2026-05-01
verified_by: orchestrator-inline (plan 01-08 executor ran out of tool budget; D-11 suite executed inline by orchestrator)
---

# Phase 1: Foundation Hardening — Verification

## Verdict: PASSED-WITH-RESIDUALS

All 5 ROADMAP success criteria verified. All D-11 closure gates pass. Two documented residuals are non-blocking and deferred to Phase 1.X gap closure.

---

## D-11 Closure Suite Results

| Gate | Command | Result | Evidence |
|------|---------|--------|---------|
| 1 | `flutter pub upgrade --dry-run` | ✅ PASS | No version solving failures. 98 deps would change (upgrades available); 40 have newer versions "incompatible with constraints" — these are intentional pins, not conflicts. |
| 2 | `flutter analyze --no-fatal-warnings` | ✅ PASS | "No issues found! (ran in 5.1s)" — baseline 0 from plan 01-01 preserved across all 7 plans |
| 3 | `flutter test test/features/auth/` | ✅ PASS | 26/26 pass (8 controller + 6 dialog rewrite from plan 01-07; 12 pre-existing supabase_auth_provider tests untouched) |
| 4 | `flutter build apk --debug` | ✅ PASS | Built in 13.7s — `build/app/outputs/flutter-apk/app-debug.apk` |
| 5 | `flutter build ios --debug --no-codesign` | ✅ PASS | Built in 7.5s — `build/ios/iphoneos/Runner.app` |
| 6 | Maestro scanner-tab-launch (iOS sim) | ✅ PASS | iPhone 17 Pro, iOS 26.2 — login → scanner tab → dismiss-permissions → qr_scanner_screen_root visible. SCAN-01 proxy met per D-12. |

---

## ROADMAP Success Criteria

### Criterion #1: `flutter run` on iOS launches mobile_scanner 7.2.0 without errors
**Status: ✅ VERIFIED**

Evidence:
- `pubspec.lock` shows `mobile_scanner: 7.2.0` (commit `3ca9881`)
- `flutter pub get` resolved mobile_scanner 7.2.0 alongside qr_flutter 4.1.0 via shared `qr 3.0.2` — zero version conflicts
- Maestro `scanner-tab-launch.yaml` passed on iPhone 17 Pro (iOS 26.2): app launched → navigated to scanner tab → `qr_scanner_screen_root` visible (mobile_scanner camera surface rendered, no crash)
- Per D-12: physical device validation deferred to Phase 3; iOS simulator is the plan-approved proxy for Phase 1

### Criterion #2: Flutter SDK ≥3.29 and firebase_core upgrade path tested via dry-run
**Status: ✅ VERIFIED**

Evidence:
- `pubspec.yaml` env block: `sdk: ^3.7.0` + `flutter: '>=3.29.0'` (pub-canonical form; plan 01-01 deviation auto-fixed — Dart 3.29 doesn't exist, Flutter 3.29 ships with Dart 3.7)
- `flutter pub upgrade --dry-run` exits 0, no "version solving failed"
- `firebase_core 4.7.0` present in `pubspec.lock`; firebase_messaging 16.2.0 + firebase_crashlytics 5.2.0 + firebase_analytics 12.3.0 all co-resolved with firebase_core 4.7.0 constraint

### Criterion #3: ForgotPasswordDialog test suite fully green
**Status: ✅ VERIFIED**

Evidence:
- `flutter test test/features/auth/` → 26/26 pass (2026-05-01, current run)
- Controller tests: 8 tests covering empty state, loading transition, success, AuthException mapping, generic exception mapping, re-entrancy guard, reset(), copyWith value equality
- Dialog widget tests: 6 tests covering form render, text input, validation, loading spinner, success state, cancel button
- The "5/13 issue" from prior documentation was stale (empirically 6 tests pre-refactor; reconciled in plan 01-06)

### Criterion #4: AdMob UMP consent integrated, form shows on first launch before any ad request
**Status: ✅ VERIFIED**

Evidence (code references):
- `lib/features/consent/data/services/ump_service.dart` — UmpService singleton wrapping `ConsentInformation.instance.requestConsentInfoUpdate` + `ConsentForm.loadAndShowConsentFormIfRequired` from `google_mobile_ads ^5.1.0` (no separate UMP package per modern path)
- `lib/main.dart` — `MobileAds.instance.initialize()` removed from `initializeApp()`; gated on `ref.listen<bool>(umpConsentReadyProvider)` (D-04)
- `lib/features/consent/presentation/widgets/ump_gate.dart` — wraps `AuthWrapper`; descendants don't mount until UMP resolves
- `lib/features/ads/data/services/admob_service.dart` — 4 methods thread `nonPersonalizedAds` flag through `AdRequest(nonPersonalizedAds: nonPersonalizedAds)` (D-06)
- UMP auto-detects GDPR/EU; non-GDPR regions skip form automatically (D-05)

### Criterion #5: Milestone packages installed cleanly
**Status: ✅ VERIFIED**

Evidence:
| Package | Resolved version |
|---------|-----------------|
| firebase_messaging | 16.2.0 |
| firebase_crashlytics | 5.2.0 |
| firebase_analytics | 12.3.0 |
| pretty_qr_code | 3.6.0 |
| screenshot | 3.0.0 |
| image | 4.5.4 |
| csv | 8.0.0 |
| flutter_form_builder | 10.3.0+2 |
| form_builder_validators | 11.3.0 |
| flutter_local_notifications | 17.2.4 |

All 10 packages resolve via `flutter pub get` with zero conflicts (commit `dc4cc5b`). Both debug builds pass. No package wired into app code (D-01 boundary). No standalone UMP package — modern path ships inside `google_mobile_ads ^5.1.0`.

---

## Residuals (Non-Blocking)

### R-01: auth/logout flow — signOut() hangs on Android emulator
**Severity:** Low (non-blocking for Phase 2-4)
**Root cause:** `await authProvider.signOut()` does not complete on Medium_Phone AVD with test user `fricred@gmail.com`. Loading dialog "Cerrando sesión..." stays visible past 30s. Suspected cause: `AuthWrapper`'s `Future.microtask(() => stopSubscriptionRealtime(ref))` fires during Supabase auth state transition and creates a listener race condition.
**Fix applied:** `Navigator.popUntil(isFirst)` is already in place for when signOut does complete (commit `b52d28f`). The hang itself is in the Supabase client call + listener teardown.
**Action:** Investigate in Phase 1.X gap-closure or Phase 12 (Crashlytics/Analytics observability). Does NOT block Phases 2-4 which don't depend on sign-out E2E behavior.

### R-02: iOS Maestro suite — partial re-run post-Semantics fixes
**Severity:** Low (informational)
**Status:** scanner-tab-launch PASS on iPhone 17 Pro validates SCAN-01 and mobile_scanner 7.2.0 launch. Full 9-flow iOS re-run after Semantics + scrollUntilVisible + pressKey:Enter fixes was not completed before Phase 1 close. Android suite (8/9 pass) covers the same flows on a different platform.
**Action:** Full iOS re-run recommended as first step of Phase 2 warmup. Does NOT block Phase 2 start.

---

## Phase 1 Commit Log (all plans)

| Plan | Key commits | What shipped |
|------|------------|--------------|
| 01-01 | 55b4710, 3ca9881 | Flutter SDK ≥3.29, mobile_scanner 7.2.0 |
| 01-02 | 9b1cc5d, 8849773 | .maestro/ root, CONVENTIONS.md, helper scaffolds |
| 01-03 | 5da00cc–33fd58e | Firebase minimum wiring (6 commits) |
| 01-04 | 1990bb6 | 10 milestone packages |
| 01-05 | cd834ff, b7ad68a, 8518f79 | UMP consent + AdMob gating |
| 01-06 | 47339ee, fda41b7, 217db0c | ForgotPasswordController refactor + 20 Maestro Keys |
| 01-07 | bd39494–8de2e80 | 14 tests + 9 Maestro flows + 2 product bug fixes (8 commits) |

**Total: 25 commits on `feature/adds`**

---

## Recommendation

**Phase 1 is closed. Proceed to Phase 2 (QR Generation Core).**

Phases 2, 3, and 4 are parallel-eligible per ROADMAP. Phase 3 requires `/gsd-research-phase 3` first (scanner-matrix CI setup). Phases 2 and 4 can be planned and executed immediately.

R-01 (signOut hang) should be tracked as a Phase 1.X gap candidate to be addressed before Phase 9 (checkout/auth-critical paths). R-02 (iOS full suite) can be done opportunistically.
