# Stack Research

**Domain:** Flutter QR app — advanced QR generation/scanning + Colombian e-commerce marketplace (Wompi) + observability
**Researched:** 2026-05-01
**Confidence:** HIGH (versions verified on pub.dev today; Wompi specifics from official docs)

## Scope

This document covers **what to ADD** for the next milestone. The locked baseline (Flutter 3.6.2+, Riverpod 2.4.9, Supabase 2.0.0, Firebase Auth, AdMob, RevenueCat, mobile_scanner 7.0.0, qr_flutter 4.1.0, go_router 13.0.0, webview_flutter 4.13.1) is out of scope and must not be re-litigated.

**Net additions across this milestone:**
1. Replace/augment `qr_flutter` with `pretty_qr_code` for advanced customization (logo, gradient, eye styles).
2. Bump `mobile_scanner` 7.0.0 → 7.2.0 (unblocks iOS via Vision API, eliminates MLKit on iOS).
3. Wompi Colombia integration via REST + WebView checkout, with webhooks verified by Supabase Edge Function.
4. Observability: `firebase_crashlytics` + `firebase_analytics` + `firebase_messaging` (FCM) — single-vendor Firebase stack.
5. Form/cart helpers: `flutter_form_builder`, `screenshot`, `csv`, `path_provider`.

---

## Recommended Stack — Additions

### Advanced QR Generation

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **pretty_qr_code** | ^3.6.0 | Replaces/augments qr_flutter for advanced visual customization | Current (Feb 2026), MIT, multi-platform (iOS/Android/Web/Desktop). Native support for logo embedding, gradient fill (linear/radial), shape modes (smooth/squares/dots), per-finder-pattern styling. This is the cleanest path to QR-02..QR-04 without forking qr_flutter. **Confidence: HIGH** |
| **qr_flutter** | ^4.1.0 (kept) | Baseline QR rendering when no customization is needed | Already integrated; keep for fallback / simple cases (CSV bulk thumbnails, fast paths). No reason to remove. **Confidence: HIGH** |
| **screenshot** | ^3.0.0 | Capture rendered QR widget → PNG/JPEG for export & share | Wraps `RenderRepaintBoundary` (the Flutter-native approach). Required for QR-09 (share image) and marketplace previews where the user's QR is composited onto material previews. Note: Platform Views are not capturable (irrelevant here — QR is pure Flutter). **Confidence: HIGH** |
| **csv** | ^8.0.0 | Parse CSV uploads for bulk QR generation (QR-07) | Stream-based decoder (low memory for large files), Excel-compatible (UTF-8 BOM, semicolon delimiter — relevant for Colombian users exporting from Excel-ES). **Confidence: HIGH** |

**Rationale for pretty_qr_code over alternatives:**
- `qr_flutter` 4.1.0: ships with no gradient/eye-style/finder-pattern support. Last meaningful update years ago. Cannot meet QR-02..QR-05 without significant fork work.
- `custom_qr_generator` 0.1.2: **DO NOT USE** — last published 3 years ago, "unverified uploader," 560 total downloads, logo support still listed as "in development." Abandoned.
- `qr_code_dart_art`: returns 404 on pub.dev — no longer published.
- `pretty_qr_code` 3.6.0: actively maintained, clean Flutter widget API, fits the Carden Pro design language.

### QR Scanning

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **mobile_scanner** | ^7.2.0 | QR/barcode camera scanning | **Bumping from currently-installed 7.0.0 to 7.2.0** unblocks SCAN-01. Version 7.0.0 (released early 2025) migrated iOS from MLKit to **Apple Vision API**, removing the heavy Google MLKit pod that was the source of the iOS dependency block in CONCERNS.md. 7.2.0 (Mar 2026) adds tap-to-focus and lens switching. iOS minimum is 13. **Confidence: HIGH** |

