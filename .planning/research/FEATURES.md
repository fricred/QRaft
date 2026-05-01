# Feature Research

**Domain:** QR generation + scanner + Colombian e-commerce + custom on-demand laser-engraved physical products (single-seller marketplace)
**Researched:** 2026-05-01
**Confidence:** HIGH for QR generation/scanner table stakes (verified across multiple competitor docs); HIGH for Colombian payment methods (Wompi docs + multiple Colombian payment guides); MEDIUM for custom-product preview UX (industry references but tool-specific patterns vary); MEDIUM for marketplace timeline UX (general pattern documented, Colombia-specific norms inferred).

---

## Feature Landscape — Domain 1: QR Generation

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| QR types: URL, plain text, vCard, WiFi, Email, SMS, Phone | Every QR generator (QR TIGER, Uniqode, ME-QR, QRCode Monkey) supports these as baseline | LOW | `qr_flutter ^4.1.0` covers content; type-specific encoding is data-formatting only (MECARD, vCard 3.0, WIFI:S:...;T:WPA;P:...;). Maps to PROJECT QR-01. |
| Logo embedding with white halo + EC level H | Standard since 2020; users assume QRs can carry brand logo. EC-H tolerates ~30% obstruction enabling 20-25% logo coverage | LOW | Compose at render time: paint QR → paint white circle/rounded rect → paint logo. Force `errorCorrectLevel: QrErrorCorrectLevel.H`. Maps to QR-02. |
| Foreground/background color | Trivial baseline across all generators | LOW | Avoid low contrast (warn users when contrast ratio < 3:1). |
| Export as PNG (high-res) | Sharing/printing requires raster. JPEG also acceptable but PNG preserves crisp edges | LOW | `RenderRepaintBoundary.toImage(pixelRatio: 4-8)` for print-quality output. |
| Save QR to user library | Users return to retrieve/reuse past QRs | MEDIUM | Maps to QR-08. Requires Supabase persistence + offline cache. |
| Share via system share sheet | Standard mobile pattern (URL, image, both) | LOW | `share_plus ^7.2.1` already in stack guidelines. Maps to QR-09. |
| Static QR (no backend tracking) | Free baseline expected by all users; required when content is sensitive (WiFi password) and shouldn't be hosted externally | LOW | Default mode. No server roundtrip for generation. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Module shapes + eye styles (rounded, circles, leaf, custom) | Visual identity beyond color; the differentiator that separates "free generator" from "design tool" — Beaconstac/Uniqode/QR TIGER all charge for this | MEDIUM | `qr_flutter` doesn't expose module shape API; need custom painter or fork. Maps to QR-04. **Flag for deeper research at phase build time.** |
| Linear + radial gradients on modules | Premium look; ME-QR and Uniqode's "Auto Design" both lean on this | MEDIUM | Custom painter w/ `Shader.linearGradient`. Apply only to body modules, not finder patterns (preserves contrast). Maps to QR-03. |
| CTA frames ("Scan me", "Visit", "Open menu") | Documented to increase scan rates ~30% per QR TIGER/Uniqode marketing data | LOW-MEDIUM | Composite frame around QR canvas; localizable strings (es/en). Maps to QR-05. |
| Curated template gallery | Lowers cognitive load — users pick instead of design from blank. Strong onboarding hook | MEDIUM | Templates as JSON manifests + thumbnail in Supabase Storage. Maps to QR-06. |
| Tight digital→physical loop (this is QRaft's differentiator) | No major QR-gen competitor closes the loop. ME-QR/Uniqode are SaaS-only | HIGH | Per PROJECT.md Core Value. The marketplace integration IS the moat. |
| Offline generation | Privacy + works on airplanes; native Apple Camera offers it for scan but not gen | LOW | All static-QR rendering is local; ensure no telemetry on generate. |
| AI-stylized QR (Stable Diffusion artistic backgrounds) | Trending late 2024-2026 (OpenArt, Quick QR Art, QR Code AI). Visually striking but scannability-fragile | HIGH | **Defer to v2.** Requires server-side ML inference and per-image scannability validation. High novelty value but risks: ~10-15% of generated codes fail real-world scanning. Track as competitive watchlist item. |
| Dynamic QR (server-redirected, trackable, editable post-print) | Killer feature for businesses; ME-QR, Uniqode, Beaconstac monetize this heavily | HIGH | Edge function on Supabase resolves short URL → target. Requires hosted domain, link analytics, dashboard. **Defer to v1.x.** Doesn't fit retail-consumer-buying-physical-QR persona. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Animated QR (GIF/video) | "Cool" factor on social media | Cannot be physically engraved; conflicts with QRaft's core loop. Cameras/phones in 2026 don't reliably scan animated content (frame-rate timing) | Static QR with motion-suggesting visuals (gradient frames) — preserves engravability |
| Scan tracking analytics on every QR | "Businesses want metrics" | Requires hosted dynamic redirect; conflicts with "user owns their QR" privacy stance; static QRs once printed cannot be edited | Offer dynamic-QR as optional power-user tier in v1.x; v1.0 stays static-only |
| AI-generated artistic backgrounds (v1) | Trending 2025-2026 | Scannability is unreliable; failed scans = bad reviews + refund requests when engraved on $30 product | Defer to v2; meanwhile offer 8-12 hand-curated templates that are guaranteed scannable when engraved on each material |
| Bulk CSV import (B2B power feature in v1) | "What if a business wants 100 QRs?" | Conflicts with retail-consumer persona stated in PROJECT.md; UX for bulk on mobile is poor; QR-07 in PROJECT marks this active but recommend deprioritizing | Keep QR-07 in scope but build minimal — single CSV upload, no per-row preview UI; B2B accounts deferred to v2 per PROJECT Out-of-Scope |
| Password-protected QRs | "Privacy" sounding | Requires server-side gating = dynamic QR; defeats "I print it on wood" use case (scanner sees gibberish without the redirect) | Educate via UI: don't print sensitive data; offer encrypted-payload as v2 advanced option |
| AR overlays on scanned QRs | "Future-forward" demo appeal | Requires AR runtime (ARKit/ARCore), 3D content management, niche audience | Skip entirely; out of scope for retail QR-merchandise app |

---

## Feature Landscape — Domain 2: QR Scanner

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Auto-detect QR (no shutter button) | Native iOS/Android camera handles this; users punish slow apps | LOW | `mobile_scanner ^3.5.7` does this natively; debounce repeated scans of same code (300-500ms). Maps to SCAN-01/SCAN-02. |
| Sub-2-second scan from camera open | Native camera benchmark; if slower, users abandon | MEDIUM | Pre-warm scanner controller; don't block on permission dialog UX. **Tied to OPT-01 performance gate.** |
| Type-aware actions (URL → open, vCard → save contact, WiFi → connect, Email → compose) | Standard since 2020; native cameras handle all these | MEDIUM | Per-type handler module; iOS WiFi auto-connect needs `NEHotspotConfiguration` (added complexity). vCard via `flutter_contacts`. Maps to SCAN-04. |
| Scan history (persistent, local + cloud sync) | Users come back to look up "what did I scan yesterday" | LOW | `scan_history` table already exists per PROJECT.md (migration `20250725122236`). Maps to SCAN-03. |
| Flashlight / torch toggle | Low-light conditions are common; native camera supports it | LOW | `mobile_scanner` MobileScannerController has `toggleTorch()`. |
| Scan from gallery image | Indoor-poster screenshots, received QRs in messages | LOW | `mobile_scanner` `analyzeImage(path)` API. |
| Camera permission with clear pre-prompt | iOS 2024+ rejection-rate cliff if rationale isn't shown first | LOW | Pre-prompt screen explaining why → request system permission. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Privacy-first stance (no telemetry on scans, history is user-owned) | Differentiator vs ad-supported scanner apps that exfiltrate scan data. Aligns with QRaft's premium brand | LOW | Already aligns with "AdMob for free users only" model. Document explicitly in privacy policy. |
| URL safety check before opening | Free apps like Gamma Play monetize this; users care after one phishing scare | MEDIUM | Local heuristics (suspicious TLDs, non-ASCII tricks, IP-as-host) + optionally Google Safe Browsing API. **Flag for v1.x.** |
| "Scan to add to QRaft library" — direct loop into generator | Unique to QRaft: scan a competitor's QR → instantly create your own beautiful version | LOW-MEDIUM | Reverses the typical scan-flow; reuses scanned `parsed_data` JSON to pre-fill QR generator form. **High-leverage differentiator.** |
| Scan to order — "convert this content to physical QR" | Bridge from scanner directly into marketplace flow with content pre-filled | MEDIUM | Combines SCAN + QR-08 + MKT-01. **Strongly aligned with Core Value.** |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Barcode scanning (EAN, UPC, Code 128) | "While we're at it..." | Doubles scope (UPC databases, product lookups); pulls focus from QR-merchandise positioning | `mobile_scanner` supports barcodes natively but **don't build product-lookup features**. If user scans barcode, show raw + copy/share, no UPC database. |
| Continuous batch-scan mode | "Power users want it" | Edge case for retail consumer persona; UI complexity for queue management | Defer; if requested post-launch, reconsider |
| AR scanner overlays | "Wow factor" | Niche, ARKit/ARCore complexity, low scan-success-rate in AR mode | Skip |
| Scan-to-translate / scan-to-explain (AI) | AI hype | Off-mission; high LLM cost; latency conflicts with sub-2s scan | Skip in v1; possibly v2 for vCard data enrichment |

---

## Feature Landscape — Domain 3: Colombian E-Commerce Marketplace (Single-Seller)

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Product catalog with filters (material, size, price) | Mercado Libre / Falabella standard | MEDIUM | Catalog by material × size matrix; persist in Supabase `products`. Maps to MKT-01. |
| Product detail with realistic preview | User must see what they're buying before $30-100 commitment | MEDIUM-HIGH | Composite render: product photo + user's QR overlaid on engraving area with material-appropriate filter (wood = darken, metal = invert lightness, acrylic = white outline). Maps to MKT-02. |
| Persistent cart across sessions | Standard e-comm; user adds to cart → checks finance → returns next day | LOW | Supabase row keyed to user_id; sync local Hive/SharedPreferences when offline. Maps to MKT-03. |
| Shipping address with departamento + ciudad picker | Colombia has 32 departamentos + 1100+ municipios; flat city input fails | MEDIUM | Static dataset (ships with app, ~50KB JSON) of departamentos→municipios. Maps to MKT-04. |
| IVA 19% calculation displayed in cart | Colombian law: prices can be IVA-included or IVA-excluded but must be transparent. Users distrust hidden fees | LOW | Compute on cart total; show line: `Subtotal / IVA 19% / Envío / Total`. Maps to MKT-03. |
| Wompi checkout: tarjeta + PSE + Nequi + Daviplata | The four payment rails dominate Colombian e-commerce per Mercado Libre, Falabella, multiple payment-gateway guides | HIGH | Wompi Web Checkout via WebView OR Widget for in-app. Webhooks for confirmation. Maps to MKT-05/MKT-06. **Flag for deep phase research.** |
| Order list + order detail | "Where's my order?" is the most-asked question in any e-comm | LOW-MEDIUM | Maps to MKT-07. Standard FlatList → detail nav. |
| Order status timeline (recibido → producción → grabando → listo → enviado → entregado) | Lead time is multi-day for custom products; users need transparency to manage expectations | MEDIUM | Visual timeline component. Statuses are admin-driven (manual ops per PROJECT). Maps to MKT-08. |
| Push notifications on status change | FCM standard; users disable email but keep push | MEDIUM | FCM topics per order; Supabase trigger sends push on status update. Maps to MKT-09. |
| Order confirmation email (PDF receipt) | Colombian law requires factura electrónica delivery — DIAN-compliant XML+PDF for B2C transactions | MEDIUM-HIGH | DIAN factura electrónica is **mandatory** for VAT-registered businesses since Nov 2020. Requires DIAN integration (or third-party billing provider like Alegra, Siigo, Facturación Electrónica). **Flag for compliance research at MKT phase.** Confidence: HIGH (DIAN.gov.co confirmed). |
| Estimated delivery date / lead time visible | Custom-product apps (Etsy, Zazzle) all show "ships in 3-5 business days" prominently. Sets expectations, reduces support load | LOW | Per-product `lead_time_days` field on `products`; compute displayed date. |
| Order cancellation window (before "in production") | Standard e-comm; legally required in Colombia (10-day right to retract per Estatuto del Consumidor for online sales) | LOW-MEDIUM | Conditional cancel button when status ∈ {recibido, en_cola}. Refund workflow via Wompi reverse-payment API. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Live preview of user's actual QR on actual chosen material before checkout | No competitor in this niche does this. Mercado Libre/Falabella sell stock products; Etsy laser engravers email mockups manually | MEDIUM-HIGH | Already MKT-02 in PROJECT. Material-specific compositing. Critical for conversion + reducing refund rate. |
| Real-time order timeline with operator-uploaded engraving progress photo | "Look, here's your QR being engraved" — emotional engagement during the multi-day wait | MEDIUM | Admin uploads photo at "grabando" status → user gets push w/ image. Strong WhatsApp-shareable moment. |
| WhatsApp delivery notifications (Colombia is WhatsApp-first) | Colombians check WhatsApp more than email; Mercado Libre tested this and bumped engagement | MEDIUM | WhatsApp Business API or a reseller (Yalochat, Treble.ai). **Flag for v1.x — adds compliance + cost.** |
| In-app PQRS (Peticiones, Quejas, Reclamos) flow | Colombian consumer-protection norm. Falabella/Mercado Libre have dedicated PQRS surfaces | LOW-MEDIUM | Form → Supabase ticket → email/push to ops. Important for legal compliance and trust. |
| Premium tier removes ads + unlocks advanced QR styles | Already MKT-10 in PROJECT; clear monetization complement to AdMob | MEDIUM | Stripe/Wompi subscription. Premium gates: gradient styles, eye custom shapes, AI templates v2. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Multi-vendor seller onboarding | "Marketplace" semantically suggests it; per PROJECT.md QRaft is single-seller | Massive scope (seller dashboards, KYC, payouts, dispute resolution). PROJECT.md explicitly lists this as Out-of-Scope | Stay single-seller in v1.0; revisit in v2 only if validated demand |
| Cross-border / multi-currency | "Why limit to Colombia?" | Wompi is COP-only; multi-currency demands separate payment processor (Stripe), tax engines, customs. PROJECT.md explicitly Colombia-only v1.0 | Defer to v2 per PROJECT Out-of-Scope |
| Buyer-to-buyer chat | "Like Mercado Libre" | Single-seller — there's no other buyer to chat with. Customer-to-merchant is what's needed | Build user-to-support contact form (PQRS) instead |
| Reviews/ratings system | Standard e-comm | Single-seller means reviews of yourself = self-reported = low trust signal. Amazon/Mercado Libre work because of vendor diversity | Consider testimonials/case-studies on marketing site instead. If reviews ship in v1, accept they're vanity. |
| Wishlists / favorites | "Standard e-comm feature" | For 6-product catalog (6 materials × few sizes) wishlists are overkill | Skip until catalog grows past ~30 SKUs |
| Loyalty points / rewards | "Drives repeat purchases" | Custom QR isn't a repeat-purchase product; users buy 1-3 lifetime. Different mental model than groceries | Skip; refer-a-friend discount is more aligned |
| Subscription boxes / recurring orders | E-comm trend | Doesn't fit "I want a custom QR engraved on wood" — non-consumable | Skip |
| Real-time chat with operator during production | "Modern UX" | XTool F1 Ultra ops are manual per PROJECT; one operator can't field synchronous chat at scale | Async messaging tied to specific order, polled every 10-30 min |
| Complex configurator with 10+ options per product | "Power user customization" | Etsy's anti-pattern — overwhelms 80% of buyers, increases abandonment | 3 axes max: material, size, QR-style preset. Anything more lives in QR-generation phase |

---

## Feature Landscape — Domain 4: Custom On-Demand Physical Product (Laser Engraving)

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Live preview of user customization on product | Every Zazzle/Etsy custom listing shows mockup before purchase. Users don't trust without it | MEDIUM-HIGH | Per-material compositing pipeline (PNG QR → applied to product photo with material-appropriate transformation). Same as MKT-02. |
| Material-specific scannability validation | If engraved QR doesn't scan, refund + reputation damage. Cannot ship a non-functional QR | MEDIUM | Pre-render QR + simulate engraving contrast (e.g., wood = ~60% contrast vs paper = 100%); reject low-contrast color combos for that material. **Critical for refund rate.** |
| Size options with physical dimensions in cm | Colombian users think in cm/mm not inches; need real-world reference (compared to credit card or coin) | LOW | Each product variant: `size_cm: {w, h}`. Render scale-comparison thumbnail. |
| Lead time clearly stated per product | Etsy/Zazzle anti-pattern is hiding lead time. Users abandon when they discover at checkout | LOW | Per-variant `lead_time_days`. Show on PDP, cart line item, and order confirmation. |
| Material specs (origin, finish, durability) | $30-100 product needs justification. Users research before commit | LOW | Markdown content on PDP; reused across listings of same material. |
| What happens if QR doesn't scan after engraving (refund/remake policy) | Inherent risk of custom = customer needs trust signal | LOW | Static policy page + checkout footer. Critical trust signal for repeat purchase. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Side-by-side digital QR vs engraved preview | Closes "will it look like the screen?" loop. Especially valuable for darker materials (cuero, metal) where contrast shifts | MEDIUM | Two-up image on PDP. Backed by photographed real samples, not synthesized. |
| Scannability guarantee badge ("guaranteed to scan or remake free") | Explicit anti-anxiety messaging. Used by Crystal Clear Memories and similar custom-product brands | LOW | Marketing + ops policy. No tech build. |
| 3D rotatable preview | Competitors (Zazzle) use 2D photo. 3D is "wow" factor | HIGH | Requires 3D models per material (modeled or photogrammetry-scanned). model_viewer Flutter package supports glTF. **Defer to v1.x — high cost vs MKT-02 2D preview.** |
| AR try-on ("hold up your phone to see QR coaster on your table") | Bleeding-edge custom-product UX (IKEA Place / Wayfair pattern) | HIGH | Requires AR Foundation + AR-anchor + per-product 3D asset. **Defer to v2.** Out of scope per PROJECT for v1. |
| Material sample bundles (low-cost intro product) | Lower bar to first purchase; user can hold real samples before bigger commit | LOW | Adds 1 SKU. Operations-light. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Free-form configurator (any color, any size, any material combo) | "Maximum personalization" | Combinatorial explosion in production planning; XTool F1 Ultra has fixed materials + fixed engraving area. Overwhelms users (Etsy custom listings often have 7+ dropdowns and 60% abandon) | 3-axis matrix: material × size × QR-style. Curated, validated, fast |
| Photo-to-engraving (upload photo, we engrave it) | Adjacent product idea | Off-mission per PROJECT (QR-only); photo engraving has different quality controls + IP concerns | Skip; if validated, separate product |
| Engraving-area free-position / rotation | "Why is QR centered only?" | Each off-center position requires re-validating scannability + production photo. 50+ photos per product becomes unmanageable | Center-only in v1; offer 2-3 fixed positions in v1.x if requested |
| User-uploaded fonts / text alongside QR | "Cool, add my name" | Multiplies design-validation burden; QR readability impacted by adjacent text | Defer; offer 2-3 fixed CTA frames (already QR-05) |
| Pre-engraving designer-approval flow ("show me a proof, I'll approve") | Etsy-style hand-crafted vibe | Adds 1-2 days lead time + ops overhead; conflicts with "smooth retail flow" | Trust the live preview from MKT-02; if user disputes after delivery, offer remake under guarantee |
| Material customization (e.g., "stain this wood darker") | Retail demand for personalization | Makes catalog combinatorial; XTool F1 Ultra doesn't stain — separate process | Curate 1-2 finish variants per material in catalog |

---

## Feature Dependencies

```
[Auth] (existing)
   |
   v
[QR Generation: types, colors, logo]  <-- Foundation for everything
   |    \
   |     \---> [QR Library (saved QRs)] <--- [Scanner] (scan-to-save)
   |              |
   |              v
   v        [Marketplace: catalog + cart]
[QR Customization: gradients, eyes, frames]
              |
              v
       [Live Product Preview (QR + material composite)]
              |
              v
       [Address Picker (departamento/ciudad)]
              |
              v
       [Wompi Checkout (PSE/Nequi/Daviplata/tarjeta)]
              |
              v
       [Webhook + Order Creation]
              |
              v
       [Order Detail + Timeline]
              |
              v
       [FCM Push Notifications]

[Templates Gallery] --enhances--> [QR Generation]
[Premium Tier]      --gates---->  [Advanced QR Styles + Ad-free]
[DIAN Factura]      --required-->  [Order Confirmation]
[PQRS Module]       --required-->  [Order Detail]   (legal compliance Colombia)
```

### Dependency Notes

- **Live Product Preview (MKT-02) requires QR Customization complete:** preview is composite of finalized QR + material image; if user can still edit colors at preview-time, must re-render. Build customization first, then preview.
- **Wompi Checkout requires Address Picker + IVA calc:** Wompi Widget posts a complete amount including taxes; back-fill address validation before payment intent.
- **Order Timeline requires Webhook handling + Notifications:** status changes flow Wompi → Edge Function → Supabase → FCM push. Must be reliable end-to-end before launch.
- **DIAN Factura Electrónica is a hard legal blocker for any VAT-registered seller:** cannot launch a paid marketplace without DIAN integration. Investigate Alegra/Siigo/Facturación Electrónica integration in MKT phase.
- **Scanner (mobile_scanner) currently blocked on iOS dependency** per PROJECT CONCERNS. Resolve before SCAN phase begins.
- **Templates Gallery enhances but doesn't block QR Generation:** can ship QR without templates and add curated templates in v1.0 polish phase.
- **Premium Tier (MKT-10) gates content but no hard dependency:** flag certain QR styles + remove ads. Build infrastructure once advanced QR styles exist.
- **AR / 3D preview conflict with simplicity:** if 3D preview is built, the 2D fallback for low-end Android (per OPT-01 "60fps on Android low-end") becomes mandatory. Adds 2x art-asset cost.

---

## MVP Definition

### Launch With (v1.0 — per PROJECT.md scope)

Maps to PROJECT.md Active requirements. Ruthless cut: only features that close the digital→physical loop.

**QR Generation & Customization:**
- [ ] QR types: URL, text, vCard, WiFi, eventos, ubicación (QR-01) — **table stakes; no QR app without these**
- [ ] Logo embedding with EC-H + white halo (QR-02) — **table stakes for branded QRs**
- [ ] Color + gradient customization (QR-03) — **differentiator vs free generators**
- [ ] Module + eye styles (QR-04) — **differentiator + visual identity**
- [ ] CTA frames (QR-05) — **table stakes for printed QR; documented scan-rate boost**
- [ ] 8-12 curated templates (QR-06) — **onboarding hook; reduces blank-canvas paralysis**
- [ ] User QR library (QR-08) — **table stakes for "save my work"**
- [ ] Share QR (QR-09) — **table stakes mobile feature**

**QR Scanner:**
- [ ] mobile_scanner iOS unblocked (SCAN-01) — **prerequisite, not feature**
- [ ] Full-screen scanner with overlay (SCAN-02) — **table stakes UX**
- [ ] Persistent scan history (SCAN-03) — **table stakes**
- [ ] Type-aware actions for URL/vCard/WiFi/Email/Phone/SMS (SCAN-04) — **table stakes**
- [ ] Privacy-first (no scan telemetry) — **brand differentiator + low cost**
- [ ] Scan-to-library bridge (scan → create QR from same content) — **unique to QRaft**

**Marketplace:**
- [ ] Product catalog with material/size filter (MKT-01)
- [ ] Live preview of user's QR on selected material (MKT-02) — **critical differentiator + refund-prevention**
- [ ] Persistent cart with IVA breakdown (MKT-03)
- [ ] Shipping address picker for Colombia departamento/municipio (MKT-04)
- [ ] Wompi checkout: tarjetas + PSE + Nequi + Daviplata (MKT-05)
- [ ] Wompi webhook handling (MKT-06)
- [ ] Order list + detail (MKT-07)
- [ ] Status timeline (MKT-08)
- [ ] FCM push on status change (MKT-09)
- [ ] DIAN factura electrónica integration — **legally required for VAT-registered businesses**
- [ ] PQRS form — **legally required Colombian consumer protection**
- [ ] Cancel-before-production flow — **legally required (Estatuto del Consumidor 10-day retract)**

**Cross-cutting:**
- [ ] Performance gates per OPT-01
- [ ] Visual polish per OPT-02
- [ ] Crashlytics + analytics + payment monitoring per OPT-03
- [ ] Premium tier (MKT-10) — defer to v1.x if timeline tight; gate is monetization, not user-facing must-have

### Add After Validation (v1.x)

- [ ] **URL safety check on scan** — adds value once scanner usage data shows users care
- [ ] **WhatsApp order notifications** — Colombians check WhatsApp more than email; high-engagement payoff. Adds compliance + WhatsApp Business API cost
- [ ] **3D rotatable product preview** — visual upgrade once 2D preview validates the loop
- [ ] **Material sample bundle SKU** — lower-friction first purchase to drive trial
- [ ] **Operator-uploaded engraving progress photo at "grabando" status** — emotional engagement; needs ops UX + image upload
- [ ] **Bulk CSV QR generation (QR-07)** — keep as v1.0 per PROJECT but build minimal; expand only on demand
- [ ] **Refer-a-friend discount** — low-cost retention; replaces typical loyalty-points anti-feature
- [ ] **Premium tier (MKT-10) if deferred from v1.0**
- [ ] **Dynamic QR (server-redirected, trackable)** — power-user upgrade if business segment emerges

### Future Consideration (v2+)

- [ ] **AR try-on ("see QR coaster on your table")** — high cost, niche payoff
- [ ] **AI-stylized QRs (Stable Diffusion artistic backgrounds)** — scannability risks too high for engraved products in v1
- [ ] **Multi-vendor seller onboarding** — explicitly out-of-scope per PROJECT
- [ ] **Multi-country / multi-currency** — explicitly out-of-scope per PROJECT
- [ ] **B2B wholesale dashboards** — explicitly out-of-scope per PROJECT
- [ ] **Photo-to-engraving** — adjacent product, off-mission
- [ ] **XTool F1 Ultra direct API integration** — explicitly out-of-scope per PROJECT (manual ops in v1)
- [ ] **Reviews/ratings (single-seller makes this vanity)** — reconsider only post-multi-vendor decision
- [ ] **Animated/video QRs** — incompatible with engraving core loop

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| QR generation core types (URL/vCard/WiFi/etc.) | HIGH | LOW | P1 |
| Logo embed + EC-H | HIGH | LOW | P1 |
| Color + gradient | HIGH | MEDIUM | P1 |
| Module + eye custom shapes | HIGH | MEDIUM | P1 |
| CTA frames | MEDIUM | LOW | P1 |
| Template gallery | MEDIUM | MEDIUM | P1 |
| QR library (save/edit/duplicate) | HIGH | MEDIUM | P1 |
| Share QR | HIGH | LOW | P1 |
| Scanner full-screen + auto-detect | HIGH | LOW (after iOS dep fix) | P1 |
| Scanner type-aware actions | HIGH | MEDIUM | P1 |
| Scan history | HIGH | LOW | P1 |
| Scan-to-library bridge | HIGH (unique) | LOW-MEDIUM | P1 |
| Catalog with filters | HIGH | MEDIUM | P1 |
| Live product preview (QR + material) | HIGH (unique) | MEDIUM-HIGH | P1 |
| Cart with IVA breakdown | HIGH | LOW | P1 |
| Address picker Colombia | HIGH | MEDIUM | P1 |
| Wompi checkout (PSE/Nequi/Daviplata/card) | HIGH | HIGH | P1 |
| Wompi webhooks | HIGH | MEDIUM | P1 |
| Order list/detail/timeline | HIGH | MEDIUM | P1 |
| FCM push on status | HIGH | MEDIUM | P1 |
| DIAN factura electrónica | HIGH (legal) | HIGH | P1 |
| PQRS form | MEDIUM (legal) | LOW | P1 |
| Cancel-before-production | MEDIUM (legal) | LOW-MEDIUM | P1 |
| Premium tier (ad-free + advanced styles) | MEDIUM | MEDIUM | P1/P2 |
| Bulk CSV QR (B2B-lite) | LOW (retail persona) | MEDIUM | P2 |
| URL safety check on scan | MEDIUM | MEDIUM | P2 |
| WhatsApp notifications | HIGH (Colombia) | HIGH | P2 |
| Operator engraving-progress photo | MEDIUM (emotional) | LOW (ops) + LOW (app) | P2 |
| 3D product preview | MEDIUM | HIGH | P2 |
| Material sample bundle | MEDIUM | LOW | P2 |
| Refer-a-friend | MEDIUM | LOW-MEDIUM | P2 |
| Dynamic QR (server-redirect/tracking) | MEDIUM (B2B) | HIGH | P3 |
| AI-stylized QR | LOW (risk vs value) | HIGH | P3 |
| AR try-on | LOW | HIGH | P3 |
| Animated QR | LOW (anti-aligned) | MEDIUM | NEVER |
| Multi-vendor sellers | NEGATIVE for scope | VERY HIGH | NEVER (scope-locked) |

**Priority key:**
- P1: Must have for v1.0 launch
- P2: Should have for v1.x post-validation
- P3: Future consideration v2+
- NEVER: Anti-feature; documented to prevent re-discussion

---

## Competitor Feature Analysis

| Feature | QR TIGER / Uniqode | ME-QR | Etsy custom-engraving sellers | Mercado Libre / Falabella | QRaft Approach |
|---------|--------------------|---------|------------------------------|----------------------------|----------------|
| QR types coverage | 24-31 types each | 20+ types | N/A | N/A | 6 types (URL/text/vCard/WiFi/event/location) — focused subset for retail |
| Logo embedding | Yes, EC-H | Yes | N/A | N/A | Yes, EC-H + white halo (PROJECT QR-02) |
| Module + eye custom styles | Premium tier | Free | N/A | N/A | Free in v1 (differentiator vs SaaS-locked) |
| AI-stylized QR | Add-on (Uniqode "Auto Design") | Some | N/A | N/A | Defer v2 — scannability risk for engraving |
| Dynamic QR + analytics | Core monetization | Core monetization | N/A | N/A | Defer v1.x — wrong persona for v1 |
| Scanner | Web-only, weak | Mobile app | N/A | N/A | First-class mobile feature (mobile_scanner) |
| Scan history | Limited | Yes | N/A | N/A | Yes, persistent + cloud sync |
| Privacy-first stance | No (telemetry-heavy) | No | N/A | N/A | **Yes — differentiator** |
| Live product preview | N/A | N/A | Manual mockup email | Stock-product photos only | **First-class — Core Value differentiator** |
| Material variety (custom physical) | N/A | N/A | Vendor-by-vendor | Limited custom | 6 materials curated for XTool F1 Ultra |
| Catalog filters | N/A | N/A | Etsy global filters | Strong filters | Material × Size × Price filters |
| Wompi (Colombia native) | N/A | N/A | Etsy doesn't support | Mercado Pago native | **Wompi native — locked decision** |
| PSE / Nequi / Daviplata | N/A | N/A | No | Yes | Yes (table stakes for Colombia) |
| Address: departamento + municipio | N/A | N/A | N/A | Yes | Yes (table stakes) |
| Order timeline transparency | N/A | N/A | Per-seller varies | Yes | Yes — granular custom-production states |
| FCM push on status | N/A | N/A | Email-heavy | Yes | Yes |
| WhatsApp notifications | N/A | N/A | Per-seller | Some | Defer to v1.x |
| DIAN factura electrónica | N/A | N/A | N/A | Yes (legally required) | Yes (legally required) |
| PQRS module | N/A | N/A | N/A | Yes | Yes |
| 10-day retract / cancel-before-production | N/A | N/A | Per-seller | Yes | Yes |
| Single seller vs multi-vendor | SaaS, single-tenant | SaaS | Multi-vendor (Etsy) | Multi-vendor | **Single-seller — locked** |
| Native mobile app | Web-first; weak apps | Yes | Web-first | Yes | **Mobile-first** |

---

## Sources

### QR Generation
- [QR TIGER vs Uniqode comparison](https://www.qrcode-tiger.com/qrtiger-vs-beaconstac) — feature parity baseline (HIGH confidence)
- [Best QR Code Apps Compared](https://www.qr-code-generator.com/blog/best-qr-code-apps/) — competitive landscape (HIGH)
- [Best Dynamic QR Code Platforms 2026](https://qrforever.com/blog/best-dynamic-qr-code-generator-2026) — dynamic QR landscape (MEDIUM, marketing source)
- [Uniqode Dynamic QR Code Generator](https://www.uniqode.com/dynamic-qr-code-generator) — dynamic QR feature set (HIGH, official)
- [QR Code Customization: 12 Design Elements (Scanova)](https://scanova.io/blog/qr-code-customization/) — eye styles, module shapes (MEDIUM)
- [QR Code Design — Uniqode](https://www.uniqode.com/qr-code-generator/custom-qr-code) — design options (HIGH)
- [QRCode Monkey](https://www.qrcode-monkey.com/) — free reference for design options (HIGH baseline)
- [QR Code AI Art Generator (HuggingFace)](https://huggingface.co/spaces/huggingface-projects/QR-code-AI-art-generator) — AI-stylized QR scope (HIGH)
- [Quick QR Art](https://quickqr.art/) — AI-stylized QR commercial product (MEDIUM)
- [AR Code](https://ar-code.com/) — AR-QR scope reference (MEDIUM)

### QR Scanner
- [7 Best QR Code Scanner Apps in 2026 (Uniqode)](https://www.uniqode.com/blog/qr-code-basics/best-qr-code-scanner-apps) — table-stakes feature list (HIGH)
- [Safest QR Code Scanner Apps (Iron Software)](https://ironsoftware.com/csharp/qr/blog/qr-tools/safest-qr-code-scanner-app/) — privacy-first scanner positioning (MEDIUM)
- [Privacy Friendly QR Scanner (KIT Secuso)](https://secuso.aifb.kit.edu/english/QR_Scanner.php) — open-source privacy-first reference (HIGH academic)
- [Best QR Code and Barcode Scanner Apps 2025](https://www.the-qrcode-generator.com/blog/best-qr-code-scanner-apps) — feature comparison (MEDIUM)

### Colombian E-Commerce + Payments
- [Mercado Libre Colombia — Medios de pago](https://www.mercadolibre.com.co/l/mediosdepago) — payment-method baseline (HIGH, official)
- [Pasarelas de pago en Colombia (Tiendanube)](https://www.tiendanube.com/blog/pasarelas-de-pago-colombia/) — payment-gateway landscape (MEDIUM)
- [Wompi Widget & Checkout Web docs](https://docs.wompi.co/en/docs/colombia/widget-checkout-web/) — checkout integration (HIGH, official)
- [Wompi Transaction Tracking](https://docs.wompi.co/en/docs/colombia/seguimiento-de-transacciones/) — order/payment tracking (HIGH, official)
- [Wompi Events / Webhooks](https://docs.wompi.co/en/docs/colombia/eventos-pagos-a-terceros/) — webhook lifecycle (HIGH, official)
- [DIAN Factura Electrónica (official)](https://www.dian.gov.co/impuestos/factura-electronica/factura-electronica/Paginas/default.aspx) — Colombian e-invoicing requirement (HIGH, government)
- [Facturación Electrónica en Colombia (Invoway)](https://invoway.com/latam/blog/facturacion-electronica-colombia-guia/) — DIAN integration overview (MEDIUM)
- [Cómo pagar por PSE con Nequi](https://ayuda.nequi.com.co/hc/es/articles/35211556821645) — payment-flow reference (HIGH, official Nequi)
- [Colombia eCommerce Country Guide (US Trade)](https://www-trade-gov.translate.goog/country-commercial-guides/colombia-ecommerce) — market data (HIGH, government)

### Custom Product / Engraving
- [Etsy laser engraving listings](https://www.etsy.com/market/laser_engraving) — custom-product UX patterns (MEDIUM)
- [Zazzle Product Templates](https://help.zazzle.com/hc/en-us/articles/219145288-Creating-a-Product-Template) — template-based custom-product approach (HIGH, official)
- [Zakeke Etsy customizer](https://www.zakeke.com/integrations/etsy/) — material-specific live preview (MEDIUM)
- [ImprintNext Laser Engraving Software](https://imprintnext.com/laser-engraving-software) — built-in 2D/3D preview (MEDIUM)
- [inkXE Laser Engraving](https://inkxe.com/laser-engraving-software/) — 3D preview reference (MEDIUM)
- [Crystal Clear Memories](https://www.crystalclearmemories.com/) — laser-engraved photo + live preview real-world example (MEDIUM)

### Single-Seller Marketplace UX
- [How to build a marketplace app (SolveIt)](https://solveit.dev/blog/how-to-build-a-marketplace-app) — feature catalog reference (LOW-MEDIUM, marketing)
- [Yokart marketplace features](https://www.yo-kart.com/yokart-multivendor-ecommerce-features.html) — feature catalog (LOW, vendor marketing)

---

*Feature research for: QRaft (QR generation/scanning + Colombian custom-laser-engraving marketplace)*
*Researched: 2026-05-01*
