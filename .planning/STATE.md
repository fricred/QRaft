# State: QRaft v1.0

**Last updated:** 2026-05-01 (post plan 01-07)

## Project Reference

**Core value**: Cerrar el loop digital→físico con un QR personalizado de calidad — diseñar → personalizar → comprar → recibir grabado, todo en pesos colombianos sin fricción.

**Current focus**: Phase 1 — Foundation Hardening (plans 01-01..01-07 complete; only 01-08 phase verification remains. Plan 01-07 closed with 8/9 Maestro flows passing on Android — auth/logout RESIDUAL due to signOut() hang surfaced as real product bug, deferred to Phase 1.X gap closure)

**Strategic anchors**:
- Brownfield foundation: Auth, GlassButton, deeplinks, i18n, Supabase, AdMob inicial — preservar y construir encima
- Every engraved QR routes through `qraft.link/{slug}` (RDR-01..06) — non-negotiable architecture
- Solo Colombia v1, COP, Wompi, IVA 19%
- DIAN factura electrónica DEFERRED to v2 with explicit risk acceptance
- Manual fulfillment via operator dashboard (no IoT in v1)

## Current Position

**Milestone:** v1.0
**Phase:** 1 of 12 — Foundation Hardening
**Plan:** 7/8 complete — next: 01-08 phase verification (wave 6)
**Status:** Plans 01-01..01-07 complete; Phase 1 in progress (final verification pending)
**Last session:** 2026-05-01 — Plan 01-07 (Maestro flows + controller tests) executed cross-session on `feature/adds`. Tasks 1+3 autonomous (commits `bd39494` 14 Flutter tests, `7eeae6d` 9 flow YAMLs); semantics rollout `627859d`; manual close-out commits `41908d0` (remove legacy SupabaseForgotPasswordDialog from main.dart, freeing 215 lines of dead code), `cb1663c` (Semantics(identifier:) on dashboard_profile_button + profile_sign_out_button + profile_sign_out_confirm_button), `3cf599d` (Maestro YAML iterations: suite recursion config, scrollUntilVisible for off-fold welcome CTA, pressKey:Enter for keyboard-occluded login_submit_button), `b52d28f` (Navigator.popUntil(isFirst) after signOut + 30s timeout on logout assertion), `3c29309` (CONVENTIONS.md Phase 1 status section). Android Medium_Phone suite: **8/9 flows PASS** (splash-happy 8s, ump-accept 7s, ump-deny-npa 9s, login-valid 27s, login-invalid 24s, forgot-password 24s, session-persistence 37s, scanner-tab-launch 37s) — auth/logout RESIDUAL with the loading dialog "Cerrando sesión..." stuck visible past 30s, signOut() hangs at the SupabaseClient call (likely interaction with subscription realtime listener teardown in AuthWrapper). iOS suite ran on iPhone 17 Pro pre-Semantics (4/7 pass, expected); not re-run after Semantics+popUntil fixes — recommended at start of next session. Real product bugs surfaced and fixed by Maestro E2E (legacy dialog dead code, Navigator stack occlusion). Plan 01-07 deviations: 6 auto-fixed (4 Rule 3 blocking, 2 Rule 4 functionally required). flutter analyze: 0 issues. Whole-suite test delta from `+83 ~1 -91` to `+97 ~1 -85` (the 6 broken-by-design dialog tests from plan 01-06 are now sane; +8 controller tests added). Earlier session: Plan 01-05 (UMP consent + AdMob gating) executed sequentially on `feature/adds`, 3 tasks, ~7 minutes. Commits `cd834ff` (consent module: ConsentState + UmpService + 5 providers) + `b7ad68a` (UmpConsentScreen + UmpGate) + `8518f79` (main.dart bootstrap reorder + AdMobService 4 method signatures + BannerAdWidget + RewardedAdButton + ad_providers refactor). New `lib/features/consent/` feature module: `ConsentState` enum with 5 values (unknown/required/notRequired/obtained/denied) + `ConsentStateX` extension exposing `isResolved` + `isPersonalizedAllowed` booleans (37 lines); `UmpService` singleton (132 lines) wrapping `ConsentInformation.instance.requestConsentInfoUpdate` + `ConsentForm.loadAndShowConsentFormIfRequired` from google_mobile_ads ^5.1.0 — NO separate UMP package install per plan 04 D-01 — using Completer-to-Future bridge over the callback-based UMP API; accept-vs-deny disambiguation via `canRequestAds()` because `ConsentStatus.obtained` covers both; fail-open posture so app does not deadlock on UMP errors. 5 Riverpod providers (umpServiceProvider, umpInitProvider, consentStateProvider, umpConsentReadyProvider, consentGrantedProvider). UmpConsentScreen ConsumerStatefulWidget triggers Google's UMP form on first frame via `WidgetsBinding.instance.addPostFrameCallback`; Carden Pro design tokens (#1A1A1A scaffold + #2E2E2E 24-radius card) + PrimaryGlassButton CTA + 2 stable Maestro Keys (`ump_consent_screen_root`, `ump_continue_button`). UmpGate ConsumerWidget with `.when()` loading/error/data branches; explicit `consent_state.dart` import so `state.isResolved` extension getter resolves. main.dart bootstrap reordered per D-04: removed `MobileAds.instance.initialize()` from `initializeApp()` (now only env → Supabase → Firebase); added `ref.listen<bool>(umpConsentReadyProvider, ...)` in `_QRaftAppState.build` that fires `ref.read(adMobInitProvider.future)` exactly once on UMP-resolves transition (FutureProvider memoization + idempotent `AdMobService.initialize()` keep it safe); AuthWrapper wrapped in `UmpGate(child: AuthWrapper())`. AdMobService 4 ad-loading methods (loadBannerAd lines 33-69, showRewardedAd lines 70-118, showInterstitialAd lines 130-181, loadNativeAd lines 184-217) now accept `bool nonPersonalizedAds = false` and pass it into `AdRequest(nonPersonalizedAds: nonPersonalizedAds)` per D-06; 0 `const AdRequest()` remaining, 4 `AdRequest(nonPersonalizedAds:` sites. BannerAdWidget._loadAd() bails if `!umpConsentReadyProvider` (D-04) AND passes `nonPersonalizedAds: !consentGranted` (D-06); `build()` watches `umpConsentReadyProvider` + ref.listen re-triggers `_loadAd` when consent flips ready post-construction (re-entrancy guard `!_isLoaded && !_isLoading`) — handles widgets built before UMP resolves. RewardedAdButton._showRewardedAd() reads consentGrantedProvider and forwards `!personalizedAllowed`. ad_providers.dart `dashboardBannerAdProvider` + `libraryBannerAdProvider` both gate on `umpConsentReadyProvider` AND forward npa flag. Maestro selector deviation documented: `ump_settings_link` Key NOT added because the "manage settings" link is rendered by Google's UMP system overlay (not a Flutter widget); plan 07 will target it via text matcher. flutter analyze: 0 issues; flutter build apk --debug --target-platform android-arm64: Built in 9.5s; flutter build ios --debug --no-codesign: Built in 9.9s. Whole-suite test delta unchanged from plan 06 (`+83 ~1 -91` — 0 new test breakage from this plan). Closes ROADMAP success criterion #4 (UMP integrated, consent form on first launch before any ad request).

