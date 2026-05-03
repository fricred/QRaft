---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-03T17:58:00Z"
progress:
  total_phases: 12
  completed_phases: 8
  total_plans: 35
  completed_plans: 36
  percent: 98
---

# State: QRaft v1.0

**Last updated:** 2026-05-03 (post plan 10-01 — FCM activated; FcmService + user_fcm_tokens + notifications tables; firebase_messaging wired before runApp)

## Project Reference

**Core value**: Cerrar el loop digital→físico con un QR personalizado de calidad — diseñar → personalizar → comprar → recibir grabado, todo en pesos colombianos sin fricción.

**Current focus**: Phase 10 in progress (1/5 plans done: 10-01 FCM activation + user_fcm_tokens + notifications tables). Phase 9 COMPLETE. Phase 8 COMPLETE. Phase 3 in parallel (2/3 plans done, 03-03 pending).

**Strategic anchors**:

- Brownfield foundation: Auth, GlassButton, deeplinks, i18n, Supabase, AdMob inicial — preservar y construir encima
- Every engraved QR routes through `qraft.link/{slug}` (RDR-01..06) — non-negotiable architecture
- Solo Colombia v1, COP, Wompi, IVA 19%
- DIAN factura electrónica DEFERRED to v2 with explicit risk acceptance
- Manual fulfillment via operator dashboard (no IoT in v1)

## Current Position

**Milestone:** v1.0
**Phase:** 10 of 12 — Orders, Realtime & FCM Notifications (next)
**Plan:** 10-01 ~ 2026-05-03 (COMPLETE: FCM activated; FcmService + user_fcm_tokens + notifications tables; background handler wired in main.dart)
**Status:** Phase 10 IN PROGRESS (1/5 plans); Phase 9 COMPLETE (5/5); Phase 8 COMPLETE; Phase 7 COMPLETE; Phase 6 COMPLETE; Phase 5 COMPLETE; Phase 4 COMPLETE; Phase 3 in progress (2/3 plans)
**Last session:** 2026-05-03T17:58:00Z

**Progress:** [█████████▊] 98%