**iOS Caveat (document for the team, not a blocker):**
On iOS, `rawBytes` returns `null` for QR codes using Kanji mode and for linear barcodes containing Windows-1252 bytes (0x80–0x9F). For QRaft this is **not relevant** — we work with text/URL/vCard/WiFi payloads which use UTF-8 / standard QR alphanumeric mode. Document in code comments only.

**Alternatives we reject:**

| Rejected | Why |
|----------|-----|
| `flutter_zxing` ^2.3.0 | Active and FFI-based (no MLKit), but switching from `mobile_scanner` mid-project costs API rewrites in the existing scanner UI, and ZXing C++ binaries inflate iOS app size. Only worth it if `mobile_scanner` 7.x doesn't resolve the iOS block — and per changelog evidence, it does. |
| `ai_barcode_scanner` ^7.1.0 | Just an opinionated UI wrapper around `mobile_scanner`. We already have a custom Carden Pro overlay design — wrapping our own UI on top of `mobile_scanner` directly is cleaner than fighting a wrapper's prebuilt UI. |

### Payments — Wompi (Colombia)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Wompi REST API** | v1 | Direct integration via `dio` or `http` from Flutter + Supabase Edge Function for webhooks | No official Wompi Flutter SDK exists. The community wrapper `wompi_payment_colombia` 3.0.0 was last published 21 months ago, missing Daviplata + Bancolombia Transfer, and explicitly disclaims affiliation. **Build thin client against REST.** **Confidence: HIGH** |
| **flutter_inappwebview** | ^6.x | Embed Wompi Web Checkout for card flow / 3DS | Already have `webview_flutter` 4.13.1 — **keep that and don't add a second WebView dep**. webview_flutter is sufficient for loading the Wompi checkout URL and intercepting the `redirect-url` to detect transaction completion. Only add `flutter_inappwebview` if we hit a feature gap (cookie/header injection); not anticipated. **Confidence: MEDIUM** |
| **crypto** | ^3.0.x (transitive via supabase_flutter) | SHA-256 for Wompi integrity hash on Edge Function side | Already in tree via Supabase. The integrity hash MUST be computed server-side (Supabase Edge Function) — never expose `integrity_secret` in the Flutter client. **Confidence: HIGH** |

**Wompi integration architecture (concrete):**

```
Flutter app                       Supabase Edge Function          Wompi
──────────                       ────────────────────────         ─────
1. Build cart, get total COP
2. POST /create-checkout-session  ──► Generate signature.integrity ──► (validated by Wompi)
                                       SHA256(reference + amount  
                                              + currency + secret)
3. Open Wompi Web Checkout URL    
   in WebView with public_key,    
   reference, integrity hash      
4. User pays (card/PSE/Nequi/     
   Daviplata)                       
5. Wompi calls webhook            ◄── POST /wompi-webhook ◄────── X-Event-Checksum header
                                       Verify SHA256(             
                                         {ordered properties}     
                                         + timestamp              
                                         + events_secret          
                                       ) == checksum              
                                       Update order status        
6. Realtime subscription on        
   `orders` table → user sees     
   confirmation                   
```

**Concrete endpoints/auth (verified from docs.wompi.co):**
- Production base: `https://production.wompi.co/v1`
- Sandbox base: `https://sandbox.wompi.co/v1`
- **Public key** (`pub_test_*` / `pub_prod_*`) — safe to ship in the app, used to fetch acceptance tokens, financial institutions list (PSE), tokenize cards.
- **Private key** (`prv_test_*` / `prv_prod_*`) — Edge Function ONLY. Used as `Authorization: Bearer prv_…` for `POST /v1/transactions` (server-to-server transaction creation if not using Web Checkout) and admin operations.
- **Integrity secret** — Edge Function ONLY. Used to compute `signature.integrity = SHA256(reference + amountInCents + currency + integrity_secret)` before opening the Web Checkout.
- **Events secret** — Edge Function ONLY. Used to verify webhook checksum: `SHA256({values of signature.properties in order} + timestamp + events_secret)` compared against `X-Event-Checksum` header / `signature.checksum` body field.
- Supported `payment_method.type`: `CARD`, `NEQUI`, `PSE`, `BANCOLOMBIA_TRANSFER`, `DAVIPLATA`, `BANCOLOMBIA_COLLECT` — covers MKT-05's spec.

