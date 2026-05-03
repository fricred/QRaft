---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-03T13:34:36Z"
progress:
  total_phases: 12
  completed_phases: 3
  total_plans: 23
  completed_plans: 23
  percent: 91
---

# State: QRaft v1.0

**Last updated:** 2026-05-03 (post plan 05-05)

## Project Reference

**Core value**: Cerrar el loop digital→físico con un QR personalizado de calidad — diseñar → personalizar → comprar → recibir grabado, todo en pesos colombianos sin fricción.

**Current focus**: Phase 7 IN PROGRESS (1/4 plans — 07-01 ✓ 2026-05-03). Phase 6 IN PROGRESS (2/4 plans — 06-01 ✓, 06-02 ✓ 2026-05-03). Phase 5 COMPLETE (5/5 plans). Phase 4 COMPLETE. Phase 3 in parallel (2/3 plans done, 03-03 pending). Next: Phase 6 plans 06-03 (QR scannability gate) or Phase 7 plans 07-02 (MaterialFilterBar + ProductVariantCard UI).

**Strategic anchors**:

- Brownfield foundation: Auth, GlassButton, deeplinks, i18n, Supabase, AdMob inicial — preservar y construir encima
- Every engraved QR routes through `qraft.link/{slug}` (RDR-01..06) — non-negotiable architecture
- Solo Colombia v1, COP, Wompi, IVA 19%
- DIAN factura electrónica DEFERRED to v2 with explicit risk acceptance
- Manual fulfillment via operator dashboard (no IoT in v1)

## Current Position