```
Phase 1:  ▰ Foundation Hardening              ✓ COMPLETE (passed-with-residuals 2026-05-01)
Phase 2:  ▰ QR Generation Core                ✓ COMPLETE 2026-05-02 (4/4 plans)
Phase 3:  ▱ QR Scanner                        IN PROGRESS (2/3 plans — 03-03 pending)
Phase 4:  ▰ Redirect Service Foundation       ✓ COMPLETE 2026-05-01 (3/3 plans)
Phase 5:  ▰ QR Customization (Print-Safe)     ✓ COMPLETE 2026-05-03 (5/5 plans)
Phase 6:  ▰ QR Digital-Only Features          ✓ COMPLETE 2026-05-03 (4/4 plans)
Phase 7:  ▰ Marketplace Catalog + QR Export   ✓ COMPLETE 2026-05-03 (4/4 plans)
Phase 8:  ▰ Cart & Customization Snapshot     ✓ COMPLETE 2026-05-03 (4/4 plans)
Phase 9:  ▰ Checkout, Wompi & Compliance      ✓ COMPLETE 2026-05-03 (5/5 plans)
Phase 10: ▱ Orders, Realtime & FCM          IN PROGRESS (1/5 plans)
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
| cart_items migration `20260504000000_cart_items_and_compute_totals.sql` requires manual application via Supabase Dashboard; `price_cop` stays whole COP pesos in cart_items; Wompi ×100 deferred to Phase 9 | plan 08-01 SUMMARY (`b25d5f7`) |
| cartItemsProvider returns Stream.empty() for unauthenticated users (not error) so StreamProvider yields AsyncValue.data([]) not AsyncValue.error | plan 08-01 SUMMARY (`3da36fb`) |
| cartTotalsProvider short-circuits to CartTotalsEntity.zero on empty cart to avoid unnecessary RPC round-trip | plan 08-01 SUMMARY (`3da36fb`) |
| QRCustomization.fromJson uses .firstWhere(orElse: () => GradientType.solid) for GradientType resolution — forward-compatible with future enum additions | plan 08-01 SUMMARY (`3da36fb`) |
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
| analyzeImageOverride + httpGetOverride callbacks injected into QrAiStyleService.stylize() for unit test isolation — avoids platform-native MobileScannerController and real HTTP calls in test environment | plan 06-03 SUMMARY (`69d3798`) |
| home_widget 0.9.1 renderFlutterWidget returns Future<String> (the saved file path) NOT Future<bool?> — verified from pub cache source at ~/.pub-cache/hosted/pub.dev/home_widget-0.9.1/lib/src/home_widget.dart | plan 06-04 SUMMARY (`eb5f308`) |
| HomeWidgetAdapter abstract interface + _DefaultHomeWidgetAdapter wraps real HomeWidget statics; optional adapter param in QrWidgetService.pinQrToWidget() for test injection | plan 06-04 SUMMARY (`eb5f308`) |
| mocktail with abstract Widget parameter requires registerFallbackValue(_FakeWidget()) with _FakeWidget.toString({DiagnosticLevel}) override; also requires registerFallbackValue(const Size(...)) | plan 06-04 SUMMARY (`eb5f308`) |
| logicalSize capped at Size(300,300) in QrWidgetService.pinQrToWidget — T-06-14 iOS WidgetKit memory limit (~30MB) guard | plan 06-04 SUMMARY (`eb5f308`) |
| http ^1.2.0 and path_provider ^2.1.2 added as direct deps (were transitive) to satisfy depend_on_referenced_packages lint rule | plan 06-03 SUMMARY (`69d3798`) |
| QrAiStylePage receives qrStorageUrl as constructor parameter — caller provides pre-uploaded URL to avoid storage upload logic in the page | plan 06-03 SUMMARY (`f877e31`) |
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
| MaterialPreviewWidget URL guard `textureUrl.isEmpty \|\| !textureUrl.startsWith('https://')` provides a second-layer T-07-08 defense at the widget render level (first layer is MaterialModel.fromJson sanitization) | plan 07-03 SUMMARY (`59096c7`) |
| MaterialPreviewWidget white-bg rule: decoration.copyWith(background: Colors.white) called even though QrDecorationBuilder.buildDecoration already sets white — explicit call mirrors QrExportService contract and makes the invariant obvious at the call site | plan 07-03 SUMMARY (`59096c7`) |
| catalogProvider uses `FutureProvider.autoDispose` + nested SELECT (single denormalized JOIN query, no N+1) | plan 07-01 SUMMARY |
| Server-authoritative order FSM (Postgres CHECK + RPC); client read-only | research ARCHITECTURE.md |
| Idempotent webhook via `payment_events.event_id PRIMARY KEY` | research ARCHITECTURE.md |
| Customization snapshot pattern (JSONB + 2160px PNG) frozen at cart/order time | research ARCHITECTURE.md |
| captureSnapshot forces EC-H by passing hasLogo=true override to QrDecorationBuilder.buildQrImage() — QrImage factory takes QrCode object not data string; EC-H ensures sufficient damage tolerance for all print-safe engraving | plan 08-03 SUMMARY (`acb0d0b`) |
| unawaited() PNG upload: cart item lives even if order-assets/ Storage unavailable; JSONB snapshot is the canonical engraver input (MKT-12) | plan 08-03 SUMMARY (`73ad8c0`) |
| _QrThumbnail uses CachedNetworkImage with icon fallback — handles null pngStorageUrl gracefully for items added before upload completed | plan 08-03 SUMMARY (`73ad8c0`) |
| es_CO NumberFormat.currency places symbol AFTER number ('89.000 $'); test helpers must use same formatter to avoid hardcoded locale-format divergence | plan 08-04 SUMMARY (`20172ae`) |
| _onProceedToCheckout() is an extracted replace-point method; Phase 9 replaces SnackBar body with navigation to CheckoutScreen + server-computed Wompi amount | plan 08-04 SUMMARY (`082f488`) |
| Server-side `compute_order_totals()` for IVA + envío (NOT client-computed) | research ARCHITECTURE.md, PITFALLS.md |
| Wompi secrets ONLY in Supabase Edge Function env (never in Flutter app) | research STACK.md, PITFALLS.md |
| orders migration `20260505000000_orders_payments_schema.sql` requires manual apply via Supabase Dashboard → SQL Editor before Plan 02 can run | plan 09-01 SUMMARY (`63dd0e3`) |
| payment_events.event_id TEXT PRIMARY KEY is the idempotency cornerstone for Wompi webhook replay safety — insert-or-fail pattern | plan 09-01 SUMMARY (`63dd0e3`) |
| validate_order_transition BEFORE UPDATE trigger enforces FSM at DB level; RPC and operator code just call UPDATE — trigger catches invalid transitions | plan 09-01 SUMMARY (`63dd0e3`) |
| create_order RPC uses empty string '' as order_number placeholder so WHEN condition fires the BEFORE INSERT trigger | plan 09-01 SUMMARY (`63dd0e3`) |
| apply_payment_event maps all non-APPROVED Wompi statuses (DECLINED/VOIDED/ERROR) to payment_failed order status — retryable via payment_pending reset in FSM | plan 09-01 SUMMARY (`63dd0e3`) |
| appNavigatorKey declared in deeplink_service.dart (not main.dart) to avoid circular import; wired to MaterialApp.navigatorKey for cold-launch payment result deep links | plan 09-03 SUMMARY (`56488a3`) |
| PaymentResultScreen uses Supabase query orders.status (server-authoritative); URL params from qraft://payment-result are never trusted (T-09-11) | plan 09-03 SUMMARY (`56488a3`) |
| isPaymentResultLink checked BEFORE auth deep link processing in DeepLinkHandler.handleDeepLink — prevents auth state machine from consuming payment-result URLs (T-09-12) | plan 09-03 SUMMARY (`56488a3`) |
| PSE retry: 5 attempts × 2s = 10s before switching to pendingPSE UI state; PSE users instructed to return and verify later | plan 09-03 SUMMARY (`56488a3`) |
| Integrity signature computed in Edge Function via crypto.subtle (Deno built-in); Flutter binary never sees WOMPI_INTEGRITY_SECRET (T-09-06) | plan 09-02 SUMMARY (`dfb7e90`) |
| wompi-webhook returns 200 on apply_payment_event RPC errors (not 500) to prevent Wompi retry storms; event already idempotently in payment_events for reconciliation | plan 09-04 SUMMARY (`9fc5056`) |
| wompi-webhook checks both X-Event-Checksum header AND signature.checksum body field; header takes priority per Wompi spec; body fallback for compatibility | plan 09-04 SUMMARY (`9fc5056`) |
| Non-transaction.updated events recorded in payment_events but cause no FSM state change — logged as informational, no RPC call | plan 09-04 SUMMARY (`9fc5056`) |
| Habeas data deletion is operator-manual until Phase 12; pqrs_submissions row provides Ley 1581 audit trail for SIC compliance | plan 09-05 SUMMARY (`747cd62`) |
| FcmService uses injectable testInstance factory (messaging + currentUserIdResolver) to enable unit testing without real Firebase/Supabase | plan 10-01 SUMMARY (`d50c4c2`) |
| firebaseBackgroundMessageHandler is a no-op stub in Phase 10 plan 01 — Plan 03 adds local notification display via flutter_local_notifications | plan 10-01 SUMMARY (`d50c4c2`) |
| notifications table has NO INSERT/UPDATE/DELETE policy for authenticated role — only service_role (send-fcm Edge Function) may write (T-10-02) | plan 10-01 SUMMARY (`d50c4c2`) |
| user_fcm_tokens UNIQUE(user_id, token) + upsert on conflict is the DoS guard (T-10-04); token never logged (T-10-03) | plan 10-01 SUMMARY (`d50c4c2`) |
| order_id FK in garantia/pqrs uses display number in subject/body; UUID lookup deferred to Phase 10 when OrderDetailScreen lands | plan 09-05 SUMMARY (`747cd62`) |
| RetractoDisclaimerWidget replaces inline amber Container from Plan 09-03 — single source of truth for Ley 1480 Art. 47 text | plan 09-05 SUMMARY (`747cd62`) |
| Amount in cents fetched from orders.total_cop after create_order RPC; client has no amount field in the Edge Function request body (T-09-07) | plan 09-02 SUMMARY (`dfb7e90`) |
| DANE departamento/municipio dataset bundled as assets/data/colombia_dane.json (offline-capable, no API calls, <100KB) | plan 09-02 SUMMARY (`6552b94`) |
| CartScreen._onProceedToCheckout: SnackBar stub replaced with MaterialPageRoute push to ShippingScreen | plan 09-02 SUMMARY (`6552b94`) |

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

**Files written this session (plan 10-01 execution):**

- `supabase/migrations/20260510000000_notifications_fcm_schema.sql` — user_fcm_tokens + notifications DDL + RLS; manual apply via Supabase Dashboard SQL Editor
- `lib/core/services/fcm_service.dart` — FcmService (requestPermission, initialize, _registerToken via upsert) + FcmService.testInstance injectable factory + fcmServiceProvider
- `test/core/services/fcm_service_test.dart` — 5 unit tests (TDD RED/GREEN)
- `lib/main.dart` — firebase_messaging import + onBackgroundMessage before runApp + FCM init on sign-in
- `.planning/phases/10-orders-realtime-fcm/10-01-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (Phase 10 plan 01 marked)

