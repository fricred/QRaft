# Phase 1: Foundation Hardening - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate brownfield blockers and align baseline so Phases 2–12 build on solid ground. This phase is operational/infrastructure — it does NOT ship user-facing features. Concretely:

1. Bump `mobile_scanner` to 7.2.0 (Vision API on iOS) to unblock SCAN-01
2. Verify Flutter SDK ≥3.29 and `firebase_core` upgrade path (`flutter pub upgrade --dry-run`)
3. Refactor + stabilize ForgotPasswordDialog test suite
4. Integrate AdMob UMP consent (`google_user_messaging_platform`) and gate `MobileAds.instance.initialize()` behind it
5. Install 10 milestone packages cleanly, including reintroducing Firebase wiring (firebase_core + 3 services) — config only, end-to-end activation deferred to per-feature phases

**Not in scope (belongs in other phases):**
- Functional scanner UX → Phase 3 (SCAN-02..04)
- FCM push end-to-end → Phase 10 (MKT-09)
- Crashlytics/Analytics activation → Phase 12 (OPT-03)
- Habeas Data Ley 1581 consent UI → Phase 9 (LGL-03)

</domain>

<decisions>
## Implementation Decisions

### Firebase Reintroduction Scope
- **D-01:** **Minimum wiring only.** Phase 1 installs `firebase_core` + the 3 milestone Firebase packages (`firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`), drops `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) into the repo, and adds `Firebase.initializeApp()` to `main.dart`. The 3 services are NOT configured end-to-end here — that work lives in Phases 10 (FCM) and 12 (Crashlytics+Analytics). Phase 1 only guarantees the build does not break and the SDK is reachable.
- **D-02:** **Reuse existing Firebase project `qraft-e8a1d`** (referenced in CLAUDE.md). Download fresh `google-services.json` and `GoogleService-Info.plist` from Firebase Console for that project. Do NOT create a new project. Add config files to repo via standard FlutterFire conventions (gitignored test variants if needed; production configs committed).
- **D-03:** Important context — Firebase was previously REMOVED from this codebase (auth migrated to Supabase Auth). Pubspec currently has NO Firebase deps and NO config files. The reintroduction is essentially from scratch even though the project ID exists upstream. Header comment in `lib/features/auth/data/providers/supabase_auth_provider.dart:6` confirms migration ("Supabase Auth Provider - Replaces Firebase Auth").

### AdMob UMP Consent Flow
- **D-04:** **Timing — after splash, before any ad request.** Splash animation runs unimpeded. Once splash finishes, before `MobileAds.instance.initialize()` is called (currently unconditional at `lib/main.dart:32`), UMP evaluates `ConsentInformation`. If consent is required, a dedicated screen presents the form. Only after consent flow completes does AdMob initialize and the user proceeds to login/home.
- **D-05:** **Scope — global, all users.** UMP itself auto-detects GDPR/EU/UK regions and applies the appropriate form. For non-GDPR regions UMP shows a simplified consent or skips automatically. This is robust to future regulations (Brazil LGPD, California CCPA, Colombia Ley 1581) without manual region lists.
- **D-06:** **Denial behavior — non-personalized ads.** If user denies, pass `npa=1` to AdMob. Banners still render but without tracking. Free-tier monetization stays intact and is GDPR-compliant. This is the industry-standard pattern.
- **D-07:** Phase 1 UMP integration is the AdMob-specific consent ONLY. The Habeas Data Ley 1581 consent (LGL-03) is its own UI in Phase 9 — do not couple the two.

### ForgotPasswordDialog Stabilization
- **D-08:** **Refactor + tests.** Extract the Riverpod async-state logic from the 327-line dialog widget into a dedicated controller (presentation pure). Rewrite tests against the controller plus simpler widget tests over the dialog. This addresses the fragility flagged in `.planning/codebase/CONCERNS.md` ("Riverpod async state race conditions in ForgotPasswordDialog").
- **D-09:** **Controller pattern: defer to planner.** The user explicitly chose to let the planner evaluate options during research/planning. Planner must compare existing `lib/features/auth/presentation/controllers/auth_controller.dart` (StateNotifier + AsyncValue) against Riverpod 2.x `AsyncNotifier` and propose in PLAN.md. Trade-offs: consistency with current AuthController vs forward-looking modernization vs hybrid migration plan.
- **D-10:** Documentation discrepancy to reconcile during planning: `.planning/codebase/CONCERNS.md` and `CLAUDE.md` say the test file has 13 tests with 5 failing; the actual file `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` has only **6 tests**. Plan must include a step to run the tests, count failures empirically, and update CONCERNS.md / CLAUDE.md with reality before refactoring. Success criterion is "all tests in the refactored suite pass" — exact count to be set after empirical run.

### Verification Depth (Definition of Done)
- **D-11:** **Build + dry-run + tests green.** Phase 1 closes when:
  1. `flutter pub upgrade --dry-run` reports no conflicts
  2. `flutter analyze` is clean
  3. `flutter test` is 100% green, including refactored ForgotPasswordDialog suite
  4. `flutter run` on iOS simulator AND Android emulator launches without crash
- **D-12:** **No physical-device smoke tests required for Phase 1 closure.** Functional verification of mobile_scanner is Phase 3's concern (SCAN-02). FCM token registration is Phase 10's. Crashlytics test crash is Phase 12's. Phase 1 only guarantees the *build* and *baseline* are sound.
- **D-13:** **Scanner fallback if `mobile_scanner` 7.2.0 fails to resolve:** escalate by spawning `/gsd-research-phase 1` and pause Phase 1 execution. Do NOT downgrade to 6.x or earlier — `.planning/codebase/CONCERNS.md` notes versions 4–6 also have breaking changes, and 6.x still uses MLKit on iOS (the original problem 7.x with Vision API solves). 7.2.0 is the specific bet from research SUMMARY.md and a downgrade would re-introduce the bug being fixed.

### Claude's Discretion
- The exact controller pattern for ForgotPasswordDialog refactor (StateNotifier vs AsyncNotifier vs hybrid). User explicitly delegated to planner.
- Concrete `pubspec.yaml` ordering / grouping of the new packages — follow existing conventions in the file.
- Whether to combine package installs into a single `pub add` invocation or stage them — operational choice, planner picks.
- Naming of the new UMP consent screen widget and route. Default: follow existing screen naming patterns in `lib/features/`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level (always relevant)
- `.planning/PROJECT.md` — Project vision, validated brownfield assets, key decisions
- `.planning/REQUIREMENTS.md` §"QR Scanner" — SCAN-01 (the only formal v1 requirement bound to Phase 1)
- `.planning/ROADMAP.md` §"Phase 1: Foundation Hardening" — goal, success criteria, dependencies
- `.planning/STATE.md` §"Decisions Locked" — locked architectural decisions carried in
- `.planning/v2-vision.md` — context for why milestone packages matter (FCM gates Phase 10; Crashlytics+Analytics gate Phase 12 GA)

### Codebase analysis (reusable assets and constraints)
- `.planning/codebase/STACK.md` §"Mobile Scanner 7.0.0" — current pinned version, target 7.2.0
- `.planning/codebase/STACK.md` §"Configuration" — env.json convention via `--dart-define-from-file`
- `.planning/codebase/CONCERNS.md` §"Mobile Scanner Dependency Update" — iOS dependency block, breaking-change risk across v4–v7
- `.planning/codebase/CONCERNS.md` §"ForgotPasswordDialog Test Failures" — fragility flagged (Riverpod async state, race conditions)
- `.planning/codebase/CONCERNS.md` §"Ad Consent & Privacy" — UMP integration gap
- `.planning/codebase/CONCERNS.md` §"Riverpod State Management Interdependencies" — pattern guidance for controller refactor

### Research synthesis
- `.planning/research/SUMMARY.md` — `mobile_scanner` 7.2.0 + Flutter SDK ≥3.29 + `pretty_qr_code` 3.6.0 alongside `qr_flutter` decision
- `.planning/research/STACK.md` — package selection rationale for milestone list
- `.planning/research/PITFALLS.md` — known pitfalls relevant to package upgrades

### Code entry points (read for current state)
- `lib/main.dart:17–35` — current `initializeApp()` flow; UMP gating must wrap `MobileAds.instance.initialize()` here
- `lib/features/ads/data/services/admob_service.dart:24` — secondary AdMob init call site
- `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` — 327-line dialog targeted for refactor
- `lib/features/auth/presentation/controllers/auth_controller.dart` — reference pattern for controller extraction
- `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` — 6 tests (count empirically before deciding pass/fail counts)
- `pubspec.yaml:21` — Flutter SDK constraint (currently `^3.6.2`, target ≥3.29)
- `pubspec.yaml:51` — `mobile_scanner: ^7.0.0` (target ^7.2.0)

### External docs (read at planning time as needed)
- Google UMP SDK docs (Flutter): https://developers.google.com/admob/flutter/privacy
- FlutterFire setup: https://firebase.flutter.dev/docs/overview
- mobile_scanner 7.x changelog: https://pub.dev/packages/mobile_scanner/changelog

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AuthController` (StateNotifier + AsyncValue) at `lib/features/auth/presentation/controllers/auth_controller.dart`** — reference pattern for the ForgotPasswordDialog controller refactor. Tested and working.
- **`SupabaseService.initialize()` and `EnvConfig.debugConfig()` in `lib/main.dart`** — existing initialization order is the insertion point for `Firebase.initializeApp()` and UMP gating.
- **`GlassButton` component library** — already used across auth screens; UMP consent screen UI can reuse for action buttons.
- **`SplashScreen` (`lib/features/splash/splash_screen.dart`)** — completion callback is the natural hook to dispatch UMP gating before AdMob init.
- **i18n infra (`lib/l10n/app_localizations.dart`)** — UMP consent screen copy goes here (es/en) even though UMP itself renders Google's localized form.

