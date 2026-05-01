# Pitfalls Research

**Domain:** Mobile QR generation/scanning + Colombian e-commerce + manual laser fulfillment (Flutter app)
**Researched:** 2026-05-01
**Confidence:** HIGH (Wompi/Colombian regulation/QR design — verified against official docs and ISO/IEC 18004 standard); MEDIUM (Flutter-specific edge cases — drawn from issue trackers and community reports)

This catalogue prioritizes pitfalls that are **specific to QRaft's risk surface**: branded QR design that must remain laser-engravable AND scannable, Wompi payment integration, manual fulfillment of physical orders, and Colombian regulatory compliance. Generic "test your code" advice is excluded.

---

## Critical Pitfalls

### Pitfall 1: Logo overlay larger than error correction can recover

**What goes wrong:**
A user adds a logo to the center of their QR (per `QR-02`). The logo covers ~30% of the QR area. With error correction level L (7%) or M (15%), the QR is unscannable. With H (30%), it's right at the edge — combined with print imperfections from laser engraving (`MKT-08` production phase), real-world scan rate drops below 70%.

**Why it happens:**
1. Defaults of QR libraries (e.g., `qr_flutter`) are typically M, not H
2. Designers visually pick logo size for aesthetics without computing covered module ratio
3. The 30% error correction budget is not "free space for logo" — it must absorb logo + dirt + scratches + the surface curvature of laser-engraved wood/leather

**How to avoid:**
- **Force error correction level H** for any QR with logo, frame, or color customization (no UI option for L/M/Q on logoed QRs)
- **Cap logo to ≤20% of total QR area** (safe working limit; H gives 30% recovery, leave 10% margin for engraving wear)
- **Center logo only** — never overlap finder patterns (the 3 corner squares) or alignment patterns
- **Apply white halo** behind logo (already in `QR-02`) — minimum 4-module padding around logo edge to preserve module readability
- **Reject logo upload** with explicit error if computed coverage > 20% rather than silently allowing it
- **Render-time validation** — after assembly, run an internal scan check (using `mobile_scanner` headless) before allowing save/checkout

**Warning signs:**
- Test scans succeed in well-lit lab but fail on engraved wood under store lighting
- Customer support tickets about "QR doesn't scan with iPhone camera"
- Marketplace return rate > 5% with "doesn't scan" reason

**Phase to address:** **QR Generation phase** (`QR-01`/`QR-02`/`QR-03`). Build the validation layer before unlocking customization.

---

### Pitfall 2: Inverted (light-on-dark) QR on Carden Pro dark theme

**What goes wrong:**
The app's dark-first design (#1A1A1A background, neon accents) tempts the team to render QR codes "natively" as white modules on dark canvas to match aesthetic. Per ISO/IEC 18004, scanners are programmed to detect *dark modules on light background* — many camera apps (older Android, iPhone Camera app on iOS < 13 in some configurations, Google Lens edge cases) silently fail to detect inverted finder patterns.

**Why it happens:**
1. Visual designers prioritize aesthetic harmony with dark theme
2. Some modern scanners DO support inversion, creating false confidence during dev testing on Pixel/recent iPhone
3. The QR preview in-app uses a sophisticated decoder (which handles inversion), masking that the *exported image* fails on consumer scanners

**How to avoid:**
- **Always render QR as dark-on-light** in the exported/printable artifact, regardless of in-app preview theme
- **Allow dark theme preview** (UI affordance) but hard-code export to dark foreground on light background
- **Show explicit "scan-ready" preview** before checkout that mimics light-on-light render conditions
- **For laser engraving**: use light material (light wood, white acrylic) with dark engraving as default; if user picks dark material (black acrylic), force a contrasting light-color engraving fill or warn explicitly that scan rate may degrade

**Warning signs:**
- "QR doesn't scan in iOS native Camera" reports while developer team scans fine with Google Lens
- User feedback "looks great but doesn't work"

**Phase to address:** **QR Customization phase** (`QR-03`). Bake the constraint in before coloring is unlocked.

---

### Pitfall 3: Frame/CTA clipping the quiet zone

**What goes wrong:**
`QR-05` adds a frame with "Scan me" CTA around the QR. A tight frame, or any frame *touching* the QR modules, violates the ISO/IEC 18004 4-module quiet zone requirement. Scanners can't reliably detect the QR boundary, causing intermittent scan failures that are hard to reproduce.

**Why it happens:**
1. Designers want compact, balanced compositions — a "tight" frame looks cleaner
2. The QR appears scannable on screen because backgrounds are uniform; in print/engraving, frame edges become physical boundaries that confuse scanners
3. Some QR libraries don't expose quiet zone padding as a configurable parameter

**How to avoid:**
- **Enforce minimum 4-module quiet zone** between any frame element and the QR modules (program-level constraint, not designer-discretion)
- **Frame must sit OUTSIDE quiet zone**, never inside or on the boundary
- **CTA text below the quiet zone**, not inside the QR area
- **Validate exported PNG/SVG** has white/material-base padding around modules equal to 4× module size before allowing save
- **Print/engrave testing**: include quiet-zone-violation test case in QA suite

**Warning signs:**
- Scan failures that disappear when user holds phone closer/further (variable working distance is a quiet-zone-violation tell)
- 2x scan attempt rate on framed QRs vs. unframed

**Phase to address:** **QR Customization phase** (`QR-05`). Quiet zone enforcement is a hard constraint, not a guideline.

---

### Pitfall 4: Custom eye styles break finder pattern detection