**Last session (plan 10-01):** 2026-05-03 — FCM activated from dormant state. Commits `c084a3d` (migration) + `554ee00` (RED tests) + `d50c4c2` (FcmService GREEN + main.dart wiring). flutter analyze 0 issues. 5/5 tests pass. NOTE: user_fcm_tokens + notifications migration requires manual apply via Supabase Dashboard SQL Editor before FCM token registration will succeed.

**Files written this session (plan 09-05 execution):**

- `supabase/migrations/20260505000001_pqrs_schema.sql` — pqrs_submissions DDL + RLS (INSERT/SELECT own) + indexes; apply via Supabase Dashboard SQL Editor
- `lib/features/legal/presentation/pages/privacy_policy_screen.dart` — 8-section Ley 1581 policy (StatelessWidget)
- `lib/features/legal/presentation/pages/habeas_data_screen.dart` — export + deletion flows, pqrs audit trail (ConsumerWidget)
- `lib/features/legal/presentation/pages/pqrs_screen.dart` — PQRS FormBuilder form → pqrs_submissions (ConsumerStatefulWidget)
- `lib/features/legal/presentation/pages/garantia_screen.dart` — 3-month warranty claim (ConsumerStatefulWidget)
- `lib/features/legal/presentation/pages/terms_screen.dart` — T&C with retracto exclusion (StatelessWidget)
- `lib/features/checkout/presentation/widgets/retracto_disclaimer_widget.dart` — canonical Ley 1480 Art. 47 amber card
- `lib/features/checkout/presentation/pages/payment_result_screen.dart` — replaced inline amber Container with RetractoDisclaimerWidget; added "Ver términos y condiciones" link
- `lib/features/profile/presentation/pages/profile_screen.dart` — added "Legal y soporte" section with 5 tiles + Semantics identifiers
- `lib/features/auth/presentation/pages/signup_screen.dart` — added privacy policy link below register button
- `.planning/phases/09-checkout-wompi-compliance/09-05-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (Phase 9 marked COMPLETE)

**Last session (plan 09-05):** 2026-05-03 — Full Colombian legal compliance (LGL-02..LGL-05). Commits `cf05f56` (legal screens + migration) + `747cd62` (RetractoDisclaimerWidget + wiring). flutter analyze 0 issues project-wide. Phase 9 COMPLETE (5/5 plans). NOTE: pqrs_submissions migration (`20260505000001_pqrs_schema.sql`) requires manual application via Supabase Dashboard SQL Editor before PQRS/HabeasData/Garantia forms can submit successfully.

**Files written this session (plan 09-04 execution):**

- `supabase/functions/wompi-webhook/index.ts` — Deno Edge Function: SHA256 X-Event-Checksum verification, idempotent payment_events insert (PK collision → 200), apply_payment_event RPC call for order FSM transitions
- `supabase/functions/wompi-webhook/deno.json` — Import map + lint config
- `.planning/phases/09-checkout-wompi-compliance/09-04-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 09-04):** 2026-05-03 — wompi-webhook Edge Function created and deployed ACTIVE. Commit `9fc5056`. Forged-event test confirmed 401 rejection. WOMPI_EVENTS_SECRET set in Supabase secrets. STOPPED at checkpoint:human-verify Task 2 — user must register webhook URL in Wompi Sandbox dashboard. Resume signal: "webhook verified: forged event rejected, valid payment approved order".