**Milestone:** v1.0
**Phase:** 6 of 12 — QR Digital-Only Features, IN PROGRESS
**Plan:** 06-02 ✓ 2026-05-03 (2/4 plans)
**Status:** Phase 7 in progress (1/4 plans); Phase 6 in progress (2/4 plans); Phase 5 COMPLETE; Phase 4 COMPLETE; Phase 3 in progress (2/3 plans)
**Last session:** 2026-05-03 — Plan 07-01 (Marketplace catalog schema + data/domain/provider stack) executed on `feature/adds`. Tasks 1+3 autonomous (commits `bd39494` 14 Flutter tests, `7eeae6d` 9 flow YAMLs); semantics rollout `627859d`; manual close-out commits `41908d0` (remove legacy SupabaseForgotPasswordDialog from main.dart, freeing 215 lines of dead code), `cb1663c` (Semantics(identifier:) on dashboard_profile_button + profile_sign_out_button + profile_sign_out_confirm_button), `3cf599d` (Maestro YAML iterations: suite recursion config, scrollUntilVisible for off-fold welcome CTA, pressKey:Enter for keyboard-occluded login_submit_button), `b52d28f` (Navigator.popUntil(isFirst) after signOut + 30s timeout on logout assertion), `3c29309` (CONVENTIONS.md Phase 1 status section). Android Medium_Phone suite: **8/9 flows PASS** (splash-happy 8s, ump-accept 7s, ump-deny-npa 9s, login-valid 27s, login-invalid 24s, forgot-password 24s, session-persistence 37s, scanner-tab-launch 37s) — auth/logout RESIDUAL with the loading dialog "Cerrando sesión..." stuck visible past 30s, signOut() hangs at the SupabaseClient call (likely interaction with subscription realtime listener teardown in AuthWrapper). iOS suite ran on iPhone 17 Pro pre-Semantics (4/7 pass, expected); not re-run after Semantics+popUntil fixes — recommended at start of next session. Real product bugs surfaced and fixed by Maestro E2E (legacy dialog dead code, Navigator stack occlusion). Plan 01-07 deviations: 6 auto-fixed (4 Rule 3 blocking, 2 Rule 4 functionally required). flutter analyze: 0 issues. Whole-suite test delta from `+83 ~1 -91` to `+97 ~1 -85` (the 6 broken-by-design dialog tests from plan 01-06 are now sane; +8 controller tests added). Earlier session: Plan 01-05 (UMP consent + AdMob gating) executed sequentially on `feature/adds`, 3 tasks, ~7 minutes. Commits `cd834ff` (consent module: ConsentState + UmpService + 5 providers) + `b7ad68a` (UmpConsentScreen + UmpGate) + `8518f79` (main.dart bootstrap reorder + AdMobService 4 method signatures + BannerAdWidget + RewardedAdButton + ad_providers refactor). New `lib/features/consent/` feature module: `ConsentState` enum with 5 values (unknown/required/notRequired/obtained/denied) + `ConsentStateX` extension exposing `isResolved` + `isPersonalizedAllowed` booleans (37 lines); `UmpService` singleton (132 lines) wrapping `ConsentInformation.instance.requestConsentInfoUpdate` + `ConsentForm.loadAndShowConsentFormIfRequired` from google_mobile_ads ^5.1.0 — NO separate UMP package install per plan 04 D-01 — using Completer-to-Future bridge over the callback-based UMP API; accept-vs-deny disambiguation via `canRequestAds()` because `ConsentStatus.obtained` covers both; fail-open posture so app does not deadlock on UMP errors. 5 Riverpod providers (umpServiceProvider, umpInitProvider, consentStateProvider, umpConsentReadyProvider, consentGrantedProvider). UmpConsentScreen ConsumerStatefulWidget triggers Google's UMP form on first frame via `WidgetsBinding.instance.addPostFrameCallback`; Carden Pro design tokens (#1A1A1A scaffold + #2E2E2E 24-radius card) + PrimaryGlassButton CTA + 2 stable Maestro Keys (`ump_consent_screen_root`, `ump_continue_button`). UmpGate ConsumerWidget with `.when()` loading/error/data branches; explicit `consent_state.dart` import so `state.isResolved` extension getter resolves. main.dart bootstrap reordered per D-04: removed `MobileAds.instance.initialize()` from `initializeApp()` (now only env → Supabase → Firebase); added `ref.listen<bool>(umpConsentReadyProvider, ...)` in `_QRaftAppState.build` that fires `ref.read(adMobInitProvider.future)` exactly once on UMP-resolves transition (FutureProvider memoization + idempotent `AdMobService.initialize()` keep it safe); AuthWrapper wrapped in `UmpGate(child: AuthWrapper())`. AdMobService 4 ad-loading methods (loadBannerAd lines 33-69, showRewardedAd lines 70-118, showInterstitialAd lines 130-181, loadNativeAd lines 184-217) now accept `bool nonPersonalizedAds = false` and pass it into `AdRequest(nonPersonalizedAds: nonPersonalizedAds)` per D-06; 0 `const AdRequest()` remaining, 4 `AdRequest(nonPersonalizedAds:` sites. BannerAdWidget._loadAd() bails if `!umpConsentReadyProvider` (D-04) AND passes `nonPersonalizedAds: !consentGranted` (D-06); `build()` watches `umpConsentReadyProvider` + ref.listen re-triggers `_loadAd` when consent flips ready post-construction (re-entrancy guard `!_isLoaded && !_isLoading`) — handles widgets built before UMP resolves. RewardedAdButton._showRewardedAd() reads consentGrantedProvider and forwards `!personalizedAllowed`. ad_providers.dart `dashboardBannerAdProvider` + `libraryBannerAdProvider` both gate on `umpConsentReadyProvider` AND forward npa flag. Maestro selector deviation documented: `ump_settings_link` Key NOT added because the "manage settings" link is rendered by Google's UMP system overlay (not a Flutter widget); plan 07 will target it via text matcher. flutter analyze: 0 issues; flutter build apk --debug --target-platform android-arm64: Built in 9.5s; flutter build ios --debug --no-codesign: Built in 9.9s. Whole-suite test delta unchanged from plan 06 (`+83 ~1 -91` — 0 new test breakage from this plan). Closes ROADMAP success criterion #4 (UMP integrated, consent form on first launch before any ad request).

**Progress:** [▰▰▰▰▰▱▱▱▱▱▱▱] 5/12 phases complete (41.7%) — Phase 3 in progress (2/3 plans); Phase 5 COMPLETE; Phase 7 in progress (1/4 plans)