**What goes wrong:**
`QR-04` lets users style the 3 corner "eyes" (finder patterns) — circular dots, rounded squares, custom shapes. Scanners use these specific squares-within-squares geometry as the *first thing they look for*. Overly creative shapes (e.g., hearts, hexagons, asymmetric) cause some scanners to fail to lock on, even though the data modules are intact.

**Why it happens:**
1. Customization libraries make any shape easy — but ISO conformance demands the finder pattern preserve its 1:1:3:1:1 dark-light ratio
2. Designers test with permissive scanners (ZXing, Google Lens) which use heuristic recovery; iOS Camera app and many native scanners require strict conformance
3. Library presets may include non-conformant styles by default

**How to avoid:**
- **Curate eye-style presets** — only ship styles validated to scan on iOS Camera, Android default Camera, Google Lens, WeChat (a known-strict scanner)
- **Run a scanner-matrix CI test** for every preset shape on multiple scanner apps before adding to gallery
- **Disallow user-uploaded custom eye shapes** in v1.0 (only curated presets); revisit if scanner conformance can be validated programmatically
- **Always preserve the 1:1:3:1:1 ratio** — the geometry must read as concentric squares to a thresholded image, even if visually styled
- **Default to standard square eyes** — only show styled options as opt-in

**Warning signs:**
- Scan success rate varies by scanner app (>10% delta between iOS Camera and Google Lens)
- Specific eye-style preset has elevated complaint rate

**Phase to address:** **QR Customization phase** (`QR-04`). Build the test matrix as part of preset curation.

---

### Pitfall 5: Wompi webhook signature not validated → trusted forgery

**What goes wrong:**
Wompi sends transaction events to a webhook URL. The naive integration parses the JSON payload and updates order status to PAID. An attacker discovers the webhook URL (e.g., from network logs, error reporting) and forges a POST claiming `transaction.status = APPROVED` for any transaction ID. The order ships without payment.

**Why it happens:**
1. Documentation makes signature validation look "optional"
2. Developers test with valid Wompi events and conclude "it works"
3. The `X-Event-Checksum` header logic (concatenate fields → SHA256 with secret) is non-trivial and often skipped in MVP

**How to avoid:**
- **Mandatory: validate `X-Event-Checksum` SHA256 signature** on every webhook before acting on payload (Wompi spec: concatenate values from `signature.properties` array → append `timestamp` → append events secret → SHA256)
- **Implement on backend (Supabase Edge Function)**, never on client — secret must never reach the Flutter app
- **Reject any event without valid signature** — log and alert
- **Whitelist Wompi source IPs** at the edge if available (defense in depth)
- **Re-query Wompi `/transactions/{id}` to verify** before fulfilling — webhook is a *trigger*, the API is the source of truth
- **Use separate events secret from API keys** — Wompi provides this in the dashboard

**Warning signs:**
- Orders flipping to PAID without matching Wompi dashboard records
- Logs show events accepted with malformed/missing signature
- Reconciliation between internal DB and Wompi shows phantom PAID orders

**Phase to address:** **Marketplace/Payment phase** (`MKT-05`/`MKT-06`). This is non-negotiable for v1.0 — never ship payments without it.

---

### Pitfall 6: Double-charge from non-idempotent payment retries

**What goes wrong:**
User taps "Pay" on flaky network. The HTTP request to Wompi succeeds, but the response times out. The app retries. Wompi creates a *second* transaction. User is charged twice. Discovered when bank statement shows duplicate COP $89,000 charges.

**Why it happens:**
1. Mobile networks in Colombia (3G/edge in some regions) have high tail-latency requests
2. Default HTTP client behavior (Dio, http) retries on timeout
3. Wompi *does* support idempotency keys, but they must be explicitly sent — not on by default

**How to avoid:**
- **Generate idempotency key on order creation** (UUID v4, persisted with the cart) — same key on every retry for the same payment attempt
- **Send `Idempotency-Key` header on Wompi transaction creation** (Wompi keys expire in 24h — enforce ≤24h between retries)
- **Backend-orchestrated payment**: Flutter app calls Supabase Edge Function → Edge Function calls Wompi with idempotency key. App retries against the Edge Function (which dedupes) rather than directly against Wompi
- **Display "Payment in progress, do not close" UI** during the active payment window; disable retry button for 30s
- **Reconciliation job**: nightly compare Wompi transactions vs. internal orders, flag duplicates, auto-refund extras

**Warning signs:**
- Customer reports of double-charge even rare (1 in 1000)
- Wompi dashboard shows transactions with same amount, same user, within 60s
- Reconciliation drift between Wompi total and internal order total

**Phase to address:** **Marketplace/Payment phase** (`MKT-05`). Idempotency key plumbing must exist from day 1, not retrofit.

---

### Pitfall 7: Client-side payment confirmation when app is killed

**What goes wrong:**
User completes payment in Wompi widget/checkout. App backgrounded. iOS terminates the process (memory pressure / >30s background). Order never marked as PAID in app's local state. User reopens app, sees "Pending Payment" — and believes they need to pay again.

**Why it happens:**
1. Flutter/iOS will kill backgrounded apps aggressively — assume `Future` continuations won't run after a background event
2. Naive integration: app state machine drives order status (BAD)
3. Wompi return URL → deep link → app resumed, but confirmation logic never reaches "verify and update"

**How to avoid:**
- **Backend (Supabase) is the single source of truth** for order status, not the app
- **Order status updated only by webhook + verification call** to Wompi `/transactions/{id}` from Edge Function
- **App reads order status reactively** (Supabase Realtime subscription on `orders` table) — if app comes back, it sees updated status
- **Deep link return URL** triggers a re-fetch of order status, not a state update
- **Show "checking payment status..." UI** on resume, never assume client knowledge