**Progress:** [▱▱▱▱▱▱▱▱▱▱▱▱] 0/12 phases complete (0%) — Phase 1: 7/8 plans complete (87.5%)

```
Phase 1:  ▱ Foundation Hardening              ← NEXT
Phase 2:  ▱ QR Generation Core                (parallel-eligible after P1)
Phase 3:  ▱ QR Scanner                        (parallel-eligible after P1)
Phase 4:  ▱ Redirect Service Foundation       (parallel-eligible after P1)
Phase 5:  ▱ QR Customization (Print-Safe)
Phase 6:  ▱ QR Digital-Only Features          (parallel-eligible after P5)
Phase 7:  ▱ Marketplace Catalog + QR Export   (parallel-eligible after P5)
Phase 8:  ▱ Cart & Customization Snapshot
Phase 9:  ▱ Checkout, Wompi & Compliance
Phase 10: ▱ Orders, Realtime & FCM
Phase 11: ▱ Operator Dashboard + Tattoo Line
Phase 12: ▱ Premium, Polish & Observability (GA)
```

## Performance Metrics

**Coverage:** 46/46 v1 requirements mapped (100%)
**Granularity:** standard (12 phases — scope-amplified)
**Mode:** yolo
**Parallelization:** enabled (3 windows: P2-P3-P4 after P1; P6-P7 after P5)