**Files written this session (plan 09-02 execution):**

- `supabase/functions/create-payment-intent/index.ts` — Deno Edge Function: JWT extraction, create_order RPC, order total fetch, SHA-256 integrity hash, Wompi URL builder
- `lib/core/config/wompi_config.dart` — WompiPaymentConfig
- `lib/core/services/payments_service.dart` — PaymentsService + PaymentServiceException
- `lib/features/checkout/domain/entities/shipping_address.dart` — ShippingAddress entity
- `lib/features/checkout/domain/entities/checkout_session.dart` — Added fromJson()/toJson()
- `lib/features/checkout/domain/use_cases/create_order_use_case.dart` — CreateOrderUseCase
- `lib/features/checkout/data/repositories/checkout_repository_impl.dart` — CheckoutRepositoryImpl
- `lib/features/checkout/presentation/providers/checkout_providers.dart` — shippingAddressProvider + createOrderProvider.family
- `lib/features/checkout/presentation/pages/shipping_screen.dart` — ShippingScreen with DANE cascading dropdowns
- `lib/features/cart/presentation/pages/cart_screen.dart` — _onProceedToCheckout wired to ShippingScreen
- `assets/data/colombia_dane.json` — 33 DANE departments + municipalities
- `pubspec.yaml` — assets/data/ bundle added
- `.planning/phases/09-checkout-wompi-compliance/09-02-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 09-02):** 2026-05-03 — create-payment-intent Edge Function + ShippingScreen + CartScreen wiring complete. Commits `dfb7e90` (Edge Function + domain) + `6552b94` (ShippingScreen + CartScreen). flutter analyze 0 issues. STOPPED at checkpoint:human-verify — user must deploy Edge Function and verify order creation in Supabase. Resume signal: "shipping form works, order created in Supabase".

**Files written this session (plan 09-03 execution):**

- `lib/features/checkout/presentation/pages/payment_result_screen.dart` — Full Supabase-polling payment result screen; 4-state machine (polling/paid/failed/pendingPSE); neon animated checkmark; Ley 1480 disclaimer; PSE retry loop; _OrderDetailPlaceholder stub
- `lib/core/services/deeplink_service.dart` — Added `appNavigatorKey`, `isPaymentResultLink`, `parsePaymentResultLink`, `_handlePaymentResult` in DeepLinkHandler before auth checks
- `lib/main.dart` — Wire `appNavigatorKey` into `MaterialApp.navigatorKey`
- `.planning/phases/09-checkout-wompi-compliance/09-03-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 09-03):** 2026-05-03 — WompiWebViewScreen + PaymentResultScreen + DeepLinkService extension complete. Commits `0249a69` (WompiWebViewScreen + PaymentResultScreen initial) + `56488a3` (deeplink extension + navigatorKey). flutter analyze 0 issues. MKT-05 marked complete.