**Warning signs:**
- Orders stuck in "Pending Payment" while Wompi shows APPROVED
- User support tickets about payments succeeding then "disappearing"

**Phase to address:** **Marketplace/Payment phase** (`MKT-05`/`MKT-06`). Architecture decision — must be set at design time.

---

### Pitfall 8: Operator forgets to update fulfillment status — orders go dark

**What goes wrong:**
Manual XTool F1 Ultra operation (per `MKT-08` and PROJECT.md "operación manual"). Order arrives → operator engraves → ships → forgets to update status from "in production" to "shipped" in admin panel. User sees stale status for days. Trust erodes. Support requests spike.

**Why it happens:**
1. Operator's primary job is laser operation, not data entry
2. No SLA on status update timing
3. No visibility tools for the operator to see "stale" orders
4. No fallback automation if operator drifts

**How to avoid:**
- **Build an operator-facing dashboard** (web, not the consumer app) optimized for one job: scan QR on physical order → jump to status update screen → 1-tap state advance
- **Each physical order gets an internal QR sticker** with order ID — operator scans it to load order, advances state with one button
- **Auto-flag stale states**: if order in "in production" > 24h, surface to operator dashboard top, alert via email/push
- **SLAs in customer-visible UI**: "Estimated 2-3 business days for engraving" sets expectation
- **Audit log** of every state transition with operator ID + timestamp
- **Time-based escalation**: if "in production" > 72h with no update, auto-notify operations lead
- **No "skip to delivered" path** — every state must be touched (forces accountability)

**Warning signs:**
- Customers asking "is my order still being made?" 3+ days after order
- Order state distribution shows "production" tail >5 days
- Operator dashboard shows growing backlog with no movement

**Phase to address:** **Order Management phase** (`MKT-07`/`MKT-08`/`MKT-09`). Build operator tooling FIRST, then push notifications, then customer timeline.

---

### Pitfall 9: No "engraving failed, retry" workflow

**What goes wrong:**
Operator engraves QR on wood; the wood splinters / laser misfocuses / surface defect. Material wasted. No defined process for: (a) marking the attempt as failed, (b) charging or not charging the customer, (c) re-engraving without creating a new order, (d) communicating delay to user.

**Why it happens:**
1. Happy path designed first; failure modes assumed rare
2. State machine doesn't model "retry" — only forward transitions
3. Refund/credit logic not built

**How to avoid:**
- **Model the state machine with explicit "production_failed" state** + transitions back to "in production" (for retry) or to "refund_initiated" (for cancel)
- **Failed attempt tracking**: log material used, reason for failure, retry count. After N retries (e.g., 3), auto-escalate
- **User communication**: when state flips to retry, push notification "We're remaking your order — same delivery estimate"
- **Cost accounting**: track material waste per SKU for pricing/margins
- **Refund path**: integrate with Wompi void (card-only) or refund flow for non-card; document who has refund authority

**Warning signs:**
- Operator manually emails customers about delays
- Hidden costs from material waste not surfaced in margin reports
- Same order ID reappears in production queue without state log

**Phase to address:** **Order Management phase** (`MKT-08`). Build the failure path during the same milestone as the happy path; never leave for "later."

---

### Pitfall 10: Personalized goods exempt from derecho de retracto — but app implies otherwise

**What goes wrong:**
Colombian Ley 1480 Art. 47 grants 5-business-day right of withdrawal for e-commerce. **However**, the law explicitly exempts goods *made to consumer specifications or clearly personalized*. A laser-engraved QR with the user's URL/logo qualifies as personalized. If the app's terms say "you have 5 days to return," the company is contractually bound even though the law allows exemption. Or worse: the app *doesn't* mention retracto at all, and the user files a complaint with SIC (Superintendencia de Industria y Comercio).

**Why it happens:**
1. Legal/UX language copy-pasted from generic e-commerce templates
2. Founders unaware of the personalization exemption
3. App fails to display retracto information, which is *itself* a Ley 1480 violation (vendors must inform of retracto means)

**How to avoid:**
- **Explicit terms language**: "Productos personalizados (QR grabado bajo tu diseño) están excluidos del derecho de retracto conforme al Art. 47 num. 3 de la Ley 1480 de 2011"
- **Show this disclaimer at checkout**, not buried in terms — user must see before paying
- **Standard QR templates** (non-personalized, generic designs) DO qualify for retracto if you sell them — handle separately or exclude entirely
- **Refund policy for non-personalized causes**: defective product, shipping damage, wrong item → these are warranty (garantía) claims, NOT retracto, and operate on different timelines (3 months by law for product defects)
- **Have terms reviewed by Colombian lawyer** before launch
- **15-day refund window** for valid claims (legal max from claim approval to money back)

**Warning signs:**
- SIC complaint filed
- Customer expects refund quoting "the law says I have 5 days"
- Internal team can't articulate which claims qualify for retracto vs. garantía

**Phase to address:** **Marketplace/Pre-Launch phase** (`MKT-04`/`MKT-07`). Legal review before first paid transaction.

---

### Pitfall 11: Ley 1581 habeas data non-compliance → SIC fines + app store risk

**What goes wrong:**
QRaft collects sensitive personal data: vCard contacts (names, phones, emails), location for location QR, scan history, marketplace shipping address (full address, ID number for invoicing). Ley 1581/2012 + Decree 1377/2013 require: explicit consent at collection, registered databases (RNBD if processing data of >100k Colombians), privacy policy with specific elements, habeas data process (access/rectification/deletion). Existing CONCERNS.md notes "no privacy explanation screen, no formal privacy policy." This is a regulatory gap.

