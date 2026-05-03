# Roadmap: QRaft v1.0

**Created:** 2026-05-01
**Granularity:** standard (12 phases — scope-amplified per research SUMMARY.md)
**Parallelization:** enabled
**Coverage:** 46/46 v1 requirements mapped (100%)
**Mode:** yolo
**Timeline target:** 4-6 months (feature-complete priority over ASAP)

## Core Value

Cerrar el loop digital→físico con un QR personalizado de calidad: que el usuario pueda diseñar un QR único y recibirlo grabado en su material favorito, sin fricción, pagado en pesos colombianos.

## Strategic Anchors

1. **Brownfield**: Auth, splash, GlassButton, deeplinks iOS/Android, i18n, Supabase, AdMob inicial, test infra base — already validated, build on top.
2. **All engraved QRs route through `qraft.link/{slug}`** — non-negotiable architectural decision (RDR-01..06). Every v1 customer becomes a v2 dynamic-QR lead without lock-out.
3. **DIAN factura electrónica DEFERRED to v2** with explicit risk acceptance (≤950 UVT). NOT in v1 phases.
4. **Solo Colombia**, COP, IVA 19%, Wompi (Bancolombia).
5. **Manual fulfillment** — XTool F1 Ultra operated by human via dashboard (MKT-11). No IoT in v1.

## Phases

- [x] **Phase 1: Foundation Hardening** — Resolve brownfield concerns (mobile_scanner iOS, ForgotPasswordDialog tests, AdMob UMP consent), align Flutter SDK ≥3.29, install milestone packages ✓ 2026-05-01 (passed-with-residuals: all 5 success criteria verified; R-01 logout hang deferred)
- [x] **Phase 2: QR Generation Core** — Users can generate QR codes for all 6 data types and save/share them from a personal library ✓ 2026-05-02
- [ ] **Phase 3: QR Scanner** — Users can scan QRs full-screen with type-aware actions and persistent history (parallel to Phase 2)
- [x] **Phase 4: Redirect Service Foundation** — `qraft.link/{slug}` infrastructure live, foundation for v2 dynamic monetization (parallel to Phases 2-3) ✓ 2026-05-01
- [x] **Phase 5: QR Customization (Print-Safe)** — Users can personalize QRs with logos/colors/styles/frames/templates and select print/digital/tattoo profile ✓ 2026-05-03
- [ ] **Phase 6: QR Digital-Only Features** — Users can create animated, AI-stylized, and home-screen-widget QRs (digital-only flow)
- [ ] **Phase 7: Marketplace Catalog + QR Export Pipeline** — Users can browse engraved-product catalog and see live preview of their customized QR on each material
- [ ] **Phase 8: Cart & Customization Snapshot** — Users can build a persistent cart with frozen customization snapshots and accurate totals (subtotal + IVA 19% + envío)
- [ ] **Phase 9: Checkout, Wompi, Colombian Compliance** — Users can pay via Wompi (cards, PSE, Nequi, Daviplata) with verified webhooks; LGL-02..05 disclaimers and habeas data live
- [ ] **Phase 10: Orders, Realtime & FCM Notifications** — Users can track order status with timeline, receive push notifications on every state change
- [ ] **Phase 11: Operator Dashboard + Tattoo Line** — Operator can fulfill orders end-to-end; Tattoo category live in marketplace with TAT-safe profile
- [ ] **Phase 12: Premium Subscription, Polish & Observability (GA)** — RevenueCat premium, performance polish, Crashlytics + Analytics + Performance, ready for launch

## Phase Details