**Files written this session (plan 09-01 execution):**

- `supabase/migrations/20260505000000_orders_payments_schema.sql` — Full DDL: order_status (11 vals) + payment_status (6 vals) enums, orders/order_items/payments/payment_events tables, validate_order_transition BEFORE UPDATE FSM trigger, generate_order_number BEFORE INSERT trigger, create_order + apply_payment_event SECURITY DEFINER RPCs, RLS policies, GRANTs
- `.planning/phases/09-checkout-wompi-compliance/09-01-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (09-01 marked in-progress at checkpoint)

**Last session (plan 09-01):** 2026-05-03 — Orders + payments schema DDL written and committed. Commit `63dd0e3`. STOPPED at checkpoint:human-action — migration not yet applied, Wompi secrets not yet set. Plan 02 cannot proceed until both steps are complete. Resume signal: "migration applied, secrets set".

**Files written this session (plan 08-04 execution):**

- `lib/features/cart/presentation/widgets/cart_summary_widget.dart` — ConsumerWidget watching cartTotalsProvider; 4-row COP breakdown (subtotal/IVA 19%/envío/total); shimmer loading; Semantics identifiers
- `lib/features/cart/presentation/pages/cart_screen.dart` — _CartSummaryPlaceholder removed; CartSummaryWidget + PrimaryGlassButton('Proceder al pago') wired; totalsReady guard disables button during loading; _onProceedToCheckout SnackBar placeholder
- `test/features/cart/presentation/widgets/cart_summary_widget_test.dart` — 4 widget tests (TDD RED/GREEN)
- `.planning/phases/08-cart-customization-snapshot/08-04-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (08-04 checkbox + Phase 8 COMPLETE marked)