```
Phase 1:  ▰ Foundation Hardening              ✓ COMPLETE (passed-with-residuals 2026-05-01)
Phase 2:  ▰ QR Generation Core                ✓ COMPLETE 2026-05-02 (4/4 plans)
Phase 3:  ▱ QR Scanner                        IN PROGRESS (2/3 plans — 03-03 pending)
Phase 4:  ▰ Redirect Service Foundation       ✓ COMPLETE 2026-05-01 (3/3 plans)
Phase 5:  ▰ QR Customization (Print-Safe)     ✓ COMPLETE 2026-05-03 (5/5 plans)
Phase 6:  ▱ QR Digital-Only Features          IN PROGRESS (2/4 plans — 06-01 ✓, 06-02 ✓ 2026-05-03)
Phase 7:  ▱ Marketplace Catalog + QR Export   IN PROGRESS (1/4 plans — 07-01 ✓ 2026-05-03)
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
| QRPreviewWidget uses PrettyQrView.data() with const PrettyQrDecoration() defaults — Phase 5 extends with gradient/eyeStyle/logo; Colors.white hardcoded (T-02-04 dark-on-light) | plan 02-02 SUMMARY (`dc3b7c2`) |
| repaintKey pattern: GlobalKey in each QR screen State + RepaintBoundary wrapping QrImageView; Plan 05 reads via RenderRepaintBoundary.toImage() — no additional wiring needed | plan 02-02 SUMMARY (`b3dafe9`) |
| EventData iCal uses local time (no Z suffix) for v1 — avoids timezone complexity for first-party generated events | plan 02-01 SUMMARY (`1d34017`) |
| QRType.event now routes to EventQRScreen (plan 02-03 replaces ComingSoonQRScreen stub; coming_soon import removed from qr_generator_screen.dart) | plan 02-03 SUMMARY (`51cae1c`) |
| EventQRScreen edit mode Phase 2 simplification: pre-fills name only, no iCal re-parse — full round-trip deferred to Phase 5 | plan 02-03 SUMMARY (`9b244f9`) |
| FeatureType.qrTypeEvent added to feature gate infrastructure — event type treated identically to other QR types for plan/subscription gating | plan 02-01 SUMMARY (`057ce60`) |
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
| Atomic scan_count increment deferred to plan 04-02 Postgres RPC; v1 uses read-modify-write in RedirectRepositoryImpl.incrementScanCount | plan 04-01 SUMMARY (`8122624`) |
| `supabaseClientProvider` introduced as overridable Riverpod Provider so tests can inject mock SupabaseClient without global Supabase.instance dependency | plan 04-01 SUMMARY (`8122624`) |
| auto-update trigger `trg_redirects_updated_at` added to redirects migration for server-side updated_at management | plan 04-01 SUMMARY (`8122624`) |
| redirects migration `20260502000000_redirects_table.sql` requires manual application via Supabase Dashboard → SQL Editor; NOT auto-applied | plan 04-01 SUMMARY (`8122624`) |
| RedirectEditScreen takes slug → loads redirect entity id → calls updateDestinationUrl(id:, destinationUrl:); empty slug shows "no redirect linked" gracefully (QRCodeEntity has no slug field yet) | plan 04-03 SUMMARY (`6f3a055`) |
| Follow-up required: add `slug` column to qr_codes table + expose on QRCodeEntity so `_editRedirectDestination` can pass real slug instead of `''` | plan 04-03 SUMMARY (`6f3a055`) |
| `pretty_qr_code` 3.6.0 for advanced customization (replaces qr_flutter for QR-02..06) | research SUMMARY.md |
| QrProfile stored as int index in QRCustomization for Equatable/JSON compat; QrProfile.values[index] used in controller | plan 05-01 SUMMARY (`f34f456`) |
| logoCoverage clamped at controller entry (updateLogoCoverage) as first-line T-05-01-01 defense; QrProfileValidator provides second-line check at export | plan 05-01 SUMMARY (`f34f456`) |
| updateProfile() auto-enforces EC-H when profile.requiresEcH is true and current level < 3 | plan 05-01 SUMMARY (`f34f456`) |
| GradientType.solid as default ensures zero migration cost for all existing QRCustomization instances | plan 05-01 SUMMARY (`f34f456`) |
| QrDecorationBuilder is the single wiring layer between QRCustomization and pretty_qr_code API; plans 03/04 extend buildDecoration shape field additively | plan 05-02 SUMMARY (`36c7873`) |
| QrImage built in initState/didUpdateWidget never in build() — prevents per-frame QR regeneration overhead | plan 05-02 SUMMARY (`37b0327`) |
| Logo coverage double-clamped: controller clamps at write (05-01), builder clamps at render (05-02) — defense in depth | plan 05-02 SUMMARY (`36c7873`) |
| EC-H forced at render time in buildQrImage when hasLogo=true regardless of stored errorCorrectionLevel | plan 05-02 SUMMARY (`36c7873`) |
| buildBrush return type is dynamic — PrettyQrBrush extends Color, both valid at runtime; plan 05-04 casts to PrettyQrBrush when wiring into shape constructor | plan 05-03 SUMMARY (`23cebed`) |
| QrExportService.exportPrintSafe forces white background via copyWith(background: Colors.white) — in-app theme cannot override (T-05-03-04 mitigated) | plan 05-03 SUMMARY (`23cebed`) |
| exportDigitalOnly passes decoration through as-is (no white bg override) — QrProfile.digitalOnly allows inverted colors | plan 06-01 SUMMARY (`8c0cda2`) |
| ai-stylize Edge Function reads REPLICATE_API_KEY from Deno.env (T-06-01); prompt sanitized server-side with /[^\w\s.,!?-]/g + 200-char cap (T-06-02); 5/month gate via ai_style_usage upsert (T-06-03) | plan 06-01 SUMMARY (`52c9ce4`) |
| mobile_scanner 7.2.0 analyzeImage(String imagePath) → Future<BarcodeCapture?> API documented in QrAnimationService stub as code comment — plan 06-03 builds against this signature | plan 06-01 SUMMARY (`52c9ce4`) |
| image 4.5.4 animated GIF uses Image.addFrame() pattern (not removed Animation class); Image.loopCount=0 + FrameType.animation; delay in centiseconds (delayMs ~/10) | plan 06-02 SUMMARY (`32b3398`) |
| QrAnimationService opacity-pulse modulates background alpha via copyWith(background:) — foreground color lives inside shape symbols not on PrettyQrDecoration directly | plan 06-02 SUMMARY (`32b3398`) |
| share_plus v10 uses Share.shareXFiles(List<XFile>) not SharePlus.instance.share(ShareParams()) | plan 06-02 SUMMARY (`6286f54`) |
| _encodeGifIsolate is a top-level function (not closure/method) — compute() isolate boundary requirement | plan 06-02 SUMMARY (`32b3398`) |
| Color equality uses toARGB32() not .value — .value is deprecated in current Flutter SDK | plan 05-03 SUMMARY (`14ccacc`) |
| Export size fixed at 2160px (not user-controllable) — DoS via size parameter impossible (T-05-03-02 accepted) | plan 05-03 SUMMARY (`23cebed`) |
| PrettyQrShape is abstract — buildShape() catch fallback uses PrettyQrSquaresSymbol() not PrettyQrShape() (which fails to compile) | plan 05-04 SUMMARY (`2ae992c`) |
| PrettyQrDotsSymbol module presets 5-7 explicitly set unifiedFinderPattern:false so dots don't override finder pattern — eye symbol handles that via finderPattern: param | plan 05-04 SUMMARY (`2ae992c`) |
| QrFrameWidget does not accept or modify quietZone — decoration passed through unchanged; 8px container padding is outside QR bounds | plan 05-04 SUMMARY (`9492b35`) |
| csv 8.0.0 deprecated CsvCodec → renamed to Csv class; use Csv(fieldDelimiter:';', autoDetect:false) — autoDetect:true default ignores the configured delimiter | plan 05-05 SUMMARY (`9575e8e`) |
| kQrTemplates const list (8 entries) — templates are compile-time constants, cannot be injected via applyFullTemplate UI path (T-05-05-04 accepted) | plan 05-05 SUMMARY (`2a41954`) |
| QrBulkImportSheet uses CSV paste TextFormField (file_picker not in pubspec) — TODO comment documents upgrade path | plan 05-05 SUMMARY (`2a41954`) |
| `mobile_scanner` 7.2.0 (Vision API on iOS) — unblocks SCAN-01 | research SUMMARY.md |
| price_cop in materials catalog stored as INT (whole COP pesos, NOT cents) — Wompi multiply ×100 at checkout (Phase 9) | plan 07-01 SUMMARY |
| materials.id is TEXT PK ('wood','acrylic','metal','leather','glass','stone') — stable FK reference, not UUID | plan 07-01 SUMMARY |
| texture_url defaults to empty string until PNGs uploaded to Supabase Storage bucket `material-textures/`; callers guard `.isEmpty` and fall back to `MaterialGradients.forCategory()` | plan 07-01 SUMMARY |
| texture_url validated to https:// only in MaterialModel.fromJson (T-07-02 mitigated); fail-safe: non-https sanitized to empty string | plan 07-01 SUMMARY (`bbace05`) |
| catalogProvider uses `FutureProvider.autoDispose` + nested SELECT (single denormalized JOIN query, no N+1) | plan 07-01 SUMMARY |
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

**Files written this session (plan 07-01 execution):**

- `supabase/migrations/20260501000000_marketplace_catalog.sql` — 3 tables (materials/products/product_variants), 3 RLS policies (public SELECT only), 6-material + 2-product + 12-variant seed; price_cop INT (whole COP pesos)
- `lib/features/marketplace/domain/entities/material_entity.dart` — Equatable MaterialEntity; textureUrl may be empty
- `lib/features/marketplace/domain/entities/product_variant_entity.dart` — Equatable ProductVariantEntity; int priceCop
- `lib/features/marketplace/domain/repositories/product_repository.dart` — abstract ProductRepository with getActiveCatalog()
- `lib/features/marketplace/data/models/material_model.dart` — fromJson + toEntity(); https-only texture_url guard (T-07-02)
- `lib/features/marketplace/data/models/product_variant_model.dart` — fromJson reads nested product + material keys
- `lib/features/marketplace/data/datasources/product_supabase_data_source.dart` — single denormalized JOIN query
- `lib/features/marketplace/data/repositories/product_repository_impl.dart` — wires datasource → entities
- `lib/features/marketplace/presentation/providers/marketplace_providers.dart` — catalogProvider + activeMaterialFilterProvider + filteredCatalogProvider
- `.planning/phases/07-marketplace-catalog/07-01-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (07-01 checkbox marked)