**Why Web Checkout (WebView) over native REST card flow:**
- **PCI scope reduction** — card numbers never touch our app or our Supabase. Wompi's hosted page handles card capture and 3DS.
- **3D Secure v2 handled by Wompi** — no SCA flow code on our side.
- **Faster path to MKT-05/MKT-06** — single integration point covers cards + PSE + Nequi + Daviplata.
- **Trade-off:** less brand control on the payment screen. Acceptable for v1; revisit in v2 if conversion drops.

If the team later wants in-app native card capture: tokenize via `POST /v1/tokens/cards` with the public key (PCI scope still drops because Wompi returns a token), then create transaction server-side. Defer to post-v1.

### Push Notifications

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **firebase_messaging** | ^16.2.0 | FCM push notifications for order status (MKT-09) | We already have Firebase Auth → adding FCM is one config step (APNs key on iOS, no extra Android setup). Native integration with `firebase_analytics` events for notification opens. Free at QRaft's scale. **Confidence: HIGH** |
| `flutter_local_notifications` | ^17.x | Display foreground notifications + notification channels (Android 8+) | Required companion to `firebase_messaging` because FCM doesn't auto-display when the app is in foreground. **Confidence: HIGH** |

**Why NOT OneSignal:**
- No regional advantage in Colombia — both FCM and OneSignal route through APNs/FCM at the carrier level.
- OneSignal adds a second vendor + analytics silo; we'd lose tight coupling with our Firebase Analytics events.
- OneSignal free tier limits subscribers; FCM is unlimited.
- Existing Firebase project (`qraft-e8a1d`) makes FCM setup ~10 minutes.

### Observability

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **firebase_crashlytics** | ^5.2.0 | Crash + non-fatal error reporting (OPT-03) | Single-vendor with our existing Firebase project. Verified-publisher Flutter Favorite, 1.41M downloads. Auto-symbolicates iOS dSYMs and Android NDK stack traces. Free. **Confidence: HIGH** |
| **firebase_analytics** | ^12.3.0 | Funnel + retention + ad attribution events | Required pair with Crashlytics — Crashlytics issue cards include Analytics breadcrumbs (last 50 events before crash) only when both are installed. Critical for marketplace funnel debugging (cart → checkout → payment success). **Confidence: HIGH** |
| **firebase_performance** | ^0.11.x | Network call + screen render traces (optional, OPT-01 supporting) | Adds automatic HTTP latency tracking to Supabase calls. Lightweight, free. Add only if performance issues surface during phase polish. **Confidence: MEDIUM** |

