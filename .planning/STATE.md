# State: QRaft v1.0

**Last updated:** 2026-05-01 (post plan 01-01)

## Project Reference

**Core value**: Cerrar el loop digital→físico con un QR personalizado de calidad — diseñar → personalizar → comprar → recibir grabado, todo en pesos colombianos sin fricción.

**Current focus**: Phase 1 — Foundation Hardening (plan 01-01 complete; advancing to plan 01-02)

**Strategic anchors**:
- Brownfield foundation: Auth, GlassButton, deeplinks, i18n, Supabase, AdMob inicial — preservar y construir encima
- Every engraved QR routes through `qraft.link/{slug}` (RDR-01..06) — non-negotiable architecture
- Solo Colombia v1, COP, Wompi, IVA 19%
- DIAN factura electrónica DEFERRED to v2 with explicit risk acceptance
- Manual fulfillment via operator dashboard (no IoT in v1)

## Current Position

**Milestone:** v1.0
**Phase:** 1 of 12 — Foundation Hardening
**Plan:** 1/8 complete — next: 01-02 Maestro foundation scaffolding
**Status:** Plan 01-01 (Flutter SDK + scanner bump) complete; Phase 1 in progress
**Last session:** 2026-05-01 — Plan 01-01 executed sequentially (2 tasks, 1 deviation: pub-syntax fix for SDK constraint), commits `55b4710` + `3ca9881`. Analyzer baseline = 0 issues.

**Progress:** [▱▱▱▱▱▱▱▱▱▱▱▱] 0/12 phases complete (0%) — Phase 1: 1/8 plans complete (12.5%)

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

**Files written this session (plan 01-01 execution):**
- `pubspec.yaml` — SDK constraint corrected (`sdk: ^3.7.0` + `flutter: '>=3.29.0'`); `mobile_scanner: ^7.2.0`
- `pubspec.lock` — `mobile_scanner` 7.1.4 → 7.2.0
- `.planning/phases/01-foundation-hardening/01-01-flutter-sdk-and-scanner-bump-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (plan 01-01 checkbox marked)

**Files from prior sessions:**
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/v2-vision.md`, `.planning/config.json`
- `.planning/research/{SUMMARY,STACK,ARCHITECTURE,PITFALLS}.md`
- `.planning/codebase/{STACK,ARCHITECTURE,CONCERNS}.md`
- `.planning/ROADMAP.md` (created by gsd-roadmapper, this session updates progress only)
- `.planning/phases/01-foundation-hardening/{01-CONTEXT,01-PATTERNS,01-01-...-PLAN}.md`

**Next command:** `/gsd-execute-phase 1` continuation — next plan is **01-02 Maestro foundation scaffolding**.

**Recommended next plans (Phase 1 wave order):**
- `01-02-maestro-foundation-scaffolding-PLAN.md` (next, can run in parallel with 01-03 if desired)
- `01-03-firebase-minimum-wiring-PLAN.md` (depends on 01-01 stable pub baseline ✓)
- `01-04-milestone-packages-install-PLAN.md` (depends on 01-01 + 01-03)

---
*State initialized: 2026-05-01 by gsd-roadmapper*
*Last updated: 2026-05-01 by plan 01-01 executor*