### Established Patterns
- **Clean architecture by feature** (`data/`/`domain/`/`presentation/`) — UMP module should follow `lib/features/consent/` or be folded into `lib/features/ads/`.
- **Riverpod providers as DI** — UMP service registers as a provider; consent state exposed via provider for downstream consumers (e.g., `BannerAdWidget` reads consent state to gate render).
- **`--dart-define-from-file=env.json` build invocation** — Firebase config files are bundled at build time, not loaded at runtime; ensure CI/CD picks up new `google-services.json` and `GoogleService-Info.plist`.
- **Existing test conventions** — `test/features/<feature>/...` mirrors `lib/`. New controller tests follow `test/features/auth/presentation/controllers/auth_controller_simple_test.dart` pattern.

### Integration Points
- **`lib/main.dart` `initializeApp()`** — single entry point for app boot. Order will become: env → Supabase → Firebase.initializeApp() → UMP eval (post-splash) → MobileAds.initialize() (post-consent).
- **`lib/features/ads/data/services/admob_service.dart:24`** — second AdMob init call site; must respect global UMP state, not initialize independently.
- **`lib/features/ads/presentation/widgets/banner_ad_widget.dart`** — render gate; reads consent provider to apply `npa=1` flag on denial.
- **`pubspec.yaml`** — three changes: SDK constraint bump, `mobile_scanner` version bump, append 11 new dependencies (10 milestone + `google_user_messaging_platform`).
- **`android/app/google-services.json` (new file)** — Android Firebase config.
- **`ios/Runner/GoogleService-Info.plist` (new file)** — iOS Firebase config; reference from Xcode project.
- **`android/app/build.gradle.kts`** — apply `com.google.gms.google-services` plugin for Firebase.
- **`ios/Podfile`** — Firebase/UMP pod entries via auto-pod-install.

