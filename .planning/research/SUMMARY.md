# Project Research Summary

**Project:** QRaft
**Domain:** Flutter QR generation/scanning + Colombian single-seller e-commerce marketplace (laser-engraved physical products, XTool F1 Ultra, Wompi payments) + digital-only QR features (animated, AI-stylized, home widgets) + redirect-service foundation for v2 dynamic QRs
**Researched:** 2026-05-01
**Confidence:** HIGH

---

## Executive Summary

QRaft is a mobile-first (iOS + Android) Flutter app that closes the digital-to-physical loop: a user designs a personalized QR code, adds it to a cart, and receives a laser-engraved product (wood, acrylic, metal, leather, glass, or stone) delivered within Colombia. No major QR-generation competitor closes this loop — ME-QR and Uniqode are SaaS-only tools. The uniqueness of this positioning makes the end-to-end flow (create → customize → buy → receive) the non-negotiable core value, and every architectural decision must protect its integrity.

The recommended approach is a layered build: QR generation and customization (the input) must be complete before the marketplace preview (which composites the user's actual QR onto material textures) can be meaningful. Payments flow through Wompi via a WebView checkout backed by a Supabase Edge Function for signature-verified webhook handling — this keeps the app at PCI SAQ-A scope. Order state is server-authoritative (PostgreSQL FSM with transition validation), driven by an operator dashboard that manages the manual XTool F1 Ultra fulfillment workflow. The whole state-change pipeline surfaces to the user via Supabase Realtime subscriptions and FCM push notifications.

A strategic v1.0 decision: **every engraved QR points to `qraft.link/{slug}` rather than directly to the user's URL**, with free destination editing in v1.0 — this builds the foundation for v2.0 dynamic QR subscription monetization without locking out the v1 customer base. See `.planning/v2-vision.md`.

The two categories of risk that must be addressed before the first paid transaction are: (1) QR scannability — logos, colors, and custom eye-styles must be validated against ISO/IEC 18004 requirements, especially since post-engraving conditions reduce contrast further than on-screen; and (2) Colombian regulatory compliance — DIAN factura electrónica is legally mandatory from day one, Ley 1480 Art. 47 personalization-exemption language must appear at checkout, and Ley 1581 habeas data consent flows must be built before GA. Both are blockers for launch, not polish-phase items.

---

## Key Findings

### Recommended Stack

The baseline (Flutter 3.6.2+, Riverpod 2.4.9, Firebase Auth, Supabase 2.0.0, AdMob, RevenueCat, go_router 13.0.0, webview_flutter 4.13.1) is locked. The milestone adds a focused set of packages without introducing competing vendors.

**Core technology additions:**

| Technology | Version | Purpose | Rationale |
|------------|---------|---------|-----------|
| `pretty_qr_code` | ^3.6.0 | Advanced QR visual customization (gradients, eye styles, logo embed) | Actively maintained (Feb 2026), MIT, native gradient/shape/finder-pattern API. `qr_flutter` cannot meet QR-03/QR-04 without a fork; `custom_qr_generator` (0.1.2) is abandoned. Keep `qr_flutter` as a fast-path fallback for thumbnails. |
| `mobile_scanner` | ^7.2.0 (bump from 7.0.0) | QR/barcode camera scanning | 7.0.0 already migrated iOS from MLKit to Apple Vision API — unblocking SCAN-01. 7.2.0 adds tap-to-focus. Requires Flutter 3.29+: confirm SDK version before upgrade. |
| `screenshot` + `image` | ^3.0.0 / ^4.x | Rasterize QR widget to PNG (share, export, engraver-quality at 2160px) | `RepaintBoundary` approach; `image` package enforces white halo and logo resize in pure Dart. |
| `csv` | ^8.0.0 | CSV bulk QR generation (QR-07) | Stream-based, Excel-ES semicolon-compatible for Colombian users. |
| Wompi REST + `webview_flutter` | v1 / 4.13.1 (existing) | Payment checkout (cards, PSE, Nequi, Daviplata) | No viable Flutter Wompi SDK exists (community package 21 months stale, missing payment methods). Build thin REST client. Integrity hash + events secret computed exclusively in Edge Function — never in client. WebView checkout keeps app at SAQ-A PCI scope. |
| `firebase_messaging` + `flutter_local_notifications` | ^16.2.0 / ^17.x | FCM push for order status changes | Single-vendor with existing Firebase project (`qraft-e8a1d`). No OneSignal: FCM is unlimited/free and couples with existing Analytics breadcrumbs in Crashlytics. |
| `firebase_crashlytics` + `firebase_analytics` | ^5.2.0 / ^12.3.0 | Crash reporting + funnel analytics | Required pair — Crashlytics issue cards include Analytics breadcrumbs (last 50 events) when both installed. Covers OPT-03. |
| `flutter_form_builder` + `form_builder_validators` | ^10.3.0 / ^11.x | Checkout form with Colombian departamento/municipio conditional validation | Active (Feb 2026). No off-the-shelf DANE validator exists; ship `assets/data/colombia_dane.json` (~50 KB) for offline address validation. |
| `home_widget` + native iOS WidgetKit/Android Glance | ^0.7.x | Home screen widgets (QRD-03) | Flutter package wraps native widget APIs but iOS WidgetKit (Swift) and Android Glance (Kotlin) UI must be built per platform |
| Lottie / GIF export libs (TBD phase research) | TBD | Animated QR export (QRD-01) | Phase-time research — `lottie` for vector animation, `flutter_gif` or canvas record for raster |
| AI styling provider (Replicate / Stability) | API | AI-stylized QRs (QRD-02 — digital only) | Recurring per-call cost; mandatory scannability validation gate before user save |
| DIAN factura electrónica provider | Alegra / Siigo / Dataico | Legally mandatory e-invoicing for B2C sales in Colombia | Do NOT build UBL 2.1 + CUFE + digital signature in-house. API-trigger on Wompi APPROVED webhook. ~$100–300k COP/month at low volume. |
| Redirect service infra | Supabase Edge Function or Cloudflare Worker | RDR-01..06 — `qraft.link/{slug}` redirect | Short URL service backing every engraved QR. Tabla `redirects` (slug, destination, owner_id, scan_count). Foundation for v2 dynamic QRs |

**Pre-integration checklist (must verify before Phase C/D builds):**
- Flutter SDK must be >= 3.29 for `mobile_scanner` 7.x
- `firebase_core` version must align across auth + messaging + crashlytics — run `flutter pub upgrade --dry-run` before adding any Firebase package
- `pretty_qr_code` + `qr_flutter` both depend on `qr` — verify `pubspec.lock` resolves without pin conflict

---

### Expected Features

**Must have — table stakes for v1.0 launch:**

- QR types: URL, text, vCard, WiFi, eventos, ubicación (QR-01)
- Logo embed with EC-H + white halo, ≤20% logo cap (QR-02)
- Color + gradient customization (QR-03)
- Module + eye styles from curated, scanner-validated presets (QR-04)
- CTA frames with 4-module quiet zone enforced (QR-05)
- 8–12 curated templates gallery (QR-06)
- Bulk CSV import (QR-07)
- QR library: save, edit, duplicate (QR-08)
- Share / export QR (QR-09)
- UI toggle "print-safe vs digital-only" with tattoo-safe as third option (QR-10 + TAT-02)
- Animated QRs digital export (QRD-01)
- AI-stylized QRs digital with mandatory scannability validation (QRD-02)
- Home screen widgets iOS+Android (QRD-03)
- Full-screen scanner with auto-detect (SCAN-02)
- Scan history persistent (SCAN-03)
- Type-aware scan actions (SCAN-04)
- Product catalog with material × size filter (MKT-01)
- Live composite preview (MKT-02)
- Persistent cart with IVA 19% + shipping (MKT-03)
- Colombian address picker (MKT-04)
- Wompi checkout: tarjeta + PSE + Nequi + Daviplata (MKT-05/06)
- Order list + detail + status timeline (MKT-07/08)
- FCM push notifications (MKT-09)
- Premium subscription tier (MKT-10) — RevenueCat partial integration
- Operator dashboard (MKT-11) — manual fulfillment management
- Customization snapshot pattern (MKT-12) — frozen at order time
- Redirect service foundation: domain, slugs, basic analytics, free destination editing (RDR-01..06)
- Tattoo line minimal: stencil/transfer products, tattoo-safe QR profile, educational content, partner waitlist (TAT-01..04)
- DIAN factura electrónica integration (LGL-01)
- Ley 1480 Art. 47 disclaimer at checkout (LGL-02)
- Ley 1581 habeas data flow (LGL-03)
- Garantía 3 meses workflow (LGL-04)
- PQRS module (LGL-05)

**Should have — competitive differentiators for v1.x:**
- Scan-to-library bridge (scan QR → pre-fill generator with same content)
- Scan-to-order bridge (scan content → marketplace pre-filled)
- URL safety check on scan
- WhatsApp order notifications
- Operator-uploaded engraving-progress photo
- Material sample bundle SKU
- 3D rotatable product preview
- Refer-a-friend discount

**Defer to v2.0+ — see `.planning/v2-vision.md`:**
- Full dynamic QR features: multi-destination, geo/time-based redirect, landing page builder, custom domains, deep analytics
- Subscription monetization for dynamic QRs (free/Pro/Studio/Lifetime tiers)
- Tattoo line full expansion: studios partnership, white-label, lifetime plans
- AR product try-on
- Multi-vendor seller onboarding
- Multi-country / multi-currency
- IoT integration with XTool F1 Ultra (telemetry, automation)

---

### Architecture Approach

The architecture extends the existing Clean Architecture (feature/data/domain/presentation per feature, Riverpod providers) with five new feature modules (`qr_customization`, `qr_digital`, `cart`, `checkout`, `orders`) plus `redirects` foundation, and core services (`payments_service`, `fcm_service`, `redirect_service`). The operator dashboard is a separate Flutter Web build (or Supabase Studio at alpha). Edge Functions handle: payment webhook verification (`wompi-webhook`), FCM dispatch (`send-fcm`), operator alerting (`notify-operator`), and the redirect service itself (`qraft-link-redirect`).

**Key architectural invariants:**
- **Customization snapshot**: `order_items.customization_snapshot` (JSONB) + `order_items.qr_png_url` frozen at checkout. Library edits never propagate to in-flight or completed orders.
- **Server-authoritative FSM**: Order status transitions validated by Postgres trigger. Client is read-only.
- **Idempotent webhook**: `payment_events.event_id PRIMARY KEY` insert-or-fail.
- **Server-side totals**: `compute_order_totals()` Postgres function authoritative.
- **Secrets in Edge Function only**: Wompi `integrity_secret`, `events_secret`, `private_key` never reach the Flutter app.
- **All engraved QRs route through `qraft.link/{slug}`**: foundation for v2 dynamic monetization.
- **Print-safe vs digital-only enforcement**: hard-coded validation per profile (logo cap, EC level, color inversion ban).
- **Tattoo-safe profile**: extra-conservative (15% logo cap, EC-H, larger module size).

---

### Critical Pitfalls

1. **Logo coverage exceeds error correction budget** — Cap logo ≤20% (≤15% for tattoo). Force EC-H. Enforce in domain layer.
2. **Inverted QR (white-on-dark) ships to engraver** — Hard-code dark-on-light at export regardless of in-app theme.
3. **Wompi webhook signature not validated** — Non-negotiable SHA256 X-Event-Checksum. Re-query Wompi GET /transactions/{id} before fulfilling.
4. **Double-charge from non-idempotent payment retries** — Idempotency-Key header + Edge Function intermediation.
5. **DIAN factura missing** — Mandatory day 1; sandbox tested before production.
6. **Ley 1480 Art. 47 disclaimer absent** — Must appear at checkout, Colombian lawyer review.
7. **Ley 1581 non-compliance** — Privacy policy in Spanish, in-app data export/deletion, AdMob UMP consent.
8. **AI-stylized QR fails post-engraving** — Block AI styles from print-safe profile; mandatory scan validation in digital flow.
9. **Redirect service downtime** — SLA monitoring critical. Tattoos depend on uptime forever.

---

## Implications for Roadmap

### Suggested phase structure (12 phases, 4-6 month window)

The original 11-phase recommendation expands to 12 to accommodate the digital-only QR features and redirect-service foundation:

1. **Phase 1: QR Generation Core (A)** — Foundation. QR-01, QR-08, QR-09. Parallel-eligible.
2. **Phase 2: QR Scanner (B)** — Independent. SCAN-01 (mobile_scanner 7.2.0 bump unblocks iOS), SCAN-02..04. Parallel with Phase 1.
3. **Phase 3: QR Customization Print-Safe (C)** — QR-02..06, QR-10 (toggle), enforce ≤20% logo + EC-H + dark-on-light export. Gates marketplace.
4. **Phase 4: QR Digital-Only Features (C2)** — QRD-01 (animated), QRD-02 (AI), QRD-03 (widgets). Parallel-eligible after Phase 3 toggle infrastructure exists.
5. **Phase 5: Redirect Service (R)** — RDR-01..06. Domain, Edge Function, redirects table, analytics. Independent — can run early in parallel.
6. **Phase 6: Marketplace Catalog + QR Export (D + E)** — MKT-01/02 + engraver-quality PNG pipeline. Two parallel sub-branches.
7. **Phase 7: Cart & Persistence (F)** — MKT-03, customization snapshot. Requires Phase 6.
8. **Phase 8: Checkout, Wompi, Legal Compliance (G)** — MKT-04..06, LGL-01..05, Wompi integration, DIAN, lawyer review. Critical path centerpiece.
9. **Phase 9: Orders + Realtime + FCM (H)** — MKT-07..09, realtime, push notifications.
10. **Phase 10: Operator Dashboard (I)** — MKT-11. Closes physical loop.
11. **Phase 11: Tattoo Line Minimal (T)** — TAT-01..04. Can shift earlier or run parallel with marketplace.
12. **Phase 12: Performance + Visual Polish + Premium (J + K)** — OPT-01..03 + MKT-10 finalization.

### Phases needing deeper research before starting

- **Phase 3 (QR Customization)**: scanner compatibility matrix for `pretty_qr_code` eye-style API
- **Phase 4 (Digital QR)**: AI provider selection (Replicate vs Stability vs OpenAI), animated export libs, native widgets implementation specifics
- **Phase 6 (Marketplace)**: real photographed product samples per material
- **Phase 8 (Checkout)**: DIAN provider comparison (Alegra vs Siigo vs Dataico), Colombian lawyer engagement
- **Phase 10 (Operator)**: tech decision (Supabase Studio vs Flutter Web)

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions verified on pub.dev 2026-05-01; Wompi API verified; Firebase versions verified |
| Features | HIGH | Competitor coverage + Colombian regulatory sources |
| Architecture | HIGH | Patterns verified against official docs |
| Pitfalls | HIGH (regulatory), MEDIUM (Flutter edge cases) | Government sources for legal; package issues for Flutter |
| Digital QR additions | MEDIUM | Newer scope additions, less competitive baseline |
| v1→v2 redirect strategy | HIGH | Verified against industry monetization patterns (QR TIGER/Uniqode/ME-QR) |

**Overall confidence:** HIGH

### Gaps to Address

- Flutter SDK version (>=3.29) confirmation before Phase 2
- Firebase Core alignment check
- DIAN provider API evaluation
- Colombian lawyer engagement scheduled
- Material sample photography before Phase 6
- Domain registration for `qraft.link` (or alternative)
- AI stylization provider selection + scannability validation strategy
- Tattoo-safe QR validation requires empirical testing on skin samples

---

## Sources

### Primary (HIGH)
- docs.wompi.co — REST API, Web Checkout, webhook signature, sandbox
- DIAN.gov.co + Dataico.com — factura electrónica mandatory requirements
- Función Pública Colombia — Ley 1480 Art. 47, Ley 1581
- pub.dev — pretty_qr_code 3.6.0, mobile_scanner 7.2.0, firebase_messaging 16.2.0, firebase_crashlytics 5.2.0, flutter_form_builder 10.3.0, home_widget
- ISO/IEC 18004 (via QRLynx, SmartyTags) — quiet zone, EC, finder pattern
- Supabase docs — Edge Functions, Realtime, Storage
- Firebase docs — FCM HTTP v1, Crashlytics + Analytics pairing

### Secondary (MEDIUM)
- QR TIGER, Uniqode, ME-QR, QRCodeMonkey — competitive landscape + monetization patterns
- Etsy, Zazzle, Crystal Clear Memories — custom physical product UX
- Mercado Libre Colombia, Tiendanube — Colombian e-commerce expectations
- Code with Andrea — Flutter Clean Architecture + Riverpod 2.0

---
*Research completed: 2026-05-01*
*Ready for roadmap: yes*