## Accumulated Context

### Decisions Locked (during initialization + execution)

| Decision | Source |
|----------|--------|
| Flutter SDK floor expressed as `sdk: ^3.7.0` + `flutter: '>=3.29.0'` (NOT `sdk: ^3.29.0`) | plan 01-01 SUMMARY (`3ca9881`) — pub treats `environment.sdk` as Dart SDK, Dart 3.29 doesn't exist |
| Analyzer baseline = 0 issues (recorded for plan 01-07 final-gate regression check) | plan 01-01 SUMMARY |
| Maestro selector convention `<feature>_<element>_<role>` documented in `.maestro/CONVENTIONS.md`; 13 verbatim selector ids enumerated for plans 06 + 07 to copy (forgot_password_*, ump_*, login_*, scanner_*, home_dashboard_root) | plan 01-02 SUMMARY |
| `maestro check-syntax` CLI used as syntax validator (equivalent to `mcp__maestro__check_flow_syntax`; both wrap the same Maestro 2.4.0 binary) | plan 01-02 SUMMARY |
| `.maestro/helpers/login.yaml` ships as text-matcher scaffold; plan 07 tightens to id matchers after plan 06 adds Keys to `auth_flow.dart` widgets | plan 01-02 SUMMARY (inline upgrade-path comments embedded in login.yaml) |
| `dismiss-permissions.yaml` localizes "Permitir" (es-CO) alongside English variants because the app ships es/en | plan 01-02 SUMMARY |
| Maestro CI integration deferred (D-16) — documented in CONVENTIONS.md so future planners do not accidentally re-scope | plan 01-02 SUMMARY |
| iOS deployment target bumped 13.0 → 15.0 (firebase_core 4.7.0 podspec requires `s.ios.deployment_target = '15.0'`); applies to `ios/Podfile` AND `ios/Runner.xcodeproj/project.pbxproj` (3 build configs). Downstream Firebase additions inherit this floor; mobile_scanner 7.x is satisfied. | plan 01-03 SUMMARY (`82b09ba`) — Rule 3 deviation |
| `lib/firebase_options.dart` hand-authored matching FlutterFire CLI output shape exactly (skip CLI install per orchestrator instruction). Future `flutterfire configure` runs produce a clean diff. | plan 01-03 SUMMARY (`4d0e9d8`) — Rule 3 deviation |
| Modern Gradle `plugins {}` apply-false style chosen over legacy `buildscript {} { dependencies { classpath(...) } }` in project-level `android/build.gradle.kts` (file had no buildscript block; modern style is the natural minimal-diff extension). google-services version 4.4.2. | plan 01-03 SUMMARY (`82b09ba`) |
| `lib/main.dart` init order locked: env → Supabase → Firebase → AdMob. Plan 01-05 will extract AdMob behind UMP gate; Firebase init stays where it is. | plan 01-03 SUMMARY (`e46e506`) |
| Native Firebase config policy: `google-services.json` + `GoogleService-Info.plist` committed (NOT gitignored — they contain only public client IDs, no secrets). Future Firebase project rotations require re-downloading both. | plan 01-03 SUMMARY (`bff89cb`) |
| Firebase service trio (firebase_messaging 16.2.0 / firebase_crashlytics 5.2.0 / firebase_analytics 12.3.0) pinned to versions that all declare firebase_core ^4.7.0 — verified via pub.dev API 2026-05-01. firebase_core stays at 4.7.0 (no bump from plan 03 pin). | plan 01-04 SUMMARY (`1990bb6`) |
| No standalone UMP package installed. Modern UMP API ships INSIDE google_mobile_ads ^5.1.0 — plan 05 imports `ConsentInformation`/`ConsentForm` from there. The third-party `user_messaging_platform` package on pub.dev is discontinued (last 1.3.0); the `google_user_messaging_platform` package referenced in earlier drafts does NOT exist on pub.dev. Verified via Google AdMob Flutter privacy docs 2026-05-01. | plan 01-04 SUMMARY (`1990bb6`) |
| Android core library desugaring enabled in `android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` in compileOptions + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` in dependencies block. Required by flutter_local_notifications 17.x; future packages requiring Java 8+ stdlib backport on minSdk < 26 inherit this floor. | plan 01-04 SUMMARY (`1990bb6`) — Rule 3 deviation |
| pubspec.yaml dep-grouping pattern extended: 4 new sections added by plan 04 (# Advanced QR Generation, # Forms, # Notifications, plus Firebase trio extension under existing # Firebase). Section comments precede grouped entries. | plan 01-04 SUMMARY (`1990bb6`) |
| ForgotPasswordController pattern: `StateNotifier<ForgotPasswordState>` + immutable state class (D-09 resolution); mirrors `qr_customization_controller.dart` since no AsyncNotifier example exists in the codebase. Constructor accepts `SupabaseClient? client` for testability (do NOT use static SupabaseService.client inside the controller body — that is the testability blocker D-08 calls out). Provider is `StateNotifierProvider.autoDispose` so re-entry into the dialog auto-resets state, sidestepping the race condition in CONCERNS.md. Re-entrancy guard: `if (state.isLoading) return;` at top of submit(). | plan 01-06 SUMMARY (`fda41b7`) |
| ForgotPasswordDialog test count: empirically 6 tests, 0 failing pre-refactor (verified `grep -cE 'testWidgets\\(\|^\\s*test\\(' = 6` and `flutter test ...forgot_password_dialog_test.dart = +6 -0`). Prior 5/13 figure in CLAUDE.md + CONCERNS.md was stale (D-10 reconciliation). Post-refactor: 6/6 fail with "Supabase has not been initialized" runtime exception because tests still override the obsolete `supabaseAuthProvider`; plan 07 task 1 rewrites the suite against `forgotPasswordControllerProvider` with a MockSupabaseClient injected via the controller constructor. | plan 01-06 SUMMARY (`47339ee`, `217db0c`) |
| Maestro Key source-of-truth pattern: when a Key spans multiple files (e.g., `main_scaffold_scanner_tab` is owned semantically by main_scaffold but rendered by main_navigation), the literal Key string lives in the feature scaffold file (so it's greppable from its semantic owner) and is passed as a `Key?` prop to the rendering widget. Implementation: `MainScaffoldKeys` class in `main_scaffold.dart` enumerates all 5 tab Keys; `MainNavigation` accepts `Key? <name>TabKey` params and applies them to GestureDetectors. | plan 01-06 SUMMARY (`217db0c`) |
| auth_controller.dart scrub: the file `lib/features/auth/presentation/controllers/auth_controller.dart` and its test `test/features/auth/presentation/controllers/auth_controller_simple_test.dart` do NOT exist on disk (verified `ls lib/features/auth/presentation/controllers/` was empty pre-plan-06; post-plan-06 it contains only `forgot_password_controller.dart`). 4 stale references in CLAUDE.md (lines 66, 786, 828, 849) replaced with `test/features/auth/data/providers/supabase_auth_provider_test.dart` (the actual auth test path) plus a forward-pointer to the new ForgotPasswordController. Future doc edits MUST NOT re-introduce auth_controller references. | plan 01-06 SUMMARY (`47339ee`) |
| Wompi as payment processor (PSE/Nequi/Daviplata/cards) | PROJECT.md |
| Solo Colombia v1.0 | PROJECT.md |
| 4-6 month timeline, feature-complete priority | PROJECT.md |
| Manual XTool F1 Ultra operation in v1 | PROJECT.md |
| QR-10 explicit toggle: print-safe / digital-only / tattoo-safe | PROJECT.md |
| Logo cap 20% (15% tattoo) with EC level H hard-coded | PROJECT.md, PITFALLS.md |
| QR exported dark-on-light for marketplace regardless of theme | PROJECT.md, PITFALLS.md |
| Wompi via REST + Web Checkout in `webview_flutter` (not community SDK) | STACK.md |
| All engraved QRs route through `qraft.link/{slug}` (foundation for v2) | PROJECT.md, v2-vision.md |
| Tattoo line as minimal product in v1 (TAT-01..04) | PROJECT.md |
| DIAN factura DEFERRED to v2 with risk acceptance ≤950 UVT | PROJECT.md, v2-vision.md |
| Free destination editing in v1 (no monetization friction) | PROJECT.md, v2-vision.md |
| `pretty_qr_code` 3.6.0 for advanced customization (replaces qr_flutter for QR-02..06) | research SUMMARY.md |
| `mobile_scanner` 7.2.0 (Vision API on iOS) — unblocks SCAN-01 | research SUMMARY.md |
| Server-authoritative order FSM (Postgres CHECK + RPC); client read-only | research ARCHITECTURE.md |
| Idempotent webhook via `payment_events.event_id PRIMARY KEY` | research ARCHITECTURE.md |
| Customization snapshot pattern (JSONB + 2160px PNG) frozen at cart/order time | research ARCHITECTURE.md |
| Server-side `compute_order_totals()` for IVA + envío (NOT client-computed) | research ARCHITECTURE.md, PITFALLS.md |
| Wompi secrets ONLY in Supabase Edge Function env (never in Flutter app) | research STACK.md, PITFALLS.md |

### Decisions to Revisit

| Decision | Trigger |
|----------|---------|
| Test coverage of checkout flow as priority | User did not mark as priority but app handles real money — propose during Phase 9 plan review |
| DIAN deferral risk acceptance | If v1 volume exceeds ~50 órdenes/mes or fiscal pressure emerges, accelerate as hotfix |
| Free destination editing in v1 | If abuse emerges (mass automated changes), introduce rate limit in v1.x |
| Operator dashboard tech (Flutter Web vs Supabase Studio) | Decided during Phase 11 research |
| AI provider for QRD-02 (Replicate vs Stability vs OpenAI) | Decided during Phase 6 research |
| **QR encoding strategy: qraft.link redirect vs inline data, parametrizable per-QR** | **MUST resolve before `/gsd-discuss-phase 2`.** Surface raised 2026-05-01 during Phase 1 discussion: the locked anchor "todo engraved → qraft.link/{slug}" only works for URL-type QRs; texto/vCard/WiFi/eventos/ubicación REQUIRE inline data because scanners cannot execute native actions (join WiFi, save contact, open map, add calendar event) from a redirect URL. Need to decide: (a) parametrizable user-choice with helper UI defaulting to qraft.link for URL and direct for others, (b) restrict marketplace to URL-type only, (c) hybrid heterogeneous engraving, (d) abandon qraft.link strategy. Affects Phases 2/4/5/7 and `.planning/v2-vision.md`. |

### Active Todos

- [x] Verify Flutter SDK ≥ 3.29 (mobile_scanner 7.x requirement) — Phase 1 ✓ Plan 01-01 (`3ca9881`): `sdk: ^3.7.0` + `flutter: '>=3.29.0'`; mobile_scanner@7.2.0 locked
- [x] Run `flutter pub upgrade --dry-run` to confirm `firebase_core` upgrade path — Phase 1 ✓ Plan 01-03 (`5da00cc`): firebase_core 4.7.0 resolved cleanly on top of plan 01-01 baseline
- [x] Confirm `pubspec.lock` resolves `pretty_qr_code` alongside `qr_flutter` (both depend on `qr` package) — Phase 1 plan 01-04 ✓ (`flutter pub get` exited 0 with both `pretty_qr_code: 3.6.0` and `qr_flutter: 4.1.0` resolved; transitive `qr 3.0.2` shared between them with no conflict)
- [ ] Update `01-PATTERNS.md:498` snippet from `sdk: ^3.29.0` to `sdk: ^3.7.0` + `flutter: '>=3.29.0'` (carried over from plan 01-01 deferred-items)
- [ ] Investigate pre-existing CocoaPods warning about `Pods-Runner.profile.xcconfig` base configuration — surfaced during plan 01-03 pod install but not introduced by it; defer to plan 01-07 verifier
- [ ] Register `qraft.link` (or chosen alternative) domain — Phase 4
- [ ] Source real photography of materials (madera, acrílico, metal, cuero, vidrio, piedra) — before Phase 7
- [ ] Engage Colombian lawyer for terms review and Ley 1480 / 1581 disclaimer language — before Phase 9
- [ ] Acquire Wompi sandbox + production keys; configure in Supabase Edge Function env — Phase 9

### Blockers

None currently. All identified blockers (mobile_scanner iOS, ForgotPasswordDialog tests, AdMob UMP) are explicitly scoped INTO Phase 1 success criteria.

### Phases Requiring Research Before Planning

Per ROADMAP.md "Phases Needing /gsd-research-phase Before Planning":

- Phase 3 — Scanner-matrix CI setup
- Phase 5 — `pretty_qr_code` eye-style compat matrix
- Phase 6 — AI provider + animated export libs + native widgets
- Phase 7 — Material photography
- Phase 11 — Operator tech decision + tattoo skin-sample testing

Phases 1, 2, 4, 8, 9, 10, 12 can proceed directly to `/gsd-plan-phase`.

## Session Continuity

**Files written this session (plan 01-06 execution):**
- `lib/features/auth/presentation/controllers/forgot_password_controller.dart` (created, 142 lines) — ForgotPasswordState + ForgotPasswordController + forgotPasswordControllerProvider
- `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` — refactored to consume controller; `_emailSent` removed; +5 Maestro Keys; +2 Semantics labels
- `lib/features/auth/presentation/pages/login_screen.dart` — extended `_buildTextField` with optional `Key? fieldKey` param; +5 Maestro Keys
- `lib/features/auth/presentation/pages/welcome_screen.dart` — +3 Maestro Keys
- `lib/features/main/main_scaffold.dart` — +1 root Key + new `MainScaffoldKeys` class enumerating all 5 tab Keys; passes Keys to MainNavigation
- `lib/shared/widgets/main_navigation.dart` — extended with optional `Key?` params per tab; applied to GestureDetectors in `_buildNavItem` and `_buildCenterButton`
- `lib/features/qr_scanner/qr_scanner_screen.dart` — +1 Scaffold root Key
- `CLAUDE.md` — test-count line corrected; 4 auth_controller(_simple_test).dart references scrubbed and replaced with supabase_auth_provider_test.dart + ForgotPasswordController forward-pointer
- `.planning/codebase/CONCERNS.md` — test-count corrected in 2 places (Known Bugs + Test Coverage Gaps)
- `.planning/phases/01-foundation-hardening/01-06-forgot-password-controller-refactor-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 01-06 checkbox marked + Phase 1 progress 5/8)