</code_context>

<specifics>
## Specific Ideas

- **mobile_scanner pinned at 7.2.0 specifically** — research SUMMARY.md identified this as the version that adopts iOS Vision API instead of MLKit. User explicitly rejected fallback to 6.x because that would re-introduce the bug.
- **UMP placement after splash, not before** — preserves the Carden Pro branded splash experience. User cares about onboarding feel.
- **Controller pattern delegated to planner** — user wants a research-backed comparison in PLAN.md before committing.
- **Reuse Firebase project `qraft-e8a1d`** — user has access; do not create a new one.
- **No physical device gates for Phase 1** — explicit. CI emulator/simulator validation is the bar.

</specifics>

<deferred>
## Deferred Ideas

- **Functional scanner verification on iOS device** — belongs in Phase 3 (SCAN-02) where the scanner UI is built.
- **FCM end-to-end activation (APNs cert, token registration plumbing)** — Phase 10 (MKT-09).
- **Crashlytics dSYM upload + smoke crash test** — Phase 12 (OPT-03).
- **Analytics first event + dashboard wiring** — Phase 12 (OPT-03).
- **Habeas Data Ley 1581 consent UI (in addition to UMP)** — Phase 9 (LGL-03).
- **Migrating other Riverpod providers from StateNotifier to AsyncNotifier** — out of Phase 1 scope; potential cross-cutting refactor for a future hardening phase if planner picks AsyncNotifier for ForgotPasswordDialog.
- **Splitting the 1500+ line UI screens flagged in CONCERNS.md** (`location_qr_screen.dart`, `qr_library_screen.dart`, etc.) — tech debt, not Phase 1 blocker; revisit during Phases 2/5/8 when those screens are touched.
- **Reconciling pubspec/CLAUDE.md docs that still describe Firebase Auth as active** — documentation cleanup; not blocking, but planner can fold into Phase 1 if cheap.
- **CI pre-commit hook to verify `env.json` is never staged** (CONCERNS.md security recommendation) — defer to a later infra phase or backlog.

</deferred>

---

*Phase: 1-Foundation Hardening*
*Context gathered: 2026-05-01*