**Why it happens:**
1. App store "privacy nutrition label" treated as enough
2. Privacy policy a placeholder TODO
3. International privacy (GDPR/CCPA) muscle memory misses Colombia-specific requirements
4. RNBD (Registro Nacional de Bases de Datos) requirement unknown to most foreign-trained devs

**How to avoid:**
- **Privacy policy hosted at qraft-e8a1d.firebaseapp.com or custom domain**, written in Spanish, covering Ley 1581 required elements:
  - Identidad y datos del responsable (legal entity)
  - Tratamiento al cual serán sometidos los datos y finalidad
  - Carácter facultativo de las respuestas a preguntas sobre datos sensibles
  - Derechos del titular (acceso, rectificación, actualización, supresión, revocatoria)
  - Mecanismos para ejercer esos derechos (channel: email, in-app form)
- **Explicit consent UI** on first launch + before each sensitive collection (camera, location, contacts) — *separate* from generic "I agree to terms"
- **Habeas data endpoint**: in-app data export + deletion request flow (the profile_screen.dart:233 stub must become real)
- **RNBD registration** with SIC if QRaft processes data of >100k Colombian users (legal threshold) — at MVP unlikely, but pre-plan
- **Data retention policy**: how long is scan history kept? When is account deletion data purged? (default per best practice: scan history user-controlled deletion + max 2-year retention; account deletion = full purge within 30 days)
- **Designate "Habeas Data Officer"** (responsable del tratamiento) — required role under the law
- **Document third-party processors** (Firebase, Supabase, Wompi, AdMob, RevenueCat) — Ley 1581 requires disclosing data sharing

**Warning signs:**
- Privacy policy is a placeholder or generic ChatGPT output
- No in-app data deletion flow
- No record of consent timestamps per user

**Phase to address:** **Pre-Launch / Compliance phase** (cross-cutting, before any GA). Should be addressed BEFORE marketplace ships paid transactions.

---

### Pitfall 12: Factura electrónica (DIAN) not issued → tax penalty risk

**What goes wrong:**
QRaft (legal entity) sells laser-engraved goods in Colombia. As a "persona jurídica," the company is **mandatorily required** to issue electronic invoices (factura electrónica) per DIAN. Each transaction needs: UBL 2.1 XML, digital signature, CUFE code, DIAN pre-validation, and graphical PDF + QR for verification. Missing invoices → 1% of prior-year operational revenue fine (cap 950 UVT, ~$47M COP), plus possible 3-day commerce closure.

**Why it happens:**
1. Founders treat invoicing as "later, after revenue" — DIAN says NO, it's day 1
2. Building the UBL 2.1 generator + DIAN integration in-house is multi-week effort
3. The customer-facing receipt (visible in app) ≠ the legal factura (must go through DIAN)

**How to avoid:**
- **Integrate a Colombian e-invoicing provider** (Alegra, Siigo, Dataico, Facturo, Nubox) via API — do NOT build in-house. Costs ~$100-300k COP/month for low volume, scales by volume. Provider handles UBL/CUFE/DIAN
- **Trigger invoice generation on Wompi APPROVED webhook** — invoice ID flows into order detail, accessible to user (download PDF)
- **Capture required fields at checkout**: in 2026, only 3 are needed from buyer — name/razón social, ID type+number, email (optional). Simplifies form
- **Test with DIAN sandbox** before production traffic
- **48-hour transmission window** in case of provider/DIAN downtime — NOT 0-tolerance
- **NIT and Cámara de Comercio registration** required for legal entity issuing facturas — confirm corporate setup

**Warning signs:**
- Customer asks "where is my factura?" and team scrambles
- DIAN audit notification (do not ignore)
- Internal accounting can't reconcile sales to invoices