**Why not Sentry:**
- `sentry_flutter` 9.19.0 is excellent (errors + traces + profiling + session replay) — but introducing a second observability vendor splits dashboards and increases cost (Sentry's free tier is 5k errors/month vs. Crashlytics unlimited). Crashlytics + Analytics already covers crash + funnel needs for v1.
- Reconsider Sentry post-v1 if we need: profiling on production builds, replay-style debugging, or release health metrics that Crashlytics doesn't surface.

### State Management Additions

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **flutter_riverpod** | ^2.4.9 (kept) | Cart/checkout state on top of existing baseline | No new dep needed. Use `StateNotifierProvider` (or `Notifier` in Riverpod 2.x) for cart, persist to Supabase via Realtime so cart survives app kills. **Confidence: HIGH** |
| **riverpod_generator** | ^2.x (optional) | Codegen for type-safe providers | Consider only if the team adopts the codegen style elsewhere; otherwise hand-written providers stay consistent with the existing Auth feature. **Confidence: MEDIUM** |

**Cart persistence pattern:** mirror the `subscription_realtime_service` approach already in the codebase — Supabase row in `cart_items` (or JSON in a `carts` table), Riverpod `.stream()` provider. No additional package required.

### Forms & Address Validation (Checkout)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **flutter_form_builder** | ^10.3.0 | Multi-field checkout form with validation (MKT-04) | Active (Feb 2026), 76.8k weekly downloads, conditional validation supports "if Departamento == Bogotá D.C., hide municipality dropdown" patterns. **Confidence: HIGH** |
| **form_builder_validators** | ^11.x | Validators companion (required, email, regex) | Standard companion to flutter_form_builder. **Confidence: HIGH** |
| **phone_form_field** | ^10.0.8 (already installed) | Phone input with Colombia +57 default | Keep — already in tree. **Confidence: HIGH** |

**Colombia address validation:** No off-the-shelf Colombian DANE validator package exists for Flutter. Maintain a static JSON of departments/municipalities (DANE list, ~33 departments / ~1,100 municipalities) in `assets/data/colombia_dane.json` and validate client-side. Cheaper and offline-capable vs. a 3rd-party API. Document this as a deliberate choice in roadmap.

### Image Handling (Logos in QR)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **image_picker** | ^1.0.7 (already installed) | User selects logo image from gallery/camera | Keep. **Confidence: HIGH** |
| **crop_your_image** | ^2.0.0 (already installed) | Square-crop logo before embedding into QR center | Keep. **Confidence: HIGH** |
| **image** | ^4.x | In-Dart image manipulation (resize logo to 80×80, alpha mask, white halo for scanability) | Pure-Dart (no native), runs on all platforms. Required to enforce QR-02's white halo around the logo to preserve readability with error correction H. **Confidence: HIGH** |
| **path_provider** | ^2.1.5 | App cache/documents dirs for offline logo cache & exported QR images | Standard Flutter plugin, last meaningful update fine for v1. **Confidence: HIGH** |
| **cached_network_image** | ^3.4.1 (already installed) | Cache material previews / template thumbnails | Already in tree. Keep. **Confidence: HIGH** |

### Reactive E-commerce Patterns (Realtime Order Tracking)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **supabase_flutter** Realtime | ^2.0.0 (already installed) | Subscribe to `orders` table for live status updates (MKT-08) | Already used for subscription tracking — same pattern. No new dep. **Confidence: HIGH** |

---

## Installation

```bash
# Advanced QR generation
flutter pub add pretty_qr_code screenshot csv image

# Wompi (HTTP only — no Wompi-specific package)
# 'http' or 'dio' likely already transitive; verify with `flutter pub deps`

# Push + Observability (single-vendor Firebase)
flutter pub add firebase_messaging firebase_crashlytics firebase_analytics flutter_local_notifications

# Forms
flutter pub add flutter_form_builder form_builder_validators

# Mobile scanner upgrade (currently 7.0.0 → 7.2.0)
# Edit pubspec.yaml: mobile_scanner: ^7.2.0
flutter pub upgrade mobile_scanner
```

**iOS post-install:**
```bash
cd ios && pod install --repo-update
```

**Firebase Crashlytics setup:**
- Add Crashlytics Gradle plugin to `android/app/build.gradle.kts` and `android/build.gradle.kts`.
- iOS: ensure `Run Script` build phase uploads dSYMs (`${PODS_ROOT}/FirebaseCrashlytics/run`).
- Add `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;` in `main.dart`.

**FCM iOS setup:**
- Upload APNs Auth Key (`.p8`) to Firebase Console → Cloud Messaging.
- Enable Push Notifications + Background Modes (Remote notifications) capabilities in Xcode.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `pretty_qr_code` | `qr_flutter` (kept for simple cases) | Use qr_flutter for thumbnail rendering of bulk-CSV QRs where customization isn't needed (saves render cycles). |
| `mobile_scanner` 7.2.0 | `flutter_zxing` 2.3.0 | Only if a future iOS regression in mobile_scanner re-introduces a build block that we can't resolve in 1 sprint. Migration cost: ~2 days for scanner UI rewrites. |
| Wompi REST + Web Checkout in WebView | `wompi_payment_colombia` 3.0.0 (community pkg) | Never — package is 21 months stale and missing payment methods we require. |
| `firebase_messaging` | `onesignal_flutter` 5.5.2 | If product team later wants OneSignal's segmentation/journey tooling without building it on top of Firebase. Not worth the dual-vendor cost in v1. |
| `firebase_crashlytics` | `sentry_flutter` 9.19.0 | If we need profiling-on-production or session replay. Reconsider in v2. |
| `webview_flutter` 4.13.1 (kept) | `flutter_inappwebview` 6.x | Only if Wompi checkout integration hits a header/cookie injection limitation we can't work around. Not anticipated. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `custom_qr_generator` 0.1.2 | Abandoned 3 years, "logo support in development" still, 560 downloads, unverified uploader. | `pretty_qr_code` 3.6.0 |
| `qr_code_dart_art` | Returns 404 on pub.dev — no longer published. | `pretty_qr_code` 3.6.0 |
| `wompi_payment_colombia` 3.0.0 | 21 months stale, missing Daviplata + Bancolombia Transfer, community wrapper with explicit non-affiliation disclaimer, 82 downloads. | Direct REST integration to `production.wompi.co/v1` from a Supabase Edge Function. |
| Hard-coding Wompi `integrity_secret` / `events_secret` / `private_key` in Flutter app | Even with `--dart-define`, secrets are extractable from the compiled binary. PCI/legal exposure. | Keep secrets in Supabase Edge Function env (`supabase secrets set`). Flutter app only ever sees `public_key`. |
| `mobile_scanner` 7.0.0 (current pinned) | Has minor camera-orientation bugs fixed in 7.1.3. | Upgrade to `^7.2.0`. |
| Calling Wompi `POST /v1/transactions` from the Flutter app with the private key | Private key in app = full account compromise. | Edge Function with `Authorization: Bearer prv_…`. |
| Native card capture (PAN entry in our UI) for v1 | Triggers PCI-DSS SAQ-D scope. ~6+ months of compliance work. | Web Checkout (WebView) — Wompi's hosted page keeps us at SAQ-A scope. |
| Adding `flutter_inappwebview` when `webview_flutter` is already installed | Two WebView plugins = two camera/permission stacks, build size bloat. | Use the existing `webview_flutter` 4.13.1. |
| `OneSignal` on top of existing Firebase | Adds vendor, splits analytics, costs at scale. No regional benefit in Colombia. | `firebase_messaging` 16.2.0. |

---

## Stack Patterns by Variant

**If iOS dependency block on `mobile_scanner` re-emerges after upgrade:**
- Pin to `mobile_scanner: 7.2.0` exact version in `pubspec.yaml`.
- Verify `ios/Podfile` `platform :ios, '13.0'` (was likely 12.0).
- If still blocked → migrate to `flutter_zxing` 2.3.0 (FFI-based, no MLKit). Budget 2 days for scanner UI rewrites.

**If Wompi Web Checkout WebView UX is unsatisfactory:**
- Migrate to in-app card tokenization: `POST /v1/tokens/cards` with public key, then transaction creation server-side via Edge Function.
- Still avoid native PAN capture (Wompi's JS widget tokenizes client-side then we POST the token).

**If notification volume grows beyond simple status updates (e.g., personalized marketing):**
- Add `firebase_in_app_messaging` (free, same vendor) before considering OneSignal.

**If observability needs deep performance debugging:**
- Add `firebase_performance` (^0.11.x) — same vendor, ~5 min config.
- Reach for Sentry only if profiling-on-prod or replay become hard requirements.

---

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| `mobile_scanner: ^7.2.0` | Flutter 3.29.0+, iOS 13+, Android API 21+ | **Action item:** verify project Flutter version meets 3.29.0+ (current locked at 3.6.2+ which means ≥3.6.2 — must be on 3.29.x or newer). If the team is on Flutter <3.29, mobile_scanner 7.x cannot be installed. |
| `pretty_qr_code: ^3.6.0` | Flutter SDK any 3.x, depends on `qr ^3.0.1` and `meta ^1.7.0` | No conflict with existing `qr_flutter`. |
| `firebase_messaging: ^16.2.0` | `firebase_core: ^4.7.0` | **Action item:** verify `firebase_core` version in current pubspec — adding messaging may force a `firebase_core` upgrade with cascading effects on `firebase_auth`. Check with `flutter pub upgrade --dry-run`. |
| `firebase_crashlytics: ^5.2.0` | Same `firebase_core: ^4.7.0` | Pair with `firebase_analytics: ^12.3.0`; both must align on `firebase_core` major. |
| `webview_flutter: 4.13.1` (current) | iOS 12+, Android API 19+ | Sufficient for Wompi Web Checkout. |
| `flutter_form_builder: ^10.3.0` | Flutter 3.x, Dart 3.x | Migration from v9 → v10 used `dart fix --apply`; we're greenfield-installing so irrelevant. |

**Pre-merge checklist for the roadmap to flag:**
- [ ] Confirm Flutter SDK ≥ 3.29 (mobile_scanner 7.x requirement).
- [ ] Confirm `firebase_core` upgrade path for messaging + crashlytics doesn't break existing firebase_auth.
- [ ] Verify `pubspec.lock` resolves `pretty_qr_code` alongside `qr_flutter` (both depend on `qr` package — minor version pin may conflict).

---

## Sources

- pub.dev / pretty_qr_code — version 3.6.0, features, multi-platform support — **HIGH**
- pub.dev / mobile_scanner — version 7.2.0, changelog, Vision API migration in 7.0.0 — **HIGH**
- pub.dev / mobile_scanner/changelog — iOS MLKit removal, iOS minimum 13 — **HIGH**
- pub.dev / firebase_crashlytics — version 5.2.0, Flutter Favorite — **HIGH**
- pub.dev / firebase_messaging — version 16.2.0, firebase_core ^4.7.0 dep — **HIGH**
- pub.dev / firebase_analytics — version 12.3.0 — **HIGH**
- pub.dev / sentry_flutter — version 9.19.0 (alternative considered) — **HIGH**
- pub.dev / flutter_form_builder — version 10.3.0+2 — **HIGH**
- pub.dev / screenshot — version 3.0.0, RenderRepaintBoundary — **HIGH**
- pub.dev / csv — version 8.0.0 — **HIGH**
- pub.dev / cached_network_image — version 3.4.1 — **HIGH**
- pub.dev / path_provider — version 2.1.5 — **HIGH**
- pub.dev / onesignal_flutter — version 5.5.2 (rejected) — **HIGH**
- pub.dev / wompi_payment_colombia — version 3.0.0, 21 months stale (rejected) — **HIGH**
- pub.dev / flutter_zxing — version 2.3.0 (alternative considered) — **HIGH**
- pub.dev / ai_barcode_scanner — version 7.1.0 (rejected) — **HIGH**
- pub.dev / custom_qr_generator — version 0.1.2, 3 years stale (rejected) — **HIGH**
- docs.wompi.co/en/docs/colombia/eventos-pagos-a-terceros — webhook signature verification algorithm (SHA256 of ordered properties + timestamp + events_secret) — **HIGH**
- docs.wompi.co/en/docs/colombia/widget-checkout-web — integrity hash formula (SHA256 of reference + amountInCents + currency + integrity_secret), Web Checkout vs Widget — **HIGH**
- docs.wompi.co/en/docs/colombia/transacciones — payment_method.type values (CARD, NEQUI, PSE, BANCOLOMBIA_TRANSFER, DAVIPLATA, BANCOLOMBIA_COLLECT), Bearer private_key auth — **HIGH**
- Wompi base URLs (sandbox.wompi.co/v1, production.wompi.co/v1) — **HIGH** (multiple official-doc sources)

---
*Stack research for: Flutter QR app + Colombia marketplace milestone*
*Researched: 2026-05-01*