**Last session (plan 08-04):** 2026-05-03 — CartSummaryWidget + 'Proceder al pago' button wired. Commits `0bee67d` (RED tests) + `20172ae` (CartSummaryWidget GREEN) + `082f488` (CartScreen integration). flutter analyze lib/features/cart/ 0 issues. 4/4 CartSummaryWidget tests; 17/17 cart tests pass. Phase 8 COMPLETE (4/4 plans). Key decisions: es_CO locale outputs trailing symbol '89.000 $'; test _cop() helper mirrors implementation format; pending timer guard in loading test via tester.pump(11s).

**Files written this session (plan 08-03 execution):**

- `lib/features/cart/domain/services/customization_snapshot_service.dart` — SnapshotResult + CustomizationSnapshotService (buildSnapshotJson + captureSnapshot)
- `lib/features/cart/data/datasources/order_assets_storage_data_source.dart` — Storage upload + patchPngUrl + storagePath
- `lib/features/marketplace/presentation/pages/product_detail_screen.dart` — _addToCart wired with captureSnapshot + unawaited _uploadSnapshotPng
- `lib/features/cart/presentation/providers/cart_providers.dart` — orderAssetsStorageDsProvider added
- `lib/features/cart/presentation/widgets/cart_item_tile.dart` — _QrThumbnail replaces icon placeholder (CachedNetworkImage)
- `test/features/cart/domain/services/customization_snapshot_service_test.dart` — 4 TDD unit tests
- `.planning/phases/08-cart-customization-snapshot/08-03-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (08-03 checkbox marked)

**Last session (plan 08-03):** 2026-05-03 — CustomizationSnapshotService + OrderAssetsStorageDataSource + wired add-to-cart pipeline + CartItemTile thumbnail. Commits `8cc89db` (RED tests) + `acb0d0b` (Task 1) + `73ad8c0` (Task 2). flutter analyze 0 issues. 4/4 new tests pass; 13/13 cart tests pass. Phase 8 in progress (3/4 plans). Key decisions: QrDecorationBuilder.buildQrImage() with hasLogo=true to force EC-H; unawaited PNG upload (JSONB is source of truth); _QrThumbnail with graceful icon fallback.

**Files written this session (plan 08-02 execution):**

- `lib/features/marketplace/presentation/pages/product_detail_screen.dart` — ConsumerWidget → ConsumerStatefulWidget; _addToCart() with auth guard + QR-selection guard + cartRepositoryProvider.addItem() + CartScreen navigation; isLoading passed to PrimaryGlassButton
- `lib/features/cart/presentation/pages/cart_screen.dart` — CartScreen: shimmer skeleton, error+retry, empty state, ListView.separated CartItemTile, _CartSummaryPlaceholder stub
- `lib/features/cart/presentation/widgets/cart_item_tile.dart` — single item row: QR icon, product name, quantity ±(capped 99, decrement-to-zero = removeItem), delete button, Semantics identifiers
- `.planning/phases/08-cart-customization-snapshot/08-02-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (08-02 checkbox marked)

**Last session (plan 08-02):** 2026-05-03 — CartScreen + CartItemTile + wired AddToCart button. Commits `1a9ccce` (ProductDetailScreen) + `79aa86b` (CartScreen + CartItemTile). flutter analyze 0 issues. Phase 8 in progress (2/4 plans). Key decisions: ConsumerStatefulWidget pattern for _isLoading state; CartSummaryPlaceholder stub awaits Phase 9 checkout; QR thumbnail icon placeholder until Plan 03 populates pngStorageUrl.

**Files written this session (plan 08-01 execution):**