**Last session (plan 07-01):** 2026-05-03 — Marketplace catalog SQL migration + full Dart domain/data/provider stack. Commits `5fce44c` (migration) + `92435e2` (8 Dart files) + `bbace05` (T-07-02 texture_url https-only). flutter analyze lib/features/marketplace/: 0 issues. Phase 7 in progress (1/4 plans).

**Files written this session (plan 06-02 execution):**

- `lib/features/qr_digital/domain/services/qr_animation_service.dart` — full implementation: captureFrames() sine-curve pulse + buildGif() in compute() isolate using image 4.5.4 Image.addFrame() API
- `lib/features/qr_digital/presentation/controllers/qr_digital_controller.dart` — QrDigitalState + QrDigitalController + qrDigitalControllerProvider (autoDispose.family)
- `lib/features/qr_digital/presentation/pages/qr_animate_page.dart` — QrAnimatePage with flutter_animate opacity-pulse preview, GlassButton export, profile guard banner, SnackBar error
- `test/features/qr_digital/services/qr_animation_service_test.dart` — 5 real unit tests replacing wave-0 sentinel; GIF magic bytes, ArgumentError, delayMs
- `.planning/phases/06-qr-digital-features/06-02-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 06-02):** 2026-05-03 — QrAnimationService full impl + QrDigitalController + QrAnimatePage. Commits `32b3398` (service + tests) + `6286f54` (controller + page). flutter analyze 0 issues. 5/5 tests pass. Phase 6 in progress (2/4 plans). Key deviations: image v4 API (Image.addFrame not Animation class), share_plus v10 API (Share.shareXFiles not SharePlus.instance.share), background-alpha pulse (foreground in shape symbols).

**Files written this session (plan 06-01 execution):**

- `lib/features/qr_generator/domain/services/qr_export_service.dart` — added exportDigitalOnly() static method (no white bg override, size param)
- `supabase/functions/ai-stylize/index.ts` — Replicate proxy Edge Function: JWT validation, prompt sanitization, 5/month gate, CORS headers
- `lib/features/qr_digital/domain/services/qr_animation_service.dart` — stub with analyzeImage API docs
- `test/features/qr_digital/services/qr_animation_service_test.dart` — wave-0 sentinel
- `test/features/qr_digital/services/qr_ai_style_service_test.dart` — wave-0 sentinel
- `test/features/qr_digital/services/qr_widget_service_test.dart` — wave-0 sentinel
- `.planning/phases/06-qr-digital-features/06-01-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 06-01):** 2026-05-03 — Replicate Edge Function proxy + exportDigitalOnly + wave-0 test sentinels. Commits `8c0cda2` (scaffolds + exportDigitalOnly) + `52c9ce4` (Edge Function + QrAnimationService stub). flutter analyze 0 issues. Phase 6 in progress (1/4 plans).