**Phase to address:** **Pre-Launch phase**, BEFORE first paid transaction (`MKT-05`). Block GA on factura integration completion.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip Wompi signature validation in MVP | Fast webhook integration (1 day vs. 3 days) | Free transactions for any attacker who finds the URL; total trust collapse | **Never** — even for sandbox demos |
| Hardcode IVA 19% as fixed multiplier | No tax engine needed | If tax law changes (e.g., reduced rate days like Día sin IVA), or if some products become exempt, every price wrong | Acceptable if explicitly scoped to "Colombian retail goods only, IVA 19%, no exemptions" with code comment |
| Trust app local state for order status | Simpler client logic | Lost orders when app killed, payment confirmation drift | **Never** for paid orders |
| Default error correction to M (qr_flutter default) | One less knob | Branded QRs unscannable in field, returns spike | **Never** for QRs with logos/colors/frames |
| Pull production keys into env.json for "debugging" | Quick reproduction of prod bug | Keys leak to git or local disk; revoke + rotate scramble | **Never** — use Wompi sandbox + matched Supabase project |
| Skip operator dashboard, use Supabase Studio direct | Save dev time on ops UI | Ops bottleneck, untrained operators corrupt data, no audit trail | Acceptable in **alpha with single trusted operator** only; must build dashboard before scaling team |
| Manual factura generation (operator emails PDFs) | Avoid e-invoicing provider cost | DIAN penalty risk; can't scale; user complaints | **Never** for >5 transactions/month in production |
| Skip retry/failure state in fulfillment state machine | Faster initial implementation | First production failure has no defined recovery path; ad-hoc DB fixes corrupt audit log | **Never** for production marketplace |
| Use real Wompi production keys for "internal testing" | Avoid sandbox setup overhead | Real money lost on dev mistakes; PCI scope contamination | **Never** — Wompi provides sandbox keys |
| Skip the ScanCheck post-render validation | Save dev time | Unscannable QRs ship; refund + reprint cost > saved dev time within first month | **Never** for v1.0 GA |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **Wompi Sandbox vs. Production keys** | Same code path tested with sandbox; switching to prod swaps keys without re-validation | Separate environments at build level (`env.json` vs `env.production.json`); URL allowlist explicit; force a smoke test on first prod deploy with $1000 COP transaction |
| **Wompi `X-Event-Checksum`** | Compute checksum with full payload | Per Wompi spec: concat values from `signature.properties` array (in order) + `timestamp` (UNIX integer) + events secret → SHA256. Easy to get field order wrong |
| **Wompi PSE flow** | Treat as synchronous like card payment | PSE redirects user to bank, can take minutes; relies on webhook for completion. App shows "Awaiting bank confirmation" UI, NOT an inline result |
| **Wompi Nequi flow** | Send phone in random format | Sandbox approves only `3991111111`; production needs E.164 or local Colombian format consistent with Wompi spec |
| **Wompi voids vs. refunds** | Treat as same operation | VOID is for card transactions still pending capture (24h-ish window); REFUND for already-settled. Different APIs, different rules. PSE/Nequi cannot be voided — only refunded via different process |
| **Firebase Auth + Supabase RLS** | User authenticated in Firebase, but Supabase RLS expects Supabase JWT | Bridge via Edge Function that mints Supabase JWT from Firebase token; verify pattern works for `auth.uid()` checks; OR migrate to Supabase Auth for app-side. Existing CONCERNS notes service key removed — confirm RLS policies enforce user scoping |
| **mobile_scanner v7.0** | Treat upgrade as patch | Major upgrade requires Flutter 3.29+. Breaking changes on `errorBuilder`, `placeholderBuilder`, `EncryptionType.none`, initial `CameraFacing.unknown`. Re-test full scanner flow on iOS+Android real devices |
| **Image picker iOS 14+ Limited Photos** | Request full Photo Library permission | Use `requestFullMetadata: false` to leverage `PHPickerViewController` which doesn't need permission; `NSPhotoLibraryUsageDescription` still required in Info.plist (App Store), just not shown |
| **AdMob + UMP consent** | Show ads to all users without consent | Integrate `google_user_messaging_platform` SDK, show consent form on first launch (required for EU/UK; recommended for COL given Ley 1581). Without it: AdMob can disable serving |
| **AdMob during checkout** | Show interstitial during payment flow | AdMob policy + UX: never show ads during payment/checkout/confirmation flows. Risk: AdMob policy violation + user perceives ad as scam attempt during sensitive moment |
| **Deep link return URL collision** | Same `qraft://` scheme handles auth + payment + share | Namespace: `qraft://auth/...`, `qraft://payment/wompi-return`, `qraft://share/...` — explicit routes prevent ambiguous handling. Test that incoming Wompi return doesn't trigger auth state machine |
| **Supabase Edge Function + Wompi** | Run client → Wompi directly | Sensitive ops (create transaction, validate webhook, query status) must go through Edge Function. Client never sees private key or events secret |
| **DIAN factura electrónica** | Build UBL 2.1 + signature + CUFE in-house | Use a Colombian provider (Alegra, Siigo, Dataico, etc.) — months of work avoided. Treat invoicing as a webhook trigger from Wompi APPROVED → call provider |
| **flutter_contacts permissions** | Request on app launch | Request only when user reaches vCard QR creation; explain purpose (Ley 1581 finalidad clarity) before triggering OS dialog |
| **Geolocator + location QR** | Persist location in plaintext in scan_history | Treat coordinates as sensitive; user explicit consent at capture; offer redaction in saved history |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Real-time QR re-render on every form change | UI jank, memory spikes, OOM on <2GB devices | Debounce 500ms after typing stops; cache last bitmap; use `compute()` isolate for render | Already happening (per CONCERNS.md, location_qr_screen 2025 lines) — visible at <100 customizations |
| QR Library loads all user QRs at once | App stutters on users with 100+ QRs | Pagination 20/page, ListView.builder, lazy thumbnails | Already known issue (qr_library_screen 1834 lines) — breaks at 100+ items per user |
| flutter_map repaints on every form rebuild | Map laggy when typing in form | Wrap in RepaintBoundary; isolate map state from form state | Already known issue — visible immediately on any field interaction |
| AdMob banner re-loads on every screen rebuild | Wasted ad requests, network bandwidth, battery | Use `AdRequest` lifecycle properly; cache loaded ad; rate-limit reload | Breaks economics at scale — AdMob may flag as invalid traffic |
| Order status polling vs. Realtime | Battery drain, scaling issues | Use Supabase Realtime subscription on `orders` table for active order; fall back to pull on app resume | Polling breaks at >1000 active concurrent users on Realtime subscription saturation per Supabase Realtime limits |
| In-memory marketplace catalog | Cold-start delay; stale prices | Server-side rendering + caching; CDN for product images; ETag-based refresh | Breaks at >100 SKUs or with frequent price updates |
| Image upload (logo) blocks UI thread | App hangs during upload | Background isolate + progress indicator + compression before upload | Already fragile (image_service.dart 640 lines) |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Wompi events secret in client code | Attacker replays valid events; can forge transaction approvals | Secret only in Supabase Edge Function env; never in app bundle, never in git |
| Order amount calculated client-side, sent to Wompi | Tampered cart → pay $1000 COP for $89,000 product | Backend computes total (subtotal + IVA + envío) and creates Wompi transaction; client just initiates and observes |
| User ID for order via client claim | User A pays for User B's order; user views others' orders | Server uses authenticated session ID, not client-supplied user ID; RLS enforces `user_id = auth.uid()` |
| Logo upload without sanitization | XSS via SVG, oversized files, malware | Whitelist file types (PNG/JPG only, no SVG); max 2MB; image dimensions check; strip metadata; re-encode server-side |
| Scan history exposing other users' data | RLS gap reveals private scans | Audit RLS on `scan_history`, `qr_codes`, `orders`; CI test that anon user can't read another user's row |
| Address (envío) in plain logs | PII leak via logging tool (Crashlytics) | Redact name/address/phone in error logs; use Sentry/Crashlytics scrubbers; OPT-03 observability must include PII scrubbing |
| Wompi webhook URL guessable / brute-force | Replay attacks if signature also weak | Use UUID-based webhook URL; rate-limit at edge; reject without signature unconditionally |
| AdMob device ID + GAID without consent | Ley 1581 / GDPR violation | UMP consent FIRST, then ad request; respect "do not personalize" |
| Storing Colombian ID number unencrypted | Identity theft if breached | Encrypt at rest (Supabase has column encryption); minimize collection — only at factura time, not at signup |
| Service key (already removed) re-introduced via env.production.json | RLS bypass; mass data leak | Code review checklist: never use service key in client; CI grep for `service_role`; document anon-key-only |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| QR preview in app looks great, real engraving differs | "I didn't expect it to look like that" — refund requests | Show realistic material preview (wood grain texture, acrylic translucency) with engraved-result rendering, not just dark/light QR on flat color |
| User saves QR; later edits source URL — old physical engraved QR breaks | "My engraved code stopped working" — but it's their data change | Make this risk **explicit at checkout**: "El QR grabado apuntará a esta URL para siempre. Si la URL cambia, el QR físico no se actualizará." Consider QRaft-hosted redirect URLs as default (qrf.co/abc → user's URL) so users CAN update later |
| Long fulfillment timeline with no in-app updates | User assumes order lost | Push notifications on EVERY state transition (`MKT-09`); plus passive timeline always visible; SLAs explicit at order time |
| AdMob interstitial during QR generation flow | Breaks creative flow; user abandons | Show ads only at natural pauses (between sessions, on library list refresh, NEVER mid-creation, NEVER during checkout) |
| Wompi widget UI in different language than app | User confusion | Wompi widget supports es-CO; ensure locale param passed; test that Wompi screens look "native" continuation of QRaft |
| Scanner permission denied → no recovery UX | User stuck | Per CONCERNS, retry UI + permission rationale + "open Settings" deep link button |
| Forgot password landing in app but no navigation | Flow break | Per CONCERNS, deeplink_service.dart:194 TODO must complete before launch |
| No download/share of factura electrónica | User can't expense purchase / file taxes | Provide PDF download on order detail page; email factura on completion |
| Cart abandonment with personal data already entered | User redoes everything | Persist cart + entered data 30 days; one-tap resume |
| "Custom" QR design tools too overwhelming | Decision paralysis, low conversion | Templates first (`QR-06`); customization as progressive disclosure |
| Color picker allows non-scannable combinations | User builds something that fails post-purchase | Real-time scannability indicator (green/yellow/red) on the design canvas; block save on red |