- `supabase/migrations/20260504000000_cart_items_and_compute_totals.sql` — cart_items table DDL + RLS (4 policies: SELECT/INSERT/UPDATE/DELETE all scoped to user_id = auth.uid()) + server_compute_order_totals() SECURITY DEFINER RPC (IVA 19% + flat 15000 COP envio)
- `lib/features/cart/domain/entities/cart_item_entity.dart` — CartItemEntity with fromJson/toJson + Equatable; customizationSnapshot as Map; pngStorageUrl nullable
- `lib/features/cart/domain/entities/cart_totals_entity.dart` — CartTotalsEntity with zero sentinel + fromRpcRow factory
- `lib/features/cart/domain/repositories/cart_repository.dart` — abstract CartRepository (watchCart, addItem, updateQuantity, removeItem, clearCart, computeTotals)
- `lib/features/cart/data/models/cart_item_model.dart` — CartItemModel extends CartItemEntity; fromSupabaseRow constructor
- `lib/features/cart/data/datasources/cart_supabase_data_source.dart` — watchCart via .stream(primaryKey) + upsert + computeTotals RPC call
- `lib/features/cart/data/repositories/cart_repository_impl.dart` — CartRepositoryImpl + CartException; quantity clamp 1..99
- `lib/features/cart/presentation/providers/cart_providers.dart` — cartRepositoryProvider + cartItemsProvider (StreamProvider) + cartTotalsProvider (FutureProvider)
- `lib/features/qr_generator/domain/entities/qr_code_entity.dart` — QRCustomization.toJson() + QRCustomization.fromJson() for JSONB snapshot serialization
- `test/features/cart/domain/cart_entities_test.dart` — 9 unit tests (entities, model, totals, JSON serialization)
- `.planning/phases/08-cart-customization-snapshot/08-01-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (08-01 checkbox marked)

**Last session (plan 08-01):** 2026-05-03 — Supabase cart_items DDL + RLS + server_compute_order_totals RPC + full Dart cart domain/data/providers + QRCustomization JSON serialization. Commits `b25d5f7` (migration) + `3da36fb` (Dart layer). flutter analyze lib/features/cart/ 0 issues. 9/9 tests pass. Phase 8 in progress (1/4 plans). Key decision: migration manual-apply only (same pattern as 04-01/07-01); price_cop stays whole COP pesos; cartItemsProvider returns Stream.empty() for unauthenticated (not error).

**Files written this session (plan 06-04 execution):**

- `lib/features/qr_digital/domain/services/qr_widget_service.dart` — QrWidgetService.pinQrToWidget() + HomeWidgetAdapter interface + _DefaultHomeWidgetAdapter; logicalSize capped at Size(300,300) T-06-14; saves qr_label (40-char truncation) + updated_at before updateWidget
- `lib/features/qr_digital/presentation/pages/qr_widget_pin_page.dart` — QrWidgetPinPage ConsumerStatefulWidget; QR preview card (200×200 PrettyQrView); platform instruction card (iOS/Android via Platform.isIOS, glassmorphism); neon gradient pin button (#00FF88); Semantics(identifier: 'widget_pin_button'); SnackBar success/error
- `ios/QRaftWidgetExtension/QRaftWidget.swift` — WidgetKit TimelineProvider + QRaftEntry + QRaftWidgetEntryView + QRaftWidget; kind: "QRaftWidget"; App Group group.io.gothcorp.qraft; systemSmall + systemMedium; iOS 17 containerBackground compat
- `ios/QRaftWidgetExtension/QRaftWidgetBundle.swift` — @main WidgetBundle entry point
- `android/app/src/main/kotlin/io/gothcorp/qraft/QrWidget.kt` — GlanceAppWidget with HomeWidgetGlanceStateDefinition; reads qr_widget_image path; BitmapFactory.decodeFile; fallback Text
- `android/app/src/main/kotlin/io/gothcorp/qraft/QrWidgetReceiver.kt` — HomeWidgetGlanceWidgetReceiver<QrWidget>
- `android/app/src/main/res/xml/qr_widget_info.xml` — AppWidget provider metadata 110dp×110dp updatePeriodMillis=0
- `test/features/qr_digital/services/qr_widget_service_test.dart` — 5 unit tests; MockHomeWidgetAdapter via mocktail; _FakeWidget fake with DiagnosticLevel override; registerFallbackValue(Widget) + registerFallbackValue(Size)
- `pubspec.yaml` — home_widget: ^0.9.1
- `android/app/build.gradle.kts` — glance-appwidget:1.1.1 dependency
- `android/app/src/main/AndroidManifest.xml` — QrWidgetReceiver <receiver> with APPWIDGET_UPDATE + qr_widget_info metadata
- `.planning/phases/06-qr-digital-features/06-04-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (Phase 6 marked COMPLETE)