**Files written this session (plan 05-05 execution):**

- `lib/features/qr_generator/domain/services/qr_bulk_import_service.dart` — QrBulkImportService + BulkQrRow + QrBulkImportException; Csv(fieldDelimiter:';', autoDetect:false); 1MB + 500-row caps
- `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` — QrFullTemplate class + kQrTemplates const list (8 entries) + applyFullTemplate() method added
- `lib/features/qr_generator/presentation/widgets/qr_template_gallery.dart` — QrTemplateGalleryWidget 2-column grid with mini QR previews + profile badges
- `lib/features/qr_generator/presentation/widgets/qr_bulk_import_sheet.dart` — QrBulkImportSheet CSV paste + live row-count preview + friendly error cards
- `test/features/qr_generator/domain/qr_bulk_import_test.dart` — 7 unit tests (RED `64f2deb` + GREEN `9575e8e`)
- `.planning/phases/05-qr-customization/05-05-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (Phase 5 marked COMPLETE)

**Last session (plan 05-05):** 2026-05-03 — 8 curated templates + applyFullTemplate + QrTemplateGalleryWidget + QrBulkImportService + QrBulkImportSheet. Commits `64f2deb` (RED tests) + `9575e8e` (GREEN service) + `2a41954` (templates + gallery + sheet). flutter analyze lib/features/qr_generator/ 0 issues. 7 bulk import tests pass. Phase 5 COMPLETE (5/5 plans).

**Files written this session (plan 05-04 execution):**

- `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` — buildShape() + _moduleSymbol() + _eyeSymbol() added; buildDecoration() updated to pass shape: buildShape(c)
- `lib/features/qr_generator/presentation/widgets/qr_preset_gallery.dart` — QrPresetGalleryWidget with 8 module + 8 eye preset thumbnails (scrollable rows)
- `lib/features/qr_generator/presentation/widgets/qr_frame_widget.dart` — QrFrameWidget CTA frame wrapper; quiet zone never modified
- `test/features/qr_generator/domain/qr_decoration_builder_test.dart` — 4 buildShape tests added (RED `29ebda1` + GREEN `2ae992c`), 19 total
- `test/features/qr_generator/widgets/qr_frame_widget_test.dart` — 3 frame widget tests (CTA layout, padding, quiet zone invariant)
- `.planning/phases/05-qr-customization/05-04-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 05-04):** 2026-05-02 — buildShape 8+8 presets + QrPresetGalleryWidget + QrFrameWidget + tests. Commits `29ebda1` (RED) + `2ae992c` (GREEN) + `9492b35` (widgets). flutter analyze lib/features/qr_generator/ 0 issues. 19 + 3 tests pass. Phase 5 in progress (4/5 plans).