### Phase 1: Foundation Hardening
**Goal**: Eliminate known brownfield blockers and align baseline so subsequent phases build on solid ground
**Depends on**: Nothing (first phase)
**Requirements**: SCAN-01 (resolve `mobile_scanner` iOS block via 7.2.0 bump)
**Success Criteria** (what must be TRUE):
  1. `flutter run` on iOS real device builds and launches `mobile_scanner` 7.2.0 without dependency errors
  2. Flutter SDK is verified ≥3.29 and `firebase_core` upgrade path tested via `flutter pub upgrade --dry-run`
  3. ForgotPasswordDialog test suite is fully green (5 previously-failing tests resolved)
  4. AdMob UMP consent SDK is integrated and consent form shows on first launch before any ad request (modern path: `ConsentInformation`/`ConsentForm` from `google_mobile_ads ^5.1.0` — no separate UMP package; verified via Google AdMob Flutter privacy docs 2026-05-01)
  5. Milestone packages installed cleanly: `pretty_qr_code`, `screenshot`, `csv`, `image`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`, `flutter_form_builder`, `form_builder_validators`, `flutter_local_notifications`
**Plans**: 8 plans (8/8 complete) ✓ 2026-05-01
- [x] 01-01-flutter-sdk-and-scanner-bump-PLAN.md — bump Flutter SDK ^3.29 + mobile_scanner ^7.2.0; verify pub upgrade dry-run clean ✓ 2026-05-01 (commits `55b4710` + `3ca9881`; pubspec.yaml uses `sdk: ^3.7.0` + `flutter: '>=3.29.0'` per pub-canonical syntax)
- [x] 01-02-maestro-foundation-scaffolding-PLAN.md — establish .maestro/ root + config + conventions + helper scaffolds ✓ 2026-05-01 (commits `9b1cc5d` + `8849773`; 5 files created: config.yaml, CONVENTIONS.md, .tool-versions, helpers/dismiss-permissions.yaml, helpers/login.yaml; both helpers pass `maestro check-syntax`)
- [x] 01-03-firebase-minimum-wiring-PLAN.md — reintroduce firebase_core for project qraft-e8a1d (config + Firebase.initializeApp; no service activation) ✓ 2026-05-01 (commits `5da00cc` + `bff89cb` + `82b09ba` + `4d0e9d8` + `e46e506`; firebase_core 4.7.0 wired end-to-end; iOS deployment target bumped 13.0 → 15.0 — Rule 3 deviation; D-01 boundary preserved, zero FCM/Crashlytics/Analytics imports)
- [x] 01-04-milestone-packages-install-PLAN.md — install 10 milestone packages without wiring (no separate UMP install — `ConsentInformation`/`ConsentForm` ship inside `google_mobile_ads ^5.1.0` which is already in pubspec) ✓ 2026-05-01 (commit `1990bb6`; firebase_messaging 16.2.0 + firebase_crashlytics 5.2.0 + firebase_analytics 12.3.0 + pretty_qr_code 3.6.0 + screenshot 3.0.0 + image 4.5.4 + csv 8.0.0 + flutter_form_builder 10.3.0+2 + form_builder_validators 11.3.0 + flutter_local_notifications 17.2.4; firebase_core stays at 4.7.0; Android core library desugaring enabled — Rule 3 deviation; D-01 boundary preserved, zero new imports in lib/; both platform debug builds pass)
- [x] 01-05-ump-consent-and-admob-gating-PLAN.md — UMP service + consent screen + UmpGate; refactor main.dart so AdMob init waits for UMP; banner reads npa flag ✓ 2026-05-01 (commits `cd834ff` + `b7ad68a` + `8518f79`; new `lib/features/consent/` module with 5-state ConsentState enum + UmpService singleton wrapping `ConsentInformation`/`ConsentForm` from google_mobile_ads ^5.1.0 — no separate UMP install — + 5 Riverpod providers + UmpConsentScreen with Maestro Keys `ump_consent_screen_root` + `ump_continue_button` + UmpGate ConsumerWidget. main.dart bootstrap reordered per D-04: AdMob init removed from `initializeApp()` and now triggered exclusively via `ref.listen<bool>(umpConsentReadyProvider)` in `_QRaftAppState.build`; AuthWrapper wrapped in UmpGate. AdMobService 4 ad-loading methods now thread `nonPersonalizedAds = false` through AdRequest (D-06); 0 `const AdRequest()` remaining, 4 `AdRequest(nonPersonalizedAds:` sites. BannerAdWidget gates load on `umpConsentReadyProvider` + ref.listen re-triggers `_loadAd` when consent flips post-construction; RewardedAdButton + 2 internal `ad_providers` callers all forward `!consentGranted`. Closes ROADMAP success criterion #4. flutter analyze 0 issues; flutter build apk + ios debug both pass; whole-suite test delta unchanged from plan 06 (`+83 ~1 -91`).
- [x] 01-06-forgot-password-controller-refactor-PLAN.md — extract ForgotPasswordController + add Maestro Keys to dialog/login/welcome/scaffold/scanner; reconcile CLAUDE.md/CONCERNS.md test count ✓ 2026-05-01 (commits `47339ee` + `fda41b7` + `217db0c`; ForgotPasswordController extracted as `StateNotifier<ForgotPasswordState>` mirroring `qr_customization_controller.dart` precedent per D-09; SupabaseClient constructor-injected for testability per D-08; provider is `StateNotifierProvider.autoDispose` so dialog re-entry auto-resets state. Dialog refactored: `_emailSent` boolean removed, reads `ref.watch(forgotPasswordControllerProvider)`, submits via `.notifier.submit(email)`. 20 stable Maestro Keys added across 5 lib files following `.maestro/CONVENTIONS.md` selector convention. Test count reconciled (D-10): empirically 6 tests / 0 failing pre-refactor (not 5/13). 4 stale `auth_controller(_simple_test).dart` references scrubbed from CLAUDE.md and replaced with `supabase_auth_provider_test.dart`. 6/6 dialog tests now fail by design — contract change from refactor; plan 07 task 1 rewrites the suite. Whole-suite delta: pre `+89 ~1 -85` → post `+83 ~1 -91` (exactly +6 dialog failures, no collateral damage). flutter analyze 0 issues; flutter build apk + ios debug both succeed)
- [x] 01-07-maestro-flows-and-controller-tests-PLAN.md — write controller + dialog tests; author 9 phase-1 Maestro flows; run on iOS sim + Android emulator ✓ 2026-05-01 (commits `bd39494` 14 Flutter tests / `7eeae6d` 9 flow YAMLs / `627859d` Semantics rollout / `41908d0` removed legacy SupabaseForgotPasswordDialog dead code / `cb1663c` Semantics on dashboard+profile widgets / `3cf599d` Maestro YAML iterations / `b52d28f` popUntil + 30s timeout / `3c29309` CONVENTIONS.md Phase 1 status. Android Medium_Phone suite: 8/9 PASS (logout RESIDUAL — signOut() hangs on real product bug, deferred to Phase 1.X). iOS iPhone 17 Pro: 4/7 pre-Semantics; full re-run pending after fixes. Real product fixes uncovered by E2E: Navigator.popUntil(isFirst) after signOut; legacy 215-line SupabaseForgotPasswordDialog removed from main.dart. flutter analyze 0 issues; whole-suite test delta `+83 ~1 -91` → `+97 ~1 -85` (6 broken-by-design dialog tests now sane + 8 new controller tests).
- [x] 01-08-phase-verification-PLAN.md — run D-11 closure suite; produce 01-VERIFICATION.md; advance STATE.md + ROADMAP.md to Phase 2 ✓ 2026-05-01 (passed-with-residuals; all D-11 gates green; 01-VERIFICATION.md produced)

**UI hint**: yes
**Research needed before planning**: NO (research SUMMARY.md already covered scope; verify SDK version is operational task)
**Parallel-eligible**: NO (must complete first — unblocks scanner + observability)

### Phase 2: QR Generation Core
**Goal**: Users can generate QR codes for all 6 data types, save them to a personal library, and share/export
**Depends on**: Phase 1 (clean build environment)
**Requirements**: QR-01, QR-08, QR-09
**Success Criteria** (what must be TRUE):
  1. User can create QRs for URL, text, vCard, WiFi, eventos, and ubicación from dedicated forms
  2. User can save a generated QR to their library and see it appear in a paginated list
  3. User can edit and duplicate any QR in their library
  4. User can share a QR via system share sheet (link or PNG image)
  5. Library list scrolls smoothly with 100+ items (pagination, ListView.builder, lazy thumbnails)
**Plans**: 4 (4/4 complete) ✓ 2026-05-02
**UI hint**: yes
**Research needed before planning**: NO
**Parallel-eligible**: YES (with Phase 3, Phase 4)
- [x] 02-01-qr-domain-layer-PLAN.md — QRType.event + EventData iCal model + getUserQRCodesPaginated repository + Supabase migration ✓ 2026-05-01 (commits `1d34017` + `057ce60`; 7 enum cases; VCALENDAR/VEVENT iCal; Supabase .range() pagination; 0 analyzer issues)
- [x] 02-02-qr-preview-widget-pretty-qr-PLAN.md — QRPreviewWidget rewritten with PrettyQrView + RepaintBoundary; repaintKey GlobalKey wired to all 6 QR screens ✓ 2026-05-02 (commits `dc3b7c2` + `b3dafe9`; Colors.white hardcoded T-02-04; _TypeBadge extracted; 0 analyzer issues)
- [x] 02-03-event-qr-screen-PLAN.md — EventQRScreen (6th QR type, completes QR-01) + EventFormController + EventForm + generator wiring + vevent filter chip + filterEvent i18n ✓ 2026-05-02 (commits `9b244f9` + `51cae1c`; description maxLength 500 T-02-07; EventQRScreen in _getEditScreenForQRType; coming_soon stub replaced; 0 analyzer issues)
- [x] 02-04-qr-share-and-export-PLAN.md — QrShareButton (RepaintBoundary→PNG→share_plus) wired to all 6 QR screens + library QrPainter offscreen PNG export; shareQR/exportQRPng i18n ✓ 2026-05-02 (commits `8bba9fa` + `a0e4da1`; Semantics identifier qr_share_button; 0 analyzer issues; APK build success; QR-09 complete)

### Phase 3: QR Scanner
**Goal**: Users can scan QRs with full-screen Carden Pro UI and have the app act on results based on QR type
**Depends on**: Phase 1 (mobile_scanner iOS block resolved)
**Requirements**: SCAN-02, SCAN-03, SCAN-04
**Success Criteria** (what must be TRUE):
  1. User opens scanner tab and sees full-screen camera with neon green Carden Pro overlay frame
  2. Scanner auto-detects QR codes and offers tap-to-focus; works on iOS 13+ and Android API 21+
  3. Every successful scan persists to `scan_history` table and appears in scan history view
  4. URL scan offers "Open" action; vCard offers "Save contact"; WiFi offers "Connect"; email/phone trigger native actions
  5. Camera permission denial shows a recovery UI with rationale and "Open Settings" deep link
**Plans**: 3 plans
Plans:
- [x] 03-01-PLAN.md — tapToFocus + lifecycle observer + permission recovery widget + Maestro keys ✓ 2026-05-02 (commits `e1f39c4` + `59408a7`; tapToFocus, lifecycle observer, permission recovery UI, Maestro keys; 0 analyzer issues)
- [x] 03-02-PLAN.md — real gallery scan (analyzeImage) + vCard flutter_contacts + WiFi credential sheet ✓ 2026-05-02 (commits `c6c1319` + `aa481bb`; _processGalleryMockResult deleted, noQRFoundInImage error, stop/start camera wrapping analyzeImage; vCard FlutterContacts.requestPermission + insertContact; WiFi _WifiCredentialsSheet with SSID/password/copy/settings; 0 analyzer issues)
- [ ] 03-03-PLAN.md — Maestro flow update + phase verification
**UI hint**: yes
**Research needed before planning**: NO (research complete — 03-RESEARCH.md)
**Parallel-eligible**: YES (with Phase 2, Phase 4)

### Phase 4: Redirect Service Foundation
**Goal**: `qraft.link/{slug}` infrastructure operational so Phase 7+ marketplace can ship orders that route through it; foundation for v2 dynamic-QR monetization
**Depends on**: Phase 1 (Supabase Edge Functions baseline confirmed)
**Requirements**: RDR-01, RDR-02, RDR-03, RDR-04, RDR-05, RDR-06
**Success Criteria** (what must be TRUE):
  1. Domain `qraft.link` (or chosen alternative) is registered with DNS pointing to redirect service
  2. Hitting `qraft.link/{slug}` issues a 301/302 to the slug's destination_url within target latency
  3. Each redirect record stores slug, destination_url, owner_id, scan_count, last_scanned_at, last_country in `redirects` table with RLS
  4. Authenticated user can edit destination_url of QRs they own from inside the app and the change takes effect immediately (free in v1)
  5. SLA monitoring is configured (uptime check + alerts) and demonstrable downtime alert fires in <5 min during a controlled test
**Plans**: 3 plans (3/3 complete) ✓ 2026-05-01
**Research needed before planning**: NO (Edge Function vs Cloudflare Worker decision can be made during plan)
**Parallel-eligible**: YES (with Phase 2, Phase 3) — must complete before Phase 11 ships first marketplace order
- [x] 04-01-redirects-table-and-rls-PLAN.md — `redirects` table DDL + RLS + Dart domain/data layer (entity, repo interface, slug generator, Supabase datasource, Riverpod providers) ✓ 2026-05-02 (commit `8122624`; 7 files; 0 analyzer issues; migration needs manual Supabase Dashboard application)
- [x] 04-02-edge-function-redirect-PLAN.md — Supabase Edge Function for slug resolution + atomic scan_count RPC ✓ 2026-05-02
- [x] 04-03-flutter-destination-editing-PLAN.md — in-app UI for editing destination_url of owned redirects ✓ 2026-05-01 (commit `6f3a055`; RedirectEditScreen + QR library popup menu + i18n; 0 analyzer issues)

### Phase 5: QR Customization (Print-Safe + Toggle Infrastructure)
**Goal**: Users can personalize QRs with logos, colors, gradients, eye/module styles, frames, and curated templates; explicit print-safe / digital-only / tattoo-safe profile toggle gates validations
**Depends on**: Phase 2 (QR generation core)
**Requirements**: QR-02, QR-03, QR-04, QR-05, QR-06, QR-10, QR-07
**Success Criteria** (what must be TRUE):
  1. User can embed a centered logo with white halo; system enforces error correction H and rejects logo coverage >20% (>15% on tattoo profile)
  2. User can apply solid colors, linear gradients, and radial gradients from pre-defined palettes; export forces dark-on-light regardless of in-app theme
  3. User can choose module shapes and "eye" styles ONLY from the curated, scanner-matrix-validated gallery (8+ presets per category)
  4. User can add a CTA frame ("Scan me", "Visit", custom text) with system-enforced 4-module quiet zone
  5. User can browse 8-12 curated templates and apply one to a QR with a single tap
  6. User selects "Print-safe / Digital-only / Tattoo-safe" profile in the editor and validations differ correctly per profile
  7. User can bulk-import a CSV (`;`-delimited for Excel-ES) and generate N QRs at once with a default template applied
**Plans**: 5 plans (5/5 complete) ✓ 2026-05-03
Plans:
- [x] 05-01-PLAN.md — QrProfile enum + QrProfileValidator + 9 new QRCustomization fields + controller methods + QrProfileToggle widget (Wave 1) ✓ 2026-05-01 (commits `c2f992b` + `19bdca9` + `d61a72f` + `f34f456`; QrProfile+GradientType+QrProfileConstraints extension; QrProfileValidator 8 unit tests; QRCustomization 9 new fields backward-compat; controller 6 new methods; QrProfileToggle SegmentedButton; 0 analyzer issues)
- [x] 05-02-PLAN.md — QrDecorationBuilder factory + logo embed + EC-H enforcement + QrLogoPickerWidget + QRPreviewWidget upgrade (Wave 2) ✓ 2026-05-02 (commits `5254012` RED + `36c7873` GREEN + `37b0327` widget; QrDecorationBuilder static service buildDecoration+buildQrImage; logo coverage clamped to profile.maxLogoScale; EC-H forced when hasLogo; PrettyQrQuietZone.standard; QrLogoPickerWidget PNG/JPG whitelist + 2MB gate; QRPreviewWidget ConsumerStatefulWidget QrImage in initState; 11 tests pass; 0 analyzer issues; APK debug build success)
- [x] 05-03-PLAN.md — Gradient brush (linear/radial) + QrExportService print-safe PNG + QrColorPickerWidget 8 presets (Wave 2, parallel to 05-02) ✓ 2026-05-02 (commits `ae4e1a5` RED + `23cebed` GREEN + `14ccacc` widget; buildBrush returns Color/PrettyQrBrush.gradient; QrExportService.exportPrintSafe 2160px toImageAsBytes white background forced; QrColorPickerWidget 8 swatches + hex validation; 15 tests pass; 0 analyzer issues)
- [x] 05-04-PLAN.md — buildShape() 8 module + 8 eye presets + PrettyQrShape.custom + QrPresetGalleryWidget + QrFrameWidget (Wave 3) ✓ 2026-05-02 (commits `29ebda1` RED + `2ae992c` GREEN + `9492b35` widgets; buildShape PrettyQrShape.custom try-catch fallback; _moduleSymbol/_eyeSymbol switch factories; QrPresetGalleryWidget 2 scrollable rows; QrFrameWidget CTA frame quiet zone invariant; 19+3 tests pass; 0 analyzer issues)
- [x] 05-05-PLAN.md — 8 curated QrFullTemplate objects + applyFullTemplate() + QrTemplateGalleryWidget + QrBulkImportService CSV + QrBulkImportSheet (Wave 3, parallel to 05-04) ✓ 2026-05-03 (commits `64f2deb` RED + `9575e8e` GREEN + `2a41954` templates+gallery+sheet; Csv(fieldDelimiter:';', autoDetect:false) csv 8.0.0 API; 1MB + 500-row caps; kQrTemplates 8 const entries; applyFullTemplate; QrTemplateGalleryWidget 2-col grid profile badges; QrBulkImportSheet CSV paste flow; 7 tests pass; 0 analyzer issues)
**UI hint**: yes
**Research needed before planning**: NO (research complete — 05-RESEARCH.md)
**Parallel-eligible**: NO (gates Phase 6, Phase 7)

### Phase 6: QR Digital-Only Features
**Goal**: Users can create rich digital-only QR experiences (animated, AI-stylized, home-screen widgets) that complement the print-safe marketplace flow without contaminating engraving scannability
**Depends on**: Phase 5 (QR-10 toggle infrastructure exists; digital profile validations defined)
**Requirements**: QRD-01, QRD-02, QRD-03
**Success Criteria** (what must be TRUE):
  1. User can export an animated QR as GIF, MP4, or Lottie and share via system share sheet (digital flow only — never reaches marketplace)
  2. User can stylize a QR with AI (Replicate or Stability provider — selected during phase research); save is BLOCKED until headless scan-validation passes
  3. User can pin a favorite QR from their library to iOS home screen via WidgetKit and Android home screen via Glance, tap-to-open the QR full-screen
  4. AI-stylized QRs are programmatically prevented from being added to cart (print-safe profile blocks AI styles)
**Plans**: 4 plans
Plans:
- [x] 06-01-PLAN.md — exportDigitalOnly() + Replicate Edge Function proxy + test scaffolds (Wave 1) ✓ 2026-05-03 (commits `8c0cda2` scaffolds+exportDigitalOnly + `52c9ce4` ai-stylize Edge Function+QrAnimationService stub; REPLICATE_API_KEY in Deno.env T-06-01; prompt sanitization T-06-02; 5/month gate T-06-03; 3 wave-0 sentinels; 0 analyzer issues)
- [ ] 06-02-PLAN.md — QRD-01 animated GIF: QrAnimationService + QrAnimatePage (Wave 2)
- [ ] 06-03-PLAN.md — QRD-02 AI stylized QR: QrAiStyleService + QrAiStylePage + scannability gate (Wave 2, parallel to 06-02)
- [ ] 06-04-PLAN.md — QRD-03 home widget: home_widget 0.9.1 + Swift WidgetKit + Kotlin Glance + human checkpoint (Wave 3)
**UI hint**: yes
**Research needed before planning**: NO (research complete — 06-RESEARCH.md)
**Parallel-eligible**: YES (can run alongside Phase 7 since it doesn't touch marketplace)

### Phase 7: Marketplace Catalog + QR Export Pipeline
**Goal**: Users can browse the engraved-product catalog (material × size × price) and see a live composite preview of their customized QR rendered on each material; system can rasterize engraver-quality 2160px PNGs
**Depends on**: Phase 5 (customized QR data is the input to material preview + PNG export)
**Requirements**: MKT-01, MKT-02
**Success Criteria** (what must be TRUE):
  1. User can browse products filtered by material (madera, acrílico, metal, cuero, vidrio, piedra) and size with realistic preview thumbnails
  2. User selects a product variant and sees a live composite preview of their selected QR rendered on the chosen material texture
  3. System can rasterize any QR to a 2160px PNG via `RepaintBoundary.toImage(pixelRatio: 12.0)` and upload to Supabase Storage `order-assets/`
  4. Catalog data lives in `products` + `product_variants` + `materials` tables with RLS for read; prices stored in COP whole pesos (INT)
  5. Material preview composition runs at 60fps on Android low-end (lazy material textures, RepaintBoundary isolation)
**Plans**: 4 plans
Plans:
- [ ] 07-01-PLAN.md — Supabase migration (materials + products + product_variants DDL + seed) + domain entities + catalogProvider
- [ ] 07-02-PLAN.md — MaterialFilterBar + ProductVariantCard widgets + replace MarketplaceScreen stub + ProductDetailScreen skeleton
- [ ] 07-03-PLAN.md — MaterialPreviewWidget (Stack: texture + white QR label via PrettyQrView) + widget tests
- [ ] 07-04-PLAN.md — Wire QR library Engrave action → marketplace; inject qrCodeId into ProductDetailScreen; visual verification checkpoint
**UI hint**: yes
**Research needed before planning**: NO (research complete — 07-RESEARCH.md)
**Parallel-eligible**: NO (gates Phase 8)

### Phase 8: Cart & Customization Snapshot
**Goal**: Users can add customized QR + product variant pairs to a persistent cart with frozen customization snapshots; totals are computed server-authoritatively (subtotal + IVA 19% + envío)
**Depends on**: Phase 7 (catalog + PNG export pipeline)
**Requirements**: MKT-03, MKT-12
**Success Criteria** (what must be TRUE):
  1. User can add a (product_variant + qr_code + customization snapshot) trio to cart and see it persist across app restarts
  2. Cart syncs cross-device for signed-in users via Supabase `cart_items`; falls back to Hive for guest sessions; merge UX defined for sign-in
  3. `customization_snapshot` (JSONB) and pre-rasterized 2160px PNG are frozen at add-to-cart; subsequent edits to the QR in library do NOT affect the cart entry
  4. Cart total displays subtotal + IVA 19% + envío clearly broken down; values match server-computed `compute_order_totals()` function (NOT computed client-side as source of truth)
  5. User can update quantity, remove items, and clear cart; all operations are reflected in both local and remote stores
**Plans**: TBD
**UI hint**: yes
**Research needed before planning**: NO
**Parallel-eligible**: NO (gates Phase 9)

### Phase 9: Checkout, Wompi & Colombian Compliance
**Goal**: Users can complete purchase with a Colombian shipping address, pay via Wompi (cards, PSE, Nequi, Daviplata), and the system validates webhooks securely; LGL-02..05 disclaimers and habeas data are live before first paid transaction
**Depends on**: Phase 8 (cart) + Phase 4 (redirect slugs needed at order creation)
**Requirements**: MKT-04, MKT-05, MKT-06, LGL-02, LGL-03, LGL-04, LGL-05
**Success Criteria** (what must be TRUE):
  1. User completes a checkout form with Colombian departamento/municipio dropdowns (DANE dataset) and address; phone validates with +57 default
  2. User taps "Pagar" → opens Wompi Web Checkout in WebView; can pay with card, PSE, Nequi, or Daviplata; sandbox round-trip succeeds
  3. Supabase Edge Function `wompi-webhook` validates SHA256 X-Event-Checksum and inserts into `payment_events` with `event_id` UNIQUE for idempotency; forged events are rejected with 401
  4. Order status transitions only via server-authoritative state machine (Postgres FSM with CHECK constraint); client cannot mutate `orders.status` directly
  5. Idempotency-Key is sent on Wompi transaction creation; double-tap retry on flaky network produces ONE Wompi transaction, not two
  6. Ley 1480 Art. 47 disclaimer ("productos personalizados grabados están exentos del retracto 5 días") is visible at checkout review screen AND in post-purchase confirmation
  7. Privacy policy in Spanish covering Ley 1581 elements is hosted, linked from checkout, signup, and profile; in-app habeas data flow allows user to export/delete their data
  8. PQRS module is accessible from profile; user can submit Petición/Queja/Reclamo/Sugerencia which lands in operator inbox
  9. Garantía 3-month claim flow (Ley 1480) is documented and reachable separately from retracto path
**Plans**: TBD
**UI hint**: yes
**Research needed before planning**: NO (Wompi spec verified in research; Colombian lawyer engagement happens during plan, not before)
**Parallel-eligible**: NO (critical-path centerpiece; gates Phase 10)

### Phase 10: Orders, Realtime & FCM Notifications
**Goal**: Users can view their orders, track status timeline live, and receive push notifications on every state change; Supabase Realtime + FCM HTTP v1 wired end-to-end
**Depends on**: Phase 9 (orders must exist to be tracked)
**Requirements**: MKT-07, MKT-08, MKT-09
**Success Criteria** (what must be TRUE):
  1. User can view a list of their orders sorted by recency; pagination handles 50+ orders without jank
  2. User can tap an order to see detail with itemized line items, total breakdown, and shipping address
  3. Order timeline visually shows: recibido → en producción → grabando → listo → enviado → entregado, with operator-driven transitions
  4. Detail screen subscribes to Supabase Realtime on `orders` filtered by user_id; status changes update in <2s without manual refresh
  5. User receives FCM push on EVERY state transition; tapping notification deep-links to order detail; foreground notifications display via `flutter_local_notifications`
  6. FCM tokens are registered in `user_fcm_tokens` table; per-device token rotation is handled
**Plans**: TBD
**UI hint**: yes
**Research needed before planning**: NO
**Parallel-eligible**: NO (gates Phase 11)

### Phase 11: Operator Dashboard + Tattoo Line
**Goal**: Operator can fulfill orders end-to-end through a dedicated dashboard; tattoo category goes live in marketplace with the tattoo-safe QR profile, educational content, and partner waitlist CTA
**Depends on**: Phase 10 (orders + state machine + notifications) and Phase 5 (QR-10 tattoo-safe profile validations exist)
**Requirements**: MKT-11, TAT-01, TAT-02, TAT-03, TAT-04
**Success Criteria** (what must be TRUE):
  1. Operator can view all orders filtered by status (paid, received_by_ops, engraving, engraving_done, shipped) in a dedicated dashboard (Flutter Web or Supabase Studio — decision finalized during phase research)
  2. Operator can transition an order to the next state via RPC functions only (`transition_order`, `record_shipment`); state machine validates legality of transition; engraving_failed→received_by_ops retry path works
  3. Each transition fires a notification row → FCM dispatch → user sees update within 2s if app open, push if backgrounded
  4. Stale-order alert: orders stuck in same state >SLA threshold surface to top of dashboard with red flag
  5. Marketplace catalog includes "Tattoo Stencil/Transfer" category with at least 1 SKU; product detail enforces tattoo-safe QR profile (15% logo cap, EC-H, larger modules)
  6. App contains educational FAQ screen on tatuar QRs (tamaño mínimo, ubicación corporal, healing, scan-survival)
  7. "Próximamente: Tattoo Studios Partner" CTA is visible in tattoo flow; signups land in `tattoo_studio_waitlist` table for v2 outreach
**Plans**: TBD
**UI hint**: yes
**Research needed before planning**: YES — operator tech decision (Flutter Web build vs Supabase Studio + RPC) per research SUMMARY.md "Phase 8 operator tech"; tattoo-safe QR validation requires empirical testing on skin samples
**Parallel-eligible**: NO (final feature phase before polish)

### Phase 12: Premium Subscription, Polish & Observability (GA)
**Goal**: Monetization tier is active (RevenueCat premium removes ads + unlocks advanced features), Carden Pro polish is complete, observability is production-ready, app is GA
**Depends on**: Phase 11 (full feature surface implemented)
**Requirements**: MKT-10, OPT-01, OPT-02, OPT-03
**Success Criteria** (what must be TRUE):
  1. User can subscribe to a premium tier via RevenueCat (iOS App Store, Android Play Store); premium status removes AdMob banners and unlocks gated features
  2. App achieves 60fps scrolling on Android API 23 reference device; splash-to-interactive is sub-2s; no jank reports during 5-min flow recording
  3. Carden Pro polish complete: haptic feedback on key actions, neon glow animations, shimmer loading on cards, microinteractions on buttons (scale 0.95 + glow), dark mode polish across all screens
  4. Firebase Crashlytics + Analytics + Performance integrated; non-fatal errors are recorded; analytics breadcrumbs surface in crash reports
  5. Payment flow has structured logging in Edge Functions; reconciliation job (compare Wompi balance vs internal `payments.status='approved'` total) runs nightly with alert on drift >0.1%
  6. AdMob UMP consent persists across launches; no ad request fires before consent; ads do NOT appear during checkout, payment, or order detail flows
**Plans**: TBD
**UI hint**: yes
**Research needed before planning**: NO
**Parallel-eligible**: NO (terminal phase)

## Dependency Graph

```
Phase 1: Foundation Hardening
    │
    ├─────────┬──────────────┐
    ▼         ▼              ▼
Phase 2     Phase 3       Phase 4
(QR Gen)   (Scanner)    (Redirect)
    │         │              │
    ▼         │              │
Phase 5       │              │
(Customize)   │              │
    │         │              │
    ├─────────┐              │
    ▼         ▼              │
Phase 6    Phase 7           │
(Digital)  (Catalog)         │
              │              │
              ▼              │
           Phase 8           │
           (Cart)            │
              │              │
              └──────┬───────┘
                     ▼
                  Phase 9
                  (Checkout + Compliance)
                     │
                     ▼
                  Phase 10
                  (Orders + FCM)
                     │
                     ▼
                  Phase 11
                  (Operator + Tattoo)
                     │
                     ▼
                  Phase 12
                  (Premium + Polish + GA)
```

**Parallelization windows:**
- After Phase 1: Phases 2, 3, 4 run in parallel
- After Phase 5: Phases 6, 7 run in parallel (Phase 6 doesn't gate Phase 7)
- All other phases are sequential

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation Hardening | 8/8 | Complete | 2026-05-01 |
| 2. QR Generation Core | 4/4 | Complete | 2026-05-02 |
| 3. QR Scanner | 2/3 | In progress | - |
| 4. Redirect Service Foundation | 3/3 | Complete | 2026-05-01 |
| 5. QR Customization (Print-Safe) | 3/5 | In progress | 2026-05-02 (plans 01-03) |
| 6. QR Digital-Only Features | 0/4 | Planned | - |
| 7. Marketplace Catalog + QR Export | 0/4 | Planned | - |
| 8. Cart & Customization Snapshot | 0/? | Not started | - |
| 9. Checkout, Wompi & Compliance | 0/? | Not started | - |
| 10. Orders, Realtime & FCM | 0/? | Not started | - |
| 11. Operator Dashboard + Tattoo | 0/? | Not started | - |
| 12. Premium, Polish & Observability | 0/? | Not started | - |

## Coverage Validation

**Total v1 requirements:** 46
**Mapped:** 46 ✓
**Unmapped:** 0
**Duplicates:** 0

| Category | Requirements | Phases |
|----------|--------------|--------|
| QR Generation | QR-01..QR-10 (10) | Phases 2, 5 |
| QR Digital-Only | QRD-01..QRD-03 (3) | Phase 6 |
| QR Scanner | SCAN-01..SCAN-04 (4) | Phases 1, 3 |
| Marketplace | MKT-01..MKT-12 (12) | Phases 7, 8, 9, 10, 11, 12 |
| Redirect Service | RDR-01..RDR-06 (6) | Phase 4 |
| Tattoo Line | TAT-01..TAT-04 (4) | Phase 11 |
| Compliance Colombia | LGL-02..LGL-05 (4) | Phase 9 |
| Optimización | OPT-01..OPT-03 (3) | Phase 12 |

## Phases Needing /gsd-research-phase Before Planning

Per research SUMMARY.md flags + dependency analysis:

| Phase | Research needed |
|-------|-----------------|
| Phase 3 | Scanner-matrix CI test setup, full-screen overlay UX confirmation |
| Phase 6 | AI provider selection (Replicate/Stability/OpenAI), animated export libs, native widget impl per platform |
| Phase 7 | Real photographed product samples per material |
| Phase 11 | Operator tech decision (Flutter Web vs Supabase Studio); tattoo-safe QR validation on skin samples |

Phases 1, 2, 4, 5, 8, 9, 10, 12 can proceed directly to `/gsd-plan-phase` without prior `/gsd-research-phase`.

## Out of Scope (NOT in any v1 phase)

Per PROJECT.md and v2-vision.md — explicitly deferred:

- DIAN factura electrónica (DIAN-01..03) — v2.0 with explicit risk acceptance ≤950 UVT
- Dynamic QR full features (DYN-01..05) — v2.0
- Subscription tiers for dynamic redirects (SUB-01..04) — v2.0
- Tattoo line full expansion (TAT2-01..04) — v2.0
- Multi-country / multi-currency — v2.0
- IoT XTool F1 Ultra integration — v2.0+
- AR product try-on — v2.0+
- Multi-vendor seller onboarding — v2.0+
- Desktop builds as primary target — Out of scope (kept functional, not polished)
- B2B wholesale / corporate accounts — Out of scope

## Evolution

Update on phase transitions:
- Mark phase checklist `[x]` on completion
- Update progress table (`Plans Complete`, `Status`, `Completed` date)
- Add new requirements to `Coverage Validation` if scope changes
- Append decisions to `## Key Decisions` in PROJECT.md

---
*Roadmap created: 2026-05-01*
*Last updated: 2026-05-01 — Phase 6 plans created (4 plans, 3 waves)*
