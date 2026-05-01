# State: QRaft v1.0

**Last updated:** 2026-05-01 (post plan 01-03)

## Project Reference

**Core value**: Cerrar el loop digital→físico con un QR personalizado de calidad — diseñar → personalizar → comprar → recibir grabado, todo en pesos colombianos sin fricción.

**Current focus**: Phase 1 — Foundation Hardening (plans 01-01 + 01-02 + 01-03 complete; advancing to plan 01-04)

**Strategic anchors**:
- Brownfield foundation: Auth, GlassButton, deeplinks, i18n, Supabase, AdMob inicial — preservar y construir encima
- Every engraved QR routes through `qraft.link/{slug}` (RDR-01..06) — non-negotiable architecture
- Solo Colombia v1, COP, Wompi, IVA 19%
- DIAN factura electrónica DEFERRED to v2 with explicit risk acceptance
- Manual fulfillment via operator dashboard (no IoT in v1)

## Current Position

**Milestone:** v1.0
**Phase:** 1 of 12 — Foundation Hardening
**Plan:** 3/8 complete — next: 01-04 Milestone packages install
**Status:** Plans 01-01 + 01-02 + 01-03 complete; Phase 1 in progress
**Last session:** 2026-05-01 — Plan 01-03 (Firebase minimum wiring) executed across two segments (5 tasks total: 1 in prior segment + 4 in continuation segment, 1 user-action checkpoint resolved between them). Commits `5da00cc` + `bff89cb` + `82b09ba` + `4d0e9d8` + `e46e506`. firebase_core 4.7.0 wired end-to-end on Android + iOS; `Firebase.initializeApp()` runs between Supabase and AdMob in `lib/main.dart`. Two Rule 3 deviations: bumped iOS deployment target 13.0 → 15.0 (firebase_core 4.7.0 hard requirement), and hand-authored `lib/firebase_options.dart` per orchestrator instruction (skip FlutterFire CLI install). Both `flutter build apk --debug` and `flutter build ios --debug --no-codesign` pass; analyzer baseline preserved at 0 issues. D-01 boundary verified: zero FCM/Crashlytics/Analytics imports in `lib/`.

**Progress:** [▱▱▱▱▱▱▱▱▱▱▱▱] 0/12 phases complete (0%) — Phase 1: 3/8 plans complete (38%)

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
- [ ] Confirm `pubspec.lock` resolves `pretty_qr_code` alongside `qr_flutter` (both depend on `qr` package) — Phase 1 plan 01-04 (qr_flutter@4.1.0 + transitive `qr` 3.0.2 verified clean by plan 01-01)
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

**Files written this session (plan 01-03 execution, continuation segment):**
- `android/app/google-services.json` — Firebase Android config for project `qraft-e8a1d` (vendor-issued; placed by user during checkpoint)
- `ios/Runner/GoogleService-Info.plist` — Firebase iOS config for project `qraft-e8a1d` (vendor-issued; placed by user during checkpoint)
- `android/app/build.gradle.kts` — `id("com.google.gms.google-services")` appended to plugins block
- `android/build.gradle.kts` — added `plugins {}` block declaring `com.google.gms.google-services 4.4.2 apply false`
- `ios/Podfile` — `platform :ios, '13.0'` → `'15.0'` (firebase_core 4.7.0 podspec requirement)
- `ios/Podfile.lock` — auto-regenerated; 25 pods total; 12 Firebase-* entries
- `ios/Runner.xcodeproj/project.pbxproj` — `IPHONEOS_DEPLOYMENT_TARGET 13.0` → `15.0` (3 build configs)
- `lib/firebase_options.dart` — hand-authored, FlutterFire-CLI-equivalent shape; android + ios concrete options
- `lib/main.dart` — added firebase_core + firebase_options imports; `Firebase.initializeApp` block between Supabase and AdMob
- `lib/l10n/app_localizations.dart` — incidental Flutter-tool reformat during build (whitespace only)
- `.planning/phases/01-foundation-hardening/01-03-firebase-minimum-wiring-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 01-03 checkbox marked)

**Files from prior sessions:**
- `pubspec.yaml`, `pubspec.lock` (modified in plan 01-01 + plan 01-03 task 1)
- `.maestro/{config.yaml,.tool-versions,CONVENTIONS.md,helpers/*}` (created in plan 01-02)
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/v2-vision.md`, `.planning/config.json`
- `.planning/research/{SUMMARY,STACK,ARCHITECTURE,PITFALLS}.md`
- `.planning/codebase/{STACK,ARCHITECTURE,CONCERNS}.md`
- `.planning/phases/01-foundation-hardening/{01-CONTEXT,01-PATTERNS,01-01-...-PLAN,01-01-...-SUMMARY,01-02-...-PLAN,01-02-...-SUMMARY,01-03-...-PLAN}.md`

**Next command:** `/gsd-execute-phase 1` continuation — next plan is **01-04 Milestone packages install**.

**Recommended next plans (Phase 1 wave order):**
- `01-04-milestone-packages-install-PLAN.md` (depends on 01-01 + 01-03 ✓; will install firebase_messaging/crashlytics/analytics on top of firebase_core 4.7.0 baseline)
- `01-05-ump-consent-and-admob-gating-PLAN.md` (depends on 01-04; will introduce ump_* widgets following CONVENTIONS.md; will extract AdMob init from `lib/main.dart:43` behind UMP gate)
- `01-06-forgot-password-controller-refactor-PLAN.md` (will add Keys to dialog widgets per CONVENTIONS.md)
- `01-07-maestro-flows-and-controller-tests-PLAN.md` (will tighten login.yaml from text- to id-matchers and author 9 phase-1 flows on top of helpers + conventions)
- `01-08-phase-verification-PLAN.md` (D-11 closure suite; produces 01-VERIFICATION.md)

---
*State initialized: 2026-05-01 by gsd-roadmapper*
*Last updated: 2026-05-01 by plan 01-03 executor*