**Files written this session (plan 05-03 execution):**

- `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` — buildBrush(QRCustomization) static method added: Color for solid, PrettyQrBrush.gradient for linear/radial
- `lib/features/qr_generator/domain/services/qr_export_service.dart` — QrExportService.exportPrintSafe: 2160px PNG export via toImageAsBytes, white background forced (T-05-03-04)
- `lib/features/qr_generator/presentation/widgets/qr_color_picker.dart` — QrColorPickerWidget: 8 Carden Pro preset swatches + validated hex input
- `test/features/qr_generator/domain/qr_decoration_builder_test.dart` — 4 buildBrush tests added (RED `ae4e1a5` + GREEN `23cebed`), 15 total
- `.planning/phases/05-qr-customization/05-03-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 05-03):** 2026-05-02 — buildBrush gradient support + QrExportService + QrColorPickerWidget. Commits `ae4e1a5` (RED tests) + `23cebed` (GREEN impl) + `14ccacc` (color picker). flutter analyze lib/features/qr_generator/ 0 issues. 15 tests pass. Phase 5 in progress (3/5 plans).

**Files written this session (plan 05-02 execution):**

- `lib/features/qr_generator/domain/services/qr_decoration_builder.dart` — QrDecorationBuilder static factory: buildDecoration + buildQrImage
- `lib/features/qr_generator/presentation/widgets/qr_logo_picker.dart` — logo picker with PNG/JPG whitelist, 2MB gate, CircleAvatar preview
- `lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart` — upgraded to ConsumerStatefulWidget; QrImage in initState; PrettyQrView via QrDecorationBuilder
- `test/features/qr_generator/domain/qr_decoration_builder_test.dart` — 11 unit tests (RED `5254012` + GREEN `36c7873`)
- `.planning/phases/05-qr-customization/05-02-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 05-02):** 2026-05-02 — QrDecorationBuilder + QrLogoPickerWidget + QRPreviewWidget upgrade. Commits `5254012` (RED tests) + `36c7873` (GREEN impl) + `37b0327` (logo picker + preview widget). flutter analyze lib/ 0 issues. APK debug build success. Phase 5 in progress (2/5 plans).

**Files written this session (plan 05-01 execution):**