---

## "Looks Done But Isn't" Checklist

- [ ] **QR Generation:** Often missing **scannability validation post-render** — verify the exported PNG actually scans on iOS Camera, Android default, and Google Lens before allowing save
- [ ] **QR Customization:** Often missing **error correction = H enforced** — verify any QR with logo/frame/color is forced to H regardless of UI default
- [ ] **QR Customization:** Often missing **quiet zone enforcement** — verify exported image has 4-module padding around modules
- [ ] **QR Scanner (`SCAN-01`):** Often missing **iOS dependency unblock** — verify mobile_scanner v7 builds clean on iOS, scans on real device, handles permission revocation mid-scan
- [ ] **Wompi integration:** Often missing **webhook signature validation** — verify by sending a forged event with invalid checksum, confirm rejection
- [ ] **Wompi integration:** Often missing **idempotency keys** — verify that 2 retries of same payment create 1 transaction, not 2
- [ ] **Wompi integration:** Often missing **sandbox→prod environment isolation** — verify keys are environment-scoped, not hardcoded
- [ ] **Order management:** Often missing **operator dashboard** — verify there's a non-Supabase-Studio interface for the laser operator
- [ ] **Order management:** Often missing **failure/retry state path** — verify state machine handles "engraving failed → retry" without DB hacks
- [ ] **Order management:** Often missing **stale order alerts** — verify orders stuck in same state >SLA trigger automatic flagging
- [ ] **Factura electrónica:** Often missing entirely — verify integration with DIAN-certified provider, test sandbox, validate CUFE on a real test invoice
- [ ] **Privacy policy:** Often a placeholder — verify it's hosted, in Spanish, covers Ley 1581 elements, linked from app + signup + checkout
- [ ] **Habeas data flow:** Often missing — verify in-app data export AND deletion flow exists and works end-to-end
- [ ] **Consent UI:** Often missing per-permission rationale — verify camera/location/contacts each show why before OS dialog
- [ ] **AdMob UMP consent:** Often missing — verify consent form shows before any ad request on first launch
- [ ] **Deep link conflicts:** Often missing namespace — verify auth/payment/share deep links don't collide
- [ ] **Tax calculation:** Often missing IVA breakdown on receipt — verify subtotal, IVA 19%, envío, total all surface in checkout AND on factura
- [ ] **Refund flow:** Often only happy-path — verify refund initiation works for Wompi card (void) and PSE/Nequi (refund) separately
- [ ] **Reconciliation:** Often missing — verify nightly job comparing Wompi balance to internal sum of APPROVED orders
- [ ] **Test coverage of checkout:** Per Key Decisions in PROJECT.md, marked "revisit" — verify checkout flow has integration tests covering double-charge, app-killed, signature-invalid scenarios
- [ ] **mobile_scanner v7 upgrade:** Per CONCERNS — verify scan flow on iOS real device, permission revocation mid-scan, camera switching
- [ ] **ForgotPasswordDialog tests:** Per CONCERNS, 5/13 failing — verify all pass before any auth-adjacent change ships

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Webhook signature not validated, attacker exploited | **HIGH** | (1) Disable webhook URL immediately; (2) audit all orders past 30d for forged status; (3) refund any fulfilled-but-unpaid; (4) deploy validation; (5) rotate Wompi events secret; (6) post-mortem + SIC notification if customer data affected |
| Double-charge from non-idempotent retries | **MEDIUM** | (1) Identify duplicates (same user + amount + ≤60s window); (2) auto-refund the duplicate via Wompi void/refund API; (3) email user with apology + reference; (4) deploy idempotency key; (5) reconcile internal DB |
| Branded QR design ships, returns spike | **MEDIUM** | (1) Pause sales of affected SKUs; (2) audit all designs against scannability rules retroactively; (3) re-engrave free of charge for affected customers; (4) deploy ScanCheck validation; (5) tighten template gallery |
| Order stuck in production, customer complains | **LOW** | (1) Operator dashboard surface (one-time DB query if dashboard not built); (2) update state manually with audit log entry; (3) push notification to user; (4) build stale-order alert if not present |
| Engraving failure with no retry path | **MEDIUM** | (1) Manual coordination operator + ops lead; (2) customer email apology + ETA; (3) free retry or refund per discretion; (4) build retry state path immediately |
| Factura not issued, DIAN audit | **HIGH** | (1) Issue back-dated facturas (DIAN allows correction within window); (2) integrate provider urgently; (3) lawyer-mediated SIC/DIAN response; (4) potential 1% revenue penalty |
| Privacy policy non-compliant, SIC complaint | **MEDIUM** | (1) Update privacy policy with Ley 1581 elements; (2) implement habeas data flow; (3) respond to SIC complaint within deadline (15 days); (4) potential fines (0.1-2000 SMMLV) |
| Inverted QR shipped, user can't scan | **LOW** | (1) Identify affected orders; (2) re-engrave with corrected polarity; (3) ship at QRaft cost; (4) hotfix exporter to force dark-on-light |
| App-killed mid-payment, order stuck pending | **LOW** | (1) Reconciliation job runs; (2) detects PAID-in-Wompi but PENDING-in-DB; (3) auto-update; (4) push notification to user; (5) deploy backend-as-source-of-truth pattern |
| Service key accidentally re-introduced | **HIGH** | (1) Immediately rotate Supabase keys; (2) audit RLS for any reliance; (3) review git history for leaked key; (4) revoke + replace; (5) CI grep rule to prevent recurrence |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Logo too big → unscannable | QR Generation phase (`QR-01`/`QR-02`) | Render-time validation; scan matrix CI test on every preset |
| Inverted QR fails scanners | QR Customization phase (`QR-03`) | Export forces dark-on-light; visual regression test |
| Frame clipping quiet zone | QR Customization phase (`QR-05`) | Programmatic 4-module padding enforcement; export inspection |
| Custom eye styles fail | QR Customization phase (`QR-04`) | Curated preset gallery passes scanner matrix CI |
| Wompi webhook signature ignored | Marketplace/Payment phase (`MKT-06`) | Send forged event in CI; assert rejection |
| Double-charge from retry | Marketplace/Payment phase (`MKT-05`) | Integration test: simulate timeout + retry, assert single transaction |
| App-killed mid-payment | Marketplace/Payment phase (`MKT-05`) | Backend-as-source-of-truth; reconciliation job test |
| Order status drift | Order Management phase (`MKT-08`) | Operator dashboard built; stale-order alert active |
| No engraving retry path | Order Management phase (`MKT-08`) | State machine includes `production_failed`; retry test |
| Retracto disclaimer missing | Pre-Launch / Marketplace (`MKT-04`) | Legal review sign-off; terms displayed at checkout |
| Ley 1581 non-compliance | Pre-Launch / Compliance (cross-cutting) | Privacy policy live; consent UI present; data export+deletion flows tested |
| Factura not issued | Pre-Launch / Marketplace (`MKT-05`) | DIAN-certified provider integrated; test invoice issued in sandbox |
| AdMob without UMP consent | Optimization / OPT-03 phase | UMP consent shown on first launch; tests confirm no ad request before consent |
| AdMob during checkout | Cross-cutting (any phase introducing checkout) | UI policy: ad-free routes for /checkout/*, /payment/* |
| mobile_scanner v7 issues | QR Scanner phase (`SCAN-01`) | Real-device test plan iOS + Android; permission edge cases |
| Image picker iOS 14+ | QR Generation phase (`QR-02`) | `requestFullMetadata: false` set; tested on iOS 14/15/16/17 |
| Deep link conflicts | Cross-cutting (Auth, Payment, Share) | Namespaced routes; integration tests for each link type |
| IVA calculation timing | Marketplace phase (`MKT-03`) | Server-computed total; receipt shows breakdown; test fixtures |

---

## Sources

**QR Design & Scannability** (HIGH confidence — based on ISO/IEC 18004 standard + corroborating industry sources):
- [QR Code Design Rules: ISO/IEC 18004 Quiet Zone, Contrast & Size — QRLynx](https://qrlynx.com/blog/qr-code-design-best-practices)
- [QR Code Error Correction Levels Explained — SmartyTags](https://www.smartytags.com/blog/qr-code-error-correction-levels)
- [QR Code Quiet Zone: The Most Ignored Requirement — QRCodeFYI](https://qrcodefyi.com/guide/quiet-zone-guide/)
- [Inverted QR Codes: White on Dark Backgrounds — QRCodeFYI](https://qrcodefyi.com/guide/inverted-qr-codes/)
- [Inverted QR Codes (Light on Dark): Why You Should Avoid Them — QR Designer](https://qrdesigner.com/blog/inverted-qr-codes-light-on-dark-why-you-should-avoid-them)
- [Why Is Your QR Code Not Working? 13 Causes and Fixes — Uniqode](https://www.uniqode.com/blog/qr-code-best-practices/qr-code-not-working)
- [QR Code Laser Engraving: A Complete Guide — OMTech](https://omtech.com/blogs/tips/qr-code-laser-engraving)
- [QR Code Laser Engraving Guide — Thunder Laser USA](https://www.thunderlaserusa.com/blog/qr-code-laser-engraving-guide/)

**Wompi Integration** (HIGH confidence — official Wompi documentation):
- [Wompi Events / Webhooks Documentation](https://docs.wompi.co/en/docs/colombia/eventos/)
- [Wompi Transactions Documentation](https://docs.wompi.co/en/docs/colombia/transacciones/)
- [Wompi Sandbox Test Data](https://docs.wompi.co/en/docs/colombia/datos-de-prueba-en-sandbox/)
- [Wompi Environments and Keys](https://docs.wompi.co/en/docs/colombia/ambientes-y-llaves/)
- [Wompi Payment Methods](https://docs.wompi.co/en/docs/colombia/metodos-de-pago/)
- [Wompi Widget & Checkout Web](https://docs.wompi.co/en/docs/colombia/widget-checkout-web/)
- [wompi_payment_colombia Flutter package](https://pub.dev/packages/wompi_payment_colombia)
- [Webhook Best Practices: Idempotency and Event Ordering — BoldSign](https://boldsign.com/blogs/webhook-best-practices-retries-idempotency/)
- [Handling Payment Webhooks Reliably — Medium](https://medium.com/@sohail_saifii/handling-payment-webhooks-reliably-idempotency-retries-validation-69b762720bf5)

**Flutter & App-Killed Patterns** (HIGH/MEDIUM):
- [Webhooks and How to Use Them in Your Flutter Backend — Code with Andrea](https://codewithandrea.com/articles/webhooks-flutter-backend/)
- [Flutter, Android, and Process Death — Square Developer Blog](https://developer.squareup.com/blog/flutter-android-and-process-death/)
- [mobile_scanner pub.dev](https://pub.dev/packages/mobile_scanner)
- [mobile_scanner Changelog](https://pub.dev/packages/mobile_scanner/changelog)
- [image_picker pub.dev — PHPickerViewController iOS 14+](https://pub.dev/packages/image_picker)
- [Flutter image_picker iOS 14 Photos Limited Permission — GitHub Issues #65995, #74014, #118687](https://github.com/flutter/flutter/issues/65995)

**Colombian Regulation** (HIGH confidence — official sources):
- [Ley 1581 de 2012 — Función Pública](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981)
- [Ley 1480 de 2011 (Estatuto del Consumidor) — Función Pública](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=44306)
- [Art. 47 Estatuto del Consumidor — Derecho de Retracto](https://leyes.co/el_estatuto_del_consumidor/47.htm)
- [Habeas Data: Protección de datos personales — Min. Justicia](https://www.minjusticia.gov.co/programas-co/LegalApp/Paginas/proteccion-de-datos-personales.aspx)
- [Colombia Law 1581 Data Protection Guide — ResGuard](https://resguard-solutions.com/blog/en/colombia-law-1581-data-protection-guide/)
- [Sistema de Factura Electrónica DIAN](https://micrositios.dian.gov.co/sistema-de-facturacion-electronica/)
- [Facturación electrónica DIAN 2026 — Dian.com.co](https://dian.com.co/facturacion-electronica-colombia-2026/)
- [Factura electrónica Colombia 2026 — Dataico](https://www.dataico.com/guia-factura-electronica-colombia-dian)
- [Colombian VAT rates and VAT compliance — Avalara](https://www.avalara.com/vatlive/en/country-guides/south-america/colombia/colombian-vat-rates-and-vat-compliance.html)

**AdMob & Compliance** (HIGH):
- [AdMob behavioral policies — Google Support](https://support.google.com/admob/answer/2753860)
- [AdMob policies and restrictions — Google Support](https://support.google.com/admob/answer/6128543)

**Internal references** (codebase concerns + project context):
- `/Users/ianmoone/Development/Personal/qraft/.planning/PROJECT.md`
- `/Users/ianmoone/Development/Personal/qraft/.planning/codebase/CONCERNS.md`
- `/Users/ianmoone/Development/Personal/qraft/CLAUDE.md`

---
*Pitfalls research for: QRaft (QR generation/customization + Colombian e-commerce + manual laser fulfillment, Flutter app)*
*Researched: 2026-05-01*