**Last session (plan 06-04):** 2026-05-03 — home_widget QrWidgetService + native stubs + QrWidgetPinPage. Commits `eb5f308` (home_widget + service + tests + native stubs) + `b06451a` (QrWidgetPinPage). flutter analyze 0 issues. 5/5 tests pass. Phase 6 COMPLETE (4/4 plans). Key deviations: renderFlutterWidget returns Future<String> not Future<bool?> (real API verified from pub cache); HomeWidgetAdapter interface added for testability; mocktail Widget/Size fallback registration required.

**Files written this session (plan 07-04 execution — close-out):**

- `lib/features/marketplace/presentation/pages/product_detail_screen.dart` — replaced `Key('qr_preview_placeholder')` stub with `MaterialPreviewWidget`; added `_SelectQrPrompt`, `_PreviewShimmer`, `_PreviewError` private widgets; `userQRCodesProvider.when()` for async QR entity lookup by id
- `lib/features/marketplace/presentation/providers/marketplace_providers.dart` — added `selectedQrForMarketplaceProvider` (`StateProvider<String?>`) as library→marketplace loose-coupling bridge
- `lib/features/marketplace/marketplace_screen.dart` — reads `selectedQrForMarketplaceProvider` at card-tap to pass `qrCodeId` into `ProductDetailScreen`
- `lib/features/qr_library/qr_library_screen.dart` — added "Engrabar" `PopupMenuItem` (sets provider, pushes `MarketplaceScreen`)
- `.planning/phases/07-marketplace-catalog/07-04-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (Phase 7 checkbox marked complete)

**Last session (plan 07-04):** 2026-05-03 — QR library → marketplace wiring; selectedQrForMarketplaceProvider bridge; MaterialPreviewWidget replacing placeholder in ProductDetailScreen. Commit `d0484a2`. flutter analyze 0 issues. 4/4 marketplace tests pass. Phase 7 COMPLETE (4/4 plans).

**Files written this session (plan 07-03 execution):**

- `lib/features/marketplace/presentation/widgets/material_preview_widget.dart` — MaterialPreviewWidget: Stack(CachedNetworkImage texture + white QR label PrettyQrView); textureUrl isEmpty/non-https guard → MaterialGradients fallback; shimmer placeholder; copyWith(background: Colors.white) white-bg enforcement
- `test/features/marketplace/presentation/material_preview_test.dart` — 4 widget tests: gradient fallback on empty/non-https URL; PrettyQrView always present; QR label 72% of previewSize via RenderBox assertion
- `.planning/phases/07-marketplace-catalog/07-03-SUMMARY.md`
- `.planning/STATE.md` (this file)

**Last session (plan 07-03):** 2026-05-03 — MaterialPreviewWidget self-contained Stack widget. Commits `59096c7` (widget) + `89bf471` (tests). flutter analyze 0 issues. 4/4 tests pass. Phase 7 in progress (3/4 plans).

**Files written this session (plan 07-02 execution):**

- `lib/features/marketplace/presentation/widgets/material_filter_bar.dart` — MaterialFilterBar ConsumerWidget; chips from catalogProvider; shimmer loading; neon selected state
- `lib/features/marketplace/presentation/widgets/product_variant_card.dart` — ProductVariantCard glassmorphism card + ProductVariantCardShimmer; COP price via intl; flutter_animate entrance
- `lib/features/marketplace/presentation/pages/product_detail_screen.dart` — ProductDetailScreen with qrCodeId hook; QR preview placeholder Key; qraft.link info banner; Phase 8 cart CTA snackbar
- `lib/features/marketplace/marketplace_screen.dart` — full replacement; ConsumerStatefulWidget; filteredCatalogProvider; ComingSoonOverlay removed; loading/error/empty/data grid states
- `.planning/phases/07-marketplace-catalog/07-02-SUMMARY.md`
- `.planning/STATE.md` (this file)
- `.planning/ROADMAP.md` (07-02 checkbox marked)

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

**Last session (plan 07-02):** 2026-05-03 — MaterialFilterBar + ProductVariantCard + replace MarketplaceScreen + ProductDetailScreen. Commits `97f4909` (widgets) + `79c9d4a` (screen + detail). flutter analyze lib/features/marketplace/: 0 issues. Phase 7 in progress (2/4 plans).

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