- `lib/features/qr_generator/domain/value_objects/qr_profile.dart` — QrProfile + GradientType enums + QrProfileConstraints extension
- `lib/features/qr_generator/domain/services/qr_profile_validator.dart` — QrProfileValidator static service + QrValidationResult
- `lib/features/qr_generator/domain/entities/qr_code_entity.dart` — QRCustomization extended with 9 Phase 5 fields (hasGradient, gradientStart, gradientEnd, gradientType, modulePreset, eyePreset, profile, frameText, logoCoverage)
- `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` — 6 new methods added (updateProfile, updateModulePreset, updateEyePreset, updateGradient, updateFrameText, updateLogoCoverage)
- `lib/features/qr_generator/presentation/widgets/qr_profile_toggle.dart` — Material 3 SegmentedButton with Semantics identifier
- `test/features/qr_generator/domain/qr_profile_validator_test.dart` — 8 unit tests (TDD RED then GREEN)
- `test/features/qr_generator/presentation/controllers/qr_customization_controller_phase5_test.dart` — 16 unit tests
- `.planning/phases/05-qr-customization/05-01-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 05-01):** 2026-05-01 — QrProfile enum + QrProfileValidator + QRCustomization 9-field extension + controller 6 new methods + QrProfileToggle widget. Commits `c2f992b` (RED validator tests) + `19bdca9` (GREEN validator impl) + `d61a72f` (RED controller tests) + `f34f456` (GREEN controller impl). flutter analyze 0 issues. Phase 5 in progress (1/5 plans).

**Files written this session (plan 03-02 execution):**

- `lib/features/qr_scanner/providers/qr_scanner_provider.dart` — scanFromGallery rewritten to accept MobileScannerController + real analyzeImage call; _processGalleryMockResult deleted; noQRFoundInImage error state; stop/start camera wrapping analyzeImage
- `lib/features/qr_scanner/qr_scanner_screen.dart` — _scanFromGallery passes _controller! to provider; null guard added
- `lib/features/qr_scanner/widgets/scan_result_dialog.dart` — flutter_contacts import; case QRCodeType.vcard: FlutterContacts.requestPermission + insertContact; case QRCodeType.wifi: _WifiCredentialsSheet modal; _WifiCredentialsSheet + _CredentialRow private widgets; missing vcard label/icon fixed in _getActionButtonText/_getActionButtonIcon
- `.planning/phases/03-qr-scanner/03-02-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 03-02 checkbox marked)

**Last session (plan 03-02):** 2026-05-02 — Real gallery QR scan + vCard contact save + WiFi credential sheet. Commits `c6c1319` (analyzeImage) + `aa481bb` (vCard + WiFi). flutter analyze 0 issues. Phase 3 in progress (2/3 plans).

**Files written this session (plan 04-01 execution):**

- `supabase/migrations/20260502000000_redirects_table.sql` — redirects table DDL + RLS + auto-update trigger; needs manual application
- `lib/features/redirect/domain/entities/redirect_entity.dart` — RedirectEntity Equatable with fromJson/toJson/copyWith
- `lib/features/redirect/domain/repositories/redirect_repository.dart` — abstract interface (6 methods)
- `lib/features/redirect/domain/utils/slug_generator.dart` — SlugGenerator with Random.secure() + generateUntilUnique retry loop
- `lib/features/redirect/data/datasources/redirect_supabase_data_source.dart` — PostgREST datasource
- `lib/features/redirect/data/repositories/redirect_repository_impl.dart` — wires datasource + slug generation
- `lib/features/redirect/presentation/providers/redirect_providers.dart` — supabaseClientProvider + redirectRepositoryProvider + userRedirectsProvider
- `.planning/phases/04-redirect-service-foundation/04-01-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (04-01 checkbox marked, Phase 4 plans listed)

**Last session (plan 04-01):** 2026-05-02 — Redirects table migration + full Dart domain/data layer. Commit `8122624`. flutter analyze 0 issues. Phase 4 in progress (1/3 plans).

**Files written this session (plan 02-03 execution):**

- `lib/features/qr_generator/presentation/controllers/event_form_controller.dart` — EventFormState + EventFormController + eventFormProvider (autoDispose)
- `lib/features/qr_generator/presentation/widgets/forms/event_form.dart` — flutter_form_builder 6-field form (name, title, startDT required; endDT, location, description optional; description maxLength 500)
- `lib/features/qr_generator/presentation/pages/event_qr_screen.dart` — ConsumerStatefulWidget 2-tab Form/Style + edit mode + RepaintBoundary + Semantics key
- `lib/features/qr_generator/qr_generator_screen.dart` — event tile routes to EventQRScreen; coming_soon import removed; event_rounded in _getIconData
- `lib/features/qr_library/qr_library_screen.dart` — vevent filter chip added; filterEvent label; EventQRScreen in edit switch
- `lib/l10n/app_en.arb` + `lib/l10n/app_es.arb` — filterEvent key added ("Event"/"Evento")
- `lib/l10n/app_localizations*.dart` — regenerated
- `.planning/phases/02-qr-generation-core/02-03-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 02-03 checkbox marked)

