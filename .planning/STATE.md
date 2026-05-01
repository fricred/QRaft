# State: QRaft v1.0

**Last updated:** 2026-05-01 (post plan 01-02)

## Project Reference

**Core value**: Cerrar el loop digital→físico con un QR personalizado de calidad — diseñar → personalizar → comprar → recibir grabado, todo en pesos colombianos sin fricción.

**Current focus**: Phase 1 — Foundation Hardening (plans 01-01 + 01-02 complete; advancing to plan 01-03)

**Strategic anchors**:
- Brownfield foundation: Auth, GlassButton, deeplinks, i18n, Supabase, AdMob inicial — preservar y construir encima
- Every engraved QR routes through `qraft.link/{slug}` (RDR-01..06) — non-negotiable architecture
- Solo Colombia v1, COP, Wompi, IVA 19%
- DIAN factura electrónica DEFERRED to v2 with explicit risk acceptance
- Manual fulfillment via operator dashboard (no IoT in v1)

## Current Position

**Milestone:** v1.0
**Phase:** 1 of 12 — Foundation Hardening
**Plan:** 2/8 complete — next: 01-03 Firebase minimum wiring
**Status:** Plans 01-01 + 01-02 complete; Phase 1 in progress
**Last session:** 2026-05-01 — Plan 01-02 (Maestro foundation scaffolding) executed sequentially (2 tasks, 0 deviations), commits `9b1cc5d` + `8849773`. Both helpers pass `maestro check-syntax`. `.maestro/` root with config, conventions, version pin, and 2 helper scaffolds is in place.

**Progress:** [▱▱▱▱▱▱▱▱▱▱▱▱] 0/12 phases complete (0%) — Phase 1: 2/8 plans complete (25%)

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
- [ ] Run `flutter pub upgrade --dry-run` to confirm `firebase_core` upgrade path | Phase 1 plan 01-03
- [ ] Confirm `pubspec.lock` resolves `pretty_qr_code` alongside `qr_flutter` (both depend on `qr` package) — Phase 1 plan 01-04 (qr_flutter@4.1.0 + transitive `qr` 3.0.2 verified clean by plan 01-01)
- [ ] Update `01-PATTERNS.md:498` snippet from `sdk: ^3.29.0` to `sdk: ^3.7.0` + `flutter: '>=3.29.0'` (carried over from plan 01-01 deferred-items)
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

**Files written this session (plan 01-02 execution):**
- `.maestro/config.yaml` — Maestro project config (appId io.gothcorp.qraft)
- `.maestro/.tool-versions` — `maestro 2.4.0` pin (asdf-style)
- `.maestro/CONVENTIONS.md` — selector convention `<feature>_<element>_<role>` + verbatim selector ids for plans 06/07
- `.maestro/helpers/dismiss-permissions.yaml` — system-dialog dismissal helper (executable; `maestro check-syntax` OK)
- `.maestro/helpers/login.yaml` — login scaffold with text matchers + plan-07 upgrade-path comments (`maestro check-syntax` OK)
- `.planning/phases/01-foundation-hardening/01-02-maestro-foundation-scaffolding-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 01-02 checkbox marked)

**Files from prior sessions:**
- `pubspec.yaml`, `pubspec.lock` (modified in plan 01-01)
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/v2-vision.md`, `.planning/config.json`
- `.planning/research/{SUMMARY,STACK,ARCHITECTURE,PITFALLS}.md`
- `.planning/codebase/{STACK,ARCHITECTURE,CONCERNS}.md`
- `.planning/ROADMAP.md` (created by gsd-roadmapper; sessions update progress only)
- `.planning/phases/01-foundation-hardening/{01-CONTEXT,01-PATTERNS,01-01-...-PLAN,01-01-...-SUMMARY,01-02-...-PLAN}.md`

**Next command:** `/gsd-execute-phase 1` continuation — next plan is **01-03 Firebase minimum wiring**.

**Recommended next plans (Phase 1 wave order):**
- `01-03-firebase-minimum-wiring-PLAN.md` (depends on 01-01 stable pub baseline ✓; independent of 01-02)
- `01-04-milestone-packages-install-PLAN.md` (depends on 01-01 + 01-03)
- `01-05-ump-consent-and-admob-gating-PLAN.md` (depends on 01-04; will introduce ump_* widgets following CONVENTIONS.md)
- `01-06-forgot-password-controller-refactor-PLAN.md` (will add Keys to dialog widgets per CONVENTIONS.md)
- `01-07-maestro-flows-and-controller-tests-PLAN.md` (will tighten login.yaml from text- to id-matchers and author 9 phase-1 flows on top of helpers + conventions)

---
*State initialized: 2026-05-01 by gsd-roadmapper*
*Last updated: 2026-05-01 by plan 01-02 executor*