**Files from prior sessions:**
- Plan 01-04: `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock`, `android/app/build.gradle.kts`, `macos/Flutter/GeneratedPluginRegistrant.swift`, plan 01-04 SUMMARY
- Plan 01-03: `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `android/app/build.gradle.kts`, `android/build.gradle.kts`, `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`, `lib/main.dart`, `lib/l10n/app_localizations.dart`, plan 01-03 SUMMARY
- Plan 01-01: `pubspec.yaml`, `pubspec.lock` (initial SDK + scanner bumps)
- Plan 01-02: `.maestro/{config.yaml,.tool-versions,CONVENTIONS.md,helpers/*}`
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/v2-vision.md`, `.planning/config.json`
- `.planning/research/{SUMMARY,STACK,ARCHITECTURE,PITFALLS}.md`
- `.planning/codebase/{STACK,ARCHITECTURE,CONCERNS}.md`
- `.planning/phases/01-foundation-hardening/{01-CONTEXT,01-PATTERNS,01-01..06-PLAN,01-01..04+06-SUMMARY}.md`

**Next command:** `/gsd-execute-phase 1` continuation — pending plans `01-05` (UMP+AdMob), `01-07` (Maestro flows + controller tests), `01-08` (phase verification).

**Recommended next plans (Phase 1 wave order):**
- `01-05-ump-consent-and-admob-gating-PLAN.md` (depends on 01-04; will introduce ump_* widgets following CONVENTIONS.md; will extract AdMob init from `lib/main.dart:43` behind UMP gate; imports `ConsentInformation`/`ConsentForm` from already-installed google_mobile_ads ^5.1.0 — no separate UMP install needed since plan 04 deliberately did not add one)
- `01-07-maestro-flows-and-controller-tests-PLAN.md` (READY: depends on 01-06 Maestro Keys + ForgotPasswordController. Tasks: rewrite forgot_password_dialog_test.dart against the controller via MockSupabaseClient injection; author forgot_password_controller_test.dart unit tests; tighten `.maestro/helpers/login.yaml` from text- to id-matchers using the 5 login_* Keys plan 06 added; author 9 phase-1 Maestro flows; run on iOS sim + Android emulator)
- `01-08-phase-verification-PLAN.md` (D-11 closure suite; produces 01-VERIFICATION.md)

---
*State initialized: 2026-05-01 by gsd-roadmapper*
*Last updated: 2026-05-01 by plan 01-06 executor*