**Last session (plan 02-04):** 2026-05-02 — QrShareButton widget created and wired to all 6 QR screens + library. Commits `8bba9fa` (QrShareButton + wiring + i18n) + `a0e4da1` (l10n regeneration). flutter analyze 0 issues, APK build success. Phase 2 COMPLETE (QR-09 implemented).

**Last session (plan 02-03):** 2026-05-02 — EventQRScreen implemented (6th QR type, QR-01 complete). Tasks 1+2 autonomous. Commits `9b244f9` (EventFormController + EventForm + EventQRScreen) + `51cae1c` (generator wiring + library filter). flutter analyze 0 issues. Phase 2 COMPLETE.

**Files written this session (plan 02-02 execution):**

- `lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart` — rewritten: PrettyQrView.data() replaces QrImageView; GlobalKey? repaintKey param; RepaintBoundary wraps container; Colors.white hardcoded; _TypeBadge private widget extracted
- `lib/features/qr_generator/presentation/pages/url_qr_screen.dart` — `final GlobalKey repaintKey = GlobalKey()` added to State; QrImageView wrapped in RepaintBoundary(key: repaintKey)
- `lib/features/qr_generator/presentation/pages/text_qr_screen.dart` — same repaintKey pattern
- `lib/features/qr_generator/presentation/pages/personal_info_qr_screen.dart` — same repaintKey pattern
- `lib/features/qr_generator/presentation/pages/wifi_qr_screen.dart` — same repaintKey pattern
- `lib/features/qr_generator/presentation/pages/email_qr_screen.dart` — same repaintKey pattern
- `lib/features/qr_generator/presentation/pages/location_qr_screen.dart` — same repaintKey pattern
- `.planning/phases/02-qr-generation-core/02-02-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 02-02 checkbox marked)

**Last session:** 2026-05-02 — Plan 02-02 (QRPreviewWidget PrettyQrView + RepaintBoundary) executed on `feature/adds`. Tasks 1+2 autonomous. Commits `dc3b7c2` (QRPreviewWidget rewrite) + `b3dafe9` (repaintKey on all 6 screens). flutter analyze 0 issues.

**Files written this session (plan 02-01 execution):**

- `lib/features/qr_generator/domain/entities/qr_type.dart` — added `QRType.event` (vevent, cyan gradient, event_rounded); all switch cases updated
- `lib/features/qr_generator/domain/entities/qr_data_models.dart` — added `EventData` class with VCALENDAR/VEVENT iCal serialization
- `lib/l10n/app_en.arb` + `lib/l10n/app_es.arb` — added qrTypeEvent / qrTypeEventDesc keys
- `lib/l10n/app_localizations*.dart` — regenerated via `flutter gen-l10n`
- `lib/features/qr_generator/presentation/pages/qr_form_screen.dart` — 5 switch case additions for event
- `lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart` — 2 switch case additions for event
- `lib/features/qr_generator/qr_generator_screen.dart` — event routes to ComingSoonQRScreen; import added
- `lib/features/qr_generator/domain/repositories/qr_repository.dart` — added getUserQRCodesPaginated abstract method
- `lib/features/qr_generator/data/datasources/qr_remote_data_source.dart` — added getUserQRCodesPaginated to interface
- `lib/features/qr_generator/data/datasources/qr_supabase_data_source.dart` — implemented getUserQRCodesPaginated with .range()
- `lib/features/qr_generator/data/repositories/qr_repository_impl.dart` — implemented getUserQRCodesPaginated with local cache fallback
- `lib/features/subscription/domain/entities/feature_access.dart` — added FeatureType.qrTypeEvent
- `lib/features/subscription/presentation/providers/feature_gate_providers.dart` — added event cases to _qrTypeToFeature + _qrTypeDisplayName
- `supabase/migrations/20260501100000_add_event_qr_type.sql` — documentation-only no-op migration
- `.planning/phases/02-qr-generation-core/02-01-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 02-01 checkbox marked)

**Last session:** 2026-05-01 — Plan 02-01 (QR domain layer: event type + pagination) executed on `feature/adds`. Tasks 1+2 autonomous. Commits `1d34017` (QRType.event + EventData + i18n + switch exhaustiveness fixes across 3 presentation files) + `057ce60` (getUserQRCodesPaginated + FeatureType.qrTypeEvent + SQL migration). flutter analyze 0 issues.

**Files from prior sessions:**

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
