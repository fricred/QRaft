# Architecture Research

**Domain:** Flutter QR-customization app + Supabase marketplace + Wompi payments + manual laser fulfillment (Colombia retail)
**Researched:** 2026-05-01
**Confidence:** HIGH (Wompi/Supabase/Riverpod patterns verified against official docs; QR rendering verified against qr_flutter package; manual-fulfillment integration is application of well-known state-machine patterns)

## Standard Architecture

### System Overview

The architecture extends the existing Clean Architecture (data/domain/presentation per feature, Riverpod state) with three new feature modules (`qr_customization`, `cart`, `orders`), a new `payments` core service, and Supabase-side Edge Functions for Wompi webhook handling. The "operator dashboard" is a Supabase-backed web admin (separate Flutter Web build or Retool/Supabase Studio) — NOT bundled into the consumer app.

```
┌──────────────────────────────────────────────────────────────────────────┐
│                  CONSUMER APP (Flutter iOS/Android)                       │
├──────────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────┐  │
│  │qr_gen +  │ │qr_scanner│ │qr_library │ │marketplace│ │orders        │  │
│  │customize │ │          │ │           │ │+ cart    │ │(timeline)    │  │
│  └────┬─────┘ └────┬─────┘ └─────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│       │            │             │             │              │          │
│       └────────────┴─────────────┴─────────────┴──────────────┘          │
│                              │ Riverpod providers                         │
├──────────────────────────────┼───────────────────────────────────────────┤
│                              ▼                                            │
│   Domain layer (entities, use cases, abstract repositories)               │
├──────────────────────────────┬───────────────────────────────────────────┤
│                              ▼                                            │
│   Data layer (repository impls, datasources, models)                      │
├──────────────────────────────┬───────────────────────────────────────────┤
│                              ▼                                            │
│   Core services: SupabaseService │ PaymentsService (Wompi widget) │ FCM  │
└──────────────────────────────┬───────────────────────────────────────────┘
                               │ HTTPS + Realtime + FCM
        ┌──────────────────────┼─────────────────────────┐
        ▼                      ▼                         ▼
┌──────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ Supabase Postgres│  │ Supabase Edge Funcs │  │ Wompi Checkout/API  │
│ (RLS-protected)  │  │ - wompi-webhook     │  │ - widget (in-app)   │
│ - qr_codes       │  │ - notify-operator   │  │ - transactions API  │
│ - templates      │  │ - send-fcm          │  │ - events webhook    │
│ - cart_items     │  │ - cancel-order      │  └──────────┬──────────┘
│ - orders         │  └──────────┬──────────┘             │
│ - order_items    │             │                        │
│ - payments       │             │ POST                   │
│ - shipments      │             ▼                        │ (X-Event-Checksum)
│ - notifications  │  ┌─────────────────────┐             │
└────────▲─────────┘  │ FCM (Firebase)      │◀────────────┘
         │            └─────────────────────┘
         │ Realtime subscriptions
         │
┌────────┴────────────────────────────────────────────────┐
│ OPERATOR DASHBOARD (Flutter Web or Supabase Studio)     │
│ - View pending orders                                    │
│ - Transition state (received → engraving → done → ...)  │
│ - Upload shipment tracking                               │
└──────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `qr_generator` (existing) | QR data type forms, generation use case | Already implemented |
| `qr_customization` (NEW) | Customization state (colors, eye style, logo, frame), preview rendering | `StateNotifierProvider<QRCustomizationController, QRCustomizationState>` driving a `QrImageView` widget |
| `qr_export` (NEW, sub-module) | Rasterize/export QR to PNG/SVG/PDF for share or material preview | `RepaintBoundary` + `toImage(pixelRatio: 4-8)` for high-DPI export |
| `marketplace` (extend stub) | Catalog browse, product detail, material previews | `FutureProvider` for catalog fetch; product entities with material specs |
| `cart` (NEW) | Cart state, persistence (local + remote), totals | `StateNotifierProvider<CartController, CartState>` with hybrid persistence (Hive local + Supabase `cart_items` for cross-device) |
| `checkout` (NEW, sub-module) | Address collection, total computation (subtotal + IVA + shipping), Wompi widget launch | Wraps Wompi web checkout via `webview_flutter` (already in pubspec) or deep-linked external browser |
| `payments` (core service) | Wompi widget invocation, transaction reference generation, redirect handling | Singleton service in `lib/core/services/payments_service.dart`; deep-link callback finalizes |
| `orders` (NEW) | Order list, order detail, timeline of states | `FutureProvider` for list; `StreamProvider` (Supabase realtime) for individual order status |
| `notifications` (NEW, core) | FCM token registration, foreground handling | `FirebaseMessaging` + token sync to Supabase user profile |
| `wompi-webhook` Edge Func | Verify SHA256 checksum, idempotency, update payment+order state | Deno function in `supabase/functions/wompi-webhook/` |
| `notify-operator` Edge Func | On new paid order, write to ops queue + send email | Triggered from DB trigger or cron |
| `send-fcm` Edge Func | Read from `notifications` table, push to FCM HTTP v1 API | Triggered by DB webhook on `INSERT` |
| Operator dashboard | Manual state transitions (received → engraving → done → shipped) | Flutter Web build OR Supabase Studio with a dedicated `operator_view` |

## Recommended Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── supabase_service.dart        (existing)
│   │   ├── deeplink_service.dart        (existing — extend for Wompi callback)
│   │   ├── payments_service.dart        NEW — Wompi widget launcher, ref generator
│   │   └── fcm_service.dart             NEW — FCM token registration, foreground handler
│   └── config/
│       ├── env_config.dart              (existing — add WOMPI_PUBLIC_KEY, WOMPI_INTEGRITY)
│       └── wompi_config.dart            NEW — endpoints, checkout URL builder
│
├── features/
│   ├── qr_generator/                    (existing)
│   │
│   ├── qr_customization/                NEW
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── template_supabase_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── qr_template_model.dart
│   │   │   │   └── qr_style_model.dart
│   │   │   └── repositories/
│   │   │       └── template_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── qr_style.dart        (color, gradient, eye_shape, module_shape, frame)
│   │   │   │   ├── qr_template.dart     (curated preset)
│   │   │   │   └── logo_config.dart     (image bytes, halo, position, size_pct)
│   │   │   ├── repositories/
│   │   │   │   └── template_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── apply_template_use_case.dart
│   │   │       └── validate_logo_size_use_case.dart  (enforces ≤25% area)
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── qr_customization_controller.dart  StateNotifier
│   │       ├── pages/
│   │       │   ├── customization_screen.dart
│   │       │   └── template_gallery_screen.dart
│   │       ├── providers/
│   │       │   └── customization_providers.dart
│   │       └── widgets/
│   │           ├── qr_preview.dart                   (RepaintBoundary)
│   │           ├── color_gradient_picker.dart
│   │           ├── eye_shape_picker.dart
│   │           ├── frame_picker.dart
│   │           └── logo_uploader.dart
│   │
│   ├── qr_export/                       NEW (sub-module of customization or shared)
│   │   ├── data/
│   │   │   └── services/
│   │   │       ├── qr_rasterizer_service.dart        (RepaintBoundary→PNG)
│   │   │       └── qr_pdf_service.dart                (printing/pdf package)
│   │   └── presentation/
│   │       └── widgets/
│   │           └── share_sheet.dart
│   │
│   ├── marketplace/                     (extend existing stub)
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── product_supabase_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── product_model.dart                (extend existing entity)
│   │   │   │   ├── material_model.dart
│   │   │   │   └── product_variant_model.dart
│   │   │   └── repositories/
│   │   │       └── product_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── product_entity.dart               (existing — extend)
│   │   │   │   ├── material_entity.dart              (wood/acrylic/metal/leather/glass/stone)
│   │   │   │   └── product_variant.dart              (size × material × price)
│   │   │   └── use_cases/
│   │   │       └── render_material_preview_use_case.dart (composite QR onto material image)
│   │   └── presentation/                              (existing pages — extend)
│   │
│   ├── cart/                            NEW
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── cart_local_data_source.dart       (Hive)
│   │   │   │   └── cart_supabase_data_source.dart    (cart_items table)
│   │   │   ├── models/
│   │   │   │   └── cart_item_model.dart
│   │   │   └── repositories/
│   │   │       └── cart_repository_impl.dart         (merges local+remote on sign-in)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── cart_item.dart                    (product_variant_id, qr_code_id, qty, customization_snapshot)
│   │   │   │   └── cart.dart
│   │   │   └── use_cases/
│   │   │       ├── add_to_cart_use_case.dart
│   │   │       ├── update_quantity_use_case.dart
│   │   │       └── compute_totals_use_case.dart      (subtotal + IVA 19% + shipping)
│   │   └── presentation/
│   │       ├── controllers/cart_controller.dart       StateNotifier persisted
│   │       ├── pages/cart_screen.dart
│   │       └── providers/cart_providers.dart
│   │
│   ├── checkout/                        NEW
│   │   ├── data/
│   │   │   └── repositories/checkout_repository_impl.dart  (creates order + payment intent)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── shipping_address.dart
│   │   │   │   └── checkout_session.dart
│   │   │   └── use_cases/
│   │   │       ├── create_order_use_case.dart        (atomic order + items insert)
│   │   │       └── launch_wompi_checkout_use_case.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── shipping_screen.dart
│   │       │   ├── review_screen.dart
│   │       │   └── payment_result_screen.dart        (deep-link landing)
│   │       └── widgets/
│   │           └── colombian_address_form.dart        (depto/ciudad/dir)
│   │
│   ├── orders/                          NEW
│   │   ├── data/
│   │   │   ├── datasources/order_supabase_data_source.dart
│   │   │   ├── models/order_model.dart
│   │   │   └── repositories/order_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── order.dart
│   │   │   │   ├── order_item.dart
│   │   │   │   ├── order_status.dart                  (enum FSM)
│   │   │   │   └── shipment.dart
│   │   │   └── use_cases/
│   │   │       └── get_order_timeline_use_case.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── orders_list_screen.dart
│   │       │   └── order_detail_screen.dart           (uses StreamProvider — realtime)
│   │       └── widgets/
│   │           └── order_timeline.dart
│   │
│   └── notifications/                   NEW
│       ├── data/services/fcm_token_sync_service.dart
│       └── presentation/providers/notification_providers.dart
│
└── shared/widgets/                      (existing — keep adding here)

supabase/
├── migrations/
│   ├── (existing 001, 002, scan_history fix)
│   ├── 20260501000000_marketplace_schema.sql         NEW
│   ├── 20260501000001_orders_payments_schema.sql     NEW
│   ├── 20260501000002_notifications_schema.sql       NEW
│   ├── 20260501000003_qr_templates_schema.sql        NEW
│   └── 20260501000004_rls_policies.sql               NEW
└── functions/
    ├── wompi-webhook/                                 NEW (Deno)
    │   └── index.ts
    ├── send-fcm/                                      NEW
    │   └── index.ts
    └── notify-operator/                               NEW
        └── index.ts
```

### Structure Rationale

- **`qr_customization/` separate from `qr_generator/`:** Generation (data type forms) is solved; customization is a layered concern that needs its own state and use cases (templates, validation of logo size, gradient definitions). Separation keeps `qr_generator` stable.
- **`qr_export/` as sub-module:** Rasterization/PDF logic is pure utility, not a domain. Could live under `core/services/` but keeping it near customization keeps related concerns close.
- **`cart/` and `checkout/` split:** Cart is long-lived state (days/weeks); checkout is an ephemeral session (minutes). Different lifecycles → different modules.
- **`orders/` independent of `checkout/`:** Orders persist long after checkout completes. Order state machine evolves via webhook + operator actions, not from checkout flow.
- **`payments_service.dart` in `core/`:** Wompi is infrastructure, not a domain feature. Other features (e.g., subscription top-ups in v2) may need it.
- **Edge Functions in `supabase/functions/`:** Webhook security requires server-side validation (cannot trust client). Deno runtime is Supabase-native; matches existing pattern.

## Architectural Patterns

### Pattern 1: Customization State as Persisted Snapshot

**What:** When user adds a customized QR to cart, the customization is **frozen as a snapshot** in `cart_items.customization_snapshot` (JSONB), then again into `order_items.customization_snapshot` at checkout. The QR's `qr_codes` row is NOT mutable from cart/order context.

**When to use:** Always. User may edit the QR after ordering — the engraver must produce what was ordered, not the latest version.

**Trade-offs:**
- Pro: Immutable order history; correct fulfillment; legal traceability
- Pro: User can edit/duplicate QRs in library without affecting in-flight orders
- Con: Slight data duplication (customization JSON × N orders)

**Example:**
```dart
class CartItem {
  final String productVariantId;     // wood-10x10cm
  final String qrCodeId;              // points to qr_codes
  final QRCustomization customization; // SNAPSHOT, not reference
  final int quantity;
}
// At checkout:
final orderItem = OrderItem(
  productVariantId: cartItem.productVariantId,
  qrSnapshotPayload: cartItem.customization.toJson(), // frozen
  qrPngExportUrl: await rasterizeAndUpload(cartItem),  // pre-rasterized for engraver
);
```

### Pattern 2: Server-Authoritative Order State Machine

**What:** Order status transitions live in PostgreSQL with a CHECK constraint enforcing the FSM. Client is **read-only** for status (writes only via Edge Function or operator role).

**When to use:** Any flow where state correctness affects money/fulfillment.

**State machine:**
```
            payment_pending
                 │
       ┌─────────┴──────────┐
       ▼                    ▼
   payment_failed       paid
                            │
                            ▼
                     received_by_ops    ← operator confirms order intake
                            │
                            ▼
                       engraving        ← operator starts laser job
                            │
                            ├── engraving_failed (back to received_by_ops)
                            ▼
                       engraving_done
                            │
                            ▼
                        shipped         ← operator uploads tracking
                            │
                            ▼
                       delivered        ← courier webhook OR manual
                            │
                            └── (terminal)
        cancelled (terminal — only allowed from payment_pending/payment_failed/received_by_ops)
        refunded  (terminal — from any post-paid state, requires admin)
```

**Trade-offs:**
- Pro: Impossible-to-corrupt state from client; auditable
- Con: All transitions must be authored as DB functions or Edge Functions
- Con: Adding states later requires migration

**Example (Postgres):**
```sql
CREATE TYPE order_status AS ENUM (
  'payment_pending','payment_failed','paid',
  'received_by_ops','engraving','engraving_failed','engraving_done',
  'shipped','delivered','cancelled','refunded'
);

-- Validate transitions in trigger
CREATE FUNCTION validate_order_transition() RETURNS trigger AS $$
BEGIN
  IF OLD.status = 'paid' AND NEW.status NOT IN ('received_by_ops','cancelled','refunded') THEN
    RAISE EXCEPTION 'Invalid transition: % → %', OLD.status, NEW.status;
  END IF;
  -- ... other transition rules
  RETURN NEW;
END $$ LANGUAGE plpgsql;
```

### Pattern 3: Idempotent Wompi Webhook (Edge Function)

**What:** Wompi may deliver the same `transaction.updated` event multiple times. Edge Function uses a `payment_events` table with `event_id UNIQUE` and a SHA256 checksum verification before any state mutation.

**When to use:** All inbound payment webhooks. Non-negotiable — duplicate processing = double-charge appearance to user, double order to operator.

**Algorithm:**
1. Receive POST from Wompi
2. Read `X-Event-Checksum` header
3. Concatenate `properties` field values + `timestamp` + Wompi events secret → SHA256 hex
4. If computed ≠ received → 401 (reject)
5. Try `INSERT INTO payment_events (event_id, ...) VALUES (...)`. If `UNIQUE` violation → 200 (already processed, ignore)
6. If insert succeeds → look up `payments.transaction_ref`, atomically update `payments.status` and `orders.status` via FSM-aware function
7. INSERT into `notifications` (triggers FCM)
8. Return 200

**Trade-offs:**
- Pro: Replay-safe, signature-verified, idempotent
- Con: Adds DB write per event (acceptable — events are infrequent)

**Example (Deno Edge Function skeleton):**
```typescript
import { createHash } from "https://deno.land/std/hash/mod.ts";

Deno.serve(async (req) => {
  const body = await req.json();
  const receivedChecksum = req.headers.get("X-Event-Checksum") ?? body.signature?.checksum;

  // 1. Verify checksum
  const props = body.signature.properties.map(p =>
    p.split('.').reduce((o, k) => o?.[k], body.data)
  ).join('');
  const expected = await sha256(`${props}${body.timestamp}${Deno.env.get("WOMPI_EVENTS_SECRET")}`);
  if (expected !== receivedChecksum) return new Response("invalid", { status: 401 });

  // 2. Idempotency
  const supabase = createClient(...);
  const { error: insertErr } = await supabase
    .from("payment_events")
    .insert({ event_id: body.id, payload: body, kind: body.event });
  if (insertErr?.code === "23505") return new Response("already_processed", { status: 200 });

  // 3. Apply state via RPC (server-side FSM)
  await supabase.rpc("apply_payment_event", {
    p_transaction_ref: body.data.transaction.reference,
    p_wompi_status: body.data.transaction.status, // APPROVED/DECLINED/VOIDED/ERROR
  });

  return new Response("ok", { status: 200 });
});
```

### Pattern 4: Hybrid Cart Persistence (Local + Remote)

**What:** Cart state mirrors to both Hive (local, instant) and Supabase `cart_items` (remote, cross-device). On app launch, remote is source of truth IF user is signed in; Hive is source of truth for guest sessions or offline.

**Merge strategy on sign-in:**
- If guest cart has items AND remote cart is empty → push local to remote
- If both have items → prompt user ("Keep local cart? / Use saved cart? / Merge?")
- After resolution → both stores hold identical state

**Trade-offs:**
- Pro: Works offline, survives app reinstall (when signed in)
- Pro: Cross-device cart for premium users
- Con: Merge UX is non-trivial (deferrable to v1.1 if MVP)

### Pattern 5: Realtime Order Tracking via Supabase Subscriptions

**What:** `OrderDetailScreen` uses a `StreamProvider` backed by a Supabase realtime channel listening to `UPDATE` on `orders WHERE id = :order_id AND user_id = auth.uid()`. UI re-renders timeline as operator transitions states.

**When to use:** Whenever user is actively viewing a single order. NOT for the orders list (use polling-on-pull-to-refresh instead — realtime channels are connection-bounded).

**Trade-offs:**
- Pro: Sub-second status updates without polling
- Pro: Complements FCM (FCM = wake from background, realtime = live in-app)
- Con: Realtime + RLS requires careful policy design (subscription respects RLS automatically — verified)

### Pattern 6: QR Rendering Pipeline

**What:** Three-tier rendering — preview, export-quality raster, vector.

```
Customization state (Riverpod)
        │
        ▼
QrImageView (qr_flutter)         ← real-time preview, ~16ms render budget
        │
        ▼ (on demand)
RepaintBoundary.toImage(pixelRatio: 6.0 = 1080px)  ← share sheet, save
        │
        ▼ (on order checkout)
RepaintBoundary.toImage(pixelRatio: 12.0 = 2160px)  ← engraver-quality PNG → upload to Supabase Storage
        │
        ▼ (optional)
SVG export via custom painter for vector workflows  ← future / B2B
```

**Logo embedding rule (enforced in domain layer):**
- Error correction MUST be Level H (30% recovery) when logo present
- Logo area ≤ 25% of QR area (validated by `validate_logo_size_use_case`)
- Logo gets a white halo/padding (configurable 4-12px equivalent) to prevent module bleed

**Trade-offs:**
- Pro: Cheap preview (60fps), expensive export only when needed
- Con: 2160px raster on low-end Android may take 200-500ms — show shimmer

## Data Flow

### Request Flow: User Creates QR → Customizes → Adds to Cart → Checks Out → Engraver Receives

```
[1. Generate]
User → QRGeneratorScreen → QRGeneratorController.create()
  → SaveQRUseCase → QRRepositoryImpl → QRSupabaseDataSource → INSERT qr_codes
  ← QRCodeEntity returned

[2. Customize]
User → CustomizationScreen → QRCustomizationController.update(style)
  → state mutation (no DB write yet — preview only)
  → QrImageView re-renders preview
  → on "Save" → UpdateQRUseCase → QRRepositoryImpl → UPDATE qr_codes.customization

[3. Material Preview]
User → MarketplaceScreen → ProductDetailScreen
  → renderMaterialPreviewUseCase(productVariant, qrCodeId)
  → fetch material texture from Supabase Storage
  → composite (Stack: material image + QrImageView with material-appropriate colors)

[4. Add to Cart]
User taps "Add to cart" → CartController.add(cartItem)
  → AddToCartUseCase
    → write to Hive (instant)
    → CartSupabaseDataSource.upsert (background)
  → state notifies UI
  → cart badge updates

[5. Checkout — Create Order]
User → CartScreen → CheckoutScreen → ShippingScreen → ReviewScreen
  → CreateOrderUseCase
    → BEGIN transaction
    → INSERT orders (status='payment_pending', total, shipping, user_id)
    → INSERT order_items (one per cart_item, with customization_snapshot AND qr_png_url)
    → upload pre-rasterized PNG to Supabase Storage `order-assets/{order_id}/`
    → INSERT payments (transaction_ref=unique, amount, status='pending')
    → COMMIT
  ← order_id, transaction_ref returned

[6. Checkout — Wompi]
User → "Pay" → LaunchWompiCheckoutUseCase
  → PaymentsService.openCheckout(transaction_ref, amount, redirect_url='qraft://payment-result')
  → opens Wompi Web Checkout (webview_flutter or external browser)
  → user completes payment
  → Wompi redirects to qraft://payment-result?id=...&status=...

[7. Webhook (parallel to redirect)]
Wompi → POST /functions/v1/wompi-webhook
  → verify X-Event-Checksum (SHA256)
  → INSERT payment_events (idempotency)
  → RPC apply_payment_event(transaction_ref, status)
    → IF APPROVED: UPDATE payments.status='approved', orders.status='paid'
    → IF DECLINED: UPDATE payments.status='declined', orders.status='payment_failed'
  → INSERT notifications (kind='payment_result', user_id, order_id)
  → DB webhook fires → send-fcm Edge Function → FCM push
  → INSERT notification (kind='new_order_for_ops') → notify-operator

[8. App receives result]
App deeplink handler (qraft://payment-result) → PaymentResultScreen
  → query orders.status (server-authoritative, ignores Wompi redirect status alone)
  → if paid → show success + navigate to order detail (StreamProvider on orders)

[9. Operator workflow]
Operator dashboard → loads orders WHERE status IN ('paid','received_by_ops','engraving','engraving_done')
  → marks "received" → RPC transition_order(order_id, 'received_by_ops')
  → marks "engraving" → RPC transition_order(order_id, 'engraving')
  → graba físicamente con XTool F1 Ultra (manual, fuera del sistema)
  → marks "done" → RPC transition_order(order_id, 'engraving_done')
  → uploads tracking → RPC transition_order(order_id, 'shipped', tracking_data)
  → each transition → DB trigger INSERT notifications → FCM to user

[10. User receives notifications]
FCM → app (background) → tap → deeplink to order detail → realtime stream shows latest state
```

### State Management

```
                        ┌──────────────────────┐
                        │ Riverpod Provider Scope│
                        └─────────┬────────────┘
                                  │
   ┌──────────────────────────────┼──────────────────────────────┐
   │                              │                              │
   ▼                              ▼                              ▼
qrCustomizationController   cartController                 orderStreamProvider(id)
(StateNotifier<QRCustomState>) (StateNotifier<CartState>)     (StreamProvider<Order>)
   │                              │                              │
   │ frame, eyes, colors, logo    │ items, totals (computed)     │ Supabase realtime
   │                              │                              │
   ▼                              ▼                              ▼
QrImageView preview           CartScreen UI                 OrderTimelineWidget
                              cartBadgeProvider (computed)
                                  │
                                  ▼
                              Hive (mirror) + Supabase cart_items (mirror)
```

### Key Data Flows

1. **QR creation → customization:** Domain entity `QRCodeEntity` flows through `QRGeneratorController` → persisted → loaded into `QRCustomizationController` for editing. Customization is a `copyWith` on the entity.
2. **Cart → order:** Cart items become order items with snapshotted customization JSONB. Cart is cleared on successful order creation (NOT on payment success — order persists as `payment_pending` if user abandons mid-checkout).
3. **Wompi events → user UI:** Webhook → DB update → realtime channel + FCM. UI receives via either path (whichever delivers first); both are idempotent (UI shows current DB state).
4. **Operator transition → user UI:** Operator dashboard RPC call → DB trigger → notifications row → send-fcm Edge Function → FCM. Realtime subscription picks up `orders.status` UPDATE if user has order detail open.
5. **QR library → marketplace preview:** User selects from `qr_library` → `qr_id` passed to marketplace product detail → live preview composites onto material image.

## Database Schema Sketch (New Tables)

```sql
-- =========================================================
-- QR templates (marketplace of pre-designed styles)
-- =========================================================
CREATE TABLE qr_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  thumbnail_url TEXT NOT NULL,
  style_payload JSONB NOT NULL,             -- QRStyle entity serialized
  category TEXT,                             -- 'minimal','colorful','business',...
  is_premium BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================
-- Marketplace catalog
-- =========================================================
CREATE TABLE materials (
  id TEXT PRIMARY KEY,                       -- 'wood','acrylic','metal','leather','glass','stone'
  display_name_es TEXT NOT NULL,
  display_name_en TEXT NOT NULL,
  texture_url TEXT NOT NULL,                 -- for material previews
  laser_compatible BOOLEAN DEFAULT true,
  notes JSONB                                -- engraving constraints
);

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name_es TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description_es TEXT,
  description_en TEXT,
  hero_image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  material_id TEXT NOT NULL REFERENCES materials(id),
  size_label TEXT NOT NULL,                  -- '10x10cm','5x5cm','llavero'
  width_mm INT NOT NULL,
  height_mm INT NOT NULL,
  price_cop INT NOT NULL,                    -- in COP cents (avoid float)
  sku TEXT UNIQUE,
  stock INT,                                 -- nullable = unlimited (made-to-order)
  is_active BOOLEAN DEFAULT true
);

-- =========================================================
-- Cart (cross-device persistent)
-- =========================================================
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_variant_id UUID NOT NULL REFERENCES product_variants(id),
  qr_code_id UUID NOT NULL REFERENCES qr_codes(id),
  customization_snapshot JSONB NOT NULL,     -- frozen at add-to-cart time
  quantity INT NOT NULL CHECK (quantity > 0),
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, product_variant_id, qr_code_id)
);

-- =========================================================
-- Orders + state machine
-- =========================================================
CREATE TYPE order_status AS ENUM (
  'payment_pending','payment_failed','paid',
  'received_by_ops','engraving','engraving_failed','engraving_done',
  'shipped','delivered','cancelled','refunded'
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL,         -- human readable e.g. 'QRA-2026-000123'
  user_id UUID NOT NULL REFERENCES auth.users(id),
  status order_status NOT NULL DEFAULT 'payment_pending',

  -- amounts (COP cents)
  subtotal_cop INT NOT NULL,
  tax_cop INT NOT NULL,                      -- IVA 19%
  shipping_cop INT NOT NULL,
  total_cop INT NOT NULL,

  -- shipping
  shipping_recipient_name TEXT NOT NULL,
  shipping_phone TEXT NOT NULL,
  shipping_department TEXT NOT NULL,
  shipping_city TEXT NOT NULL,
  shipping_address TEXT NOT NULL,
  shipping_notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  engraving_started_at TIMESTAMPTZ,
  engraving_done_at TIMESTAMPTZ,
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_ops_queue ON orders(status, created_at) WHERE status IN ('paid','received_by_ops','engraving','engraving_done');

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_variant_id UUID NOT NULL REFERENCES product_variants(id),
  qr_code_id UUID REFERENCES qr_codes(id) ON DELETE SET NULL,  -- preserve order if user deletes QR
  customization_snapshot JSONB NOT NULL,     -- engraver source-of-truth
  qr_png_url TEXT NOT NULL,                  -- pre-rasterized 2160px PNG in Storage
  unit_price_cop INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  line_total_cop INT NOT NULL
);

-- =========================================================
-- Payments (Wompi)
-- =========================================================
CREATE TYPE payment_status AS ENUM ('pending','approved','declined','voided','error','refunded');

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  transaction_ref TEXT UNIQUE NOT NULL,      -- our ref, sent to Wompi
  wompi_transaction_id TEXT,                 -- Wompi's id, set on first event
  amount_cop INT NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  payment_method TEXT,                        -- 'CARD','PSE','NEQUI','BANCOLOMBIA_TRANSFER',...
  raw_payload JSONB,                          -- last event body for audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payment_events (                 -- idempotency log
  event_id TEXT PRIMARY KEY,                  -- Wompi event id, UNIQUE
  payment_id UUID REFERENCES payments(id),
  kind TEXT NOT NULL,                         -- 'transaction.updated', etc.
  payload JSONB NOT NULL,
  received_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================
-- Shipments
-- =========================================================
CREATE TABLE shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  carrier TEXT NOT NULL,                      -- 'Servientrega','Coordinadora','Interrapidisimo',...
  tracking_number TEXT NOT NULL,
  tracking_url TEXT,
  shipped_at TIMESTAMPTZ NOT NULL,
  estimated_delivery_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);

-- =========================================================
-- Notifications (drives FCM via send-fcm Edge Function)
-- =========================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,                         -- 'payment_approved','order_engraving','order_shipped',...
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,                                 -- {order_id: ...} for deeplink
  fcm_state TEXT DEFAULT 'pending',           -- 'pending','sent','failed'
  fcm_retries INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ
);

CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL,                     -- 'ios','android'
  device_label TEXT,
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- RLS: every table SELECT/UPDATE restricted to user_id = auth.uid()
-- Operator role bypasses via service_role key (used only by ops dashboard auth)
```

### Schema Decisions

- **COP in integer cents (`*_cop INT`):** Floats lose precision; ints with cent discipline avoid Wompi/IVA rounding bugs. 1,000,000 COP = 100,000,000 (overflow safe in INT4 up to ~21M COP; consider BIGINT if expecting >$5K USD orders, but unlikely v1.0).
- **`order_items.customization_snapshot` + `qr_png_url`:** Belt-and-suspenders. Engraver gets the rendered PNG (no Flutter dependency on ops side); if PNG is corrupted, can re-render from JSONB.
- **`payment_events.event_id PRIMARY KEY`:** Idempotency cornerstone. Insert-or-fail pattern.
- **`order_items.qr_code_id` ON DELETE SET NULL:** Preserve order history even if user deletes the QR from library after fulfillment.
- **`order_number` separate from UUID `id`:** UUIDs are for systems; order numbers are for humans (customer service, invoices).
- **Indexes on `(status, created_at)`:** Operator dashboard queries this constantly; without it, full-table scan as orders grow.
- **`notifications` table is the queue:** Decouples app/operator transitions from FCM delivery. Retries possible.

## Build Order (Phase Recommendations)

The roadmap should sequence phases by **dependency direction**, not by user-visible value. Below is the dependency graph:

```
                 ┌──────────────────────────────────┐
                 │ Existing baseline (Auth, Splash, │
                 │ Supabase, Riverpod, GlassButton) │
                 └────────────────┬─────────────────┘
                                  │
              ┌───────────────────┼─────────────────────┐
              ▼                   ▼                     ▼
  Phase A: QR Generation   Phase B: QR Scanner   (independent of marketplace)
   (data-type forms,        (resolve mobile_       — can ship in parallel
    qr_flutter render,      scanner iOS block,
    library CRUD)           SCAN-01)
              │
              ▼
  Phase C: QR Customization & Templates
   (style entity, color picker, eye/frame, logo,
    template gallery, validate-logo-size, render preview)
              │
              ▼  (customization → preview → material preview)
              │
              ├──────────────────────────────────────┐
              ▼                                      ▼
  Phase D: Marketplace Catalog          Phase E: QR Export Pipeline
   (products, variants, materials,        (RepaintBoundary→PNG/PDF,
    material preview, FilterBar)           Storage upload, share sheet)
              │                                      │
              └──────────────┬───────────────────────┘
                             ▼
              Phase F: Cart & Persistence
               (Hive + Supabase, totals, IVA, shipping)
                             │
                             ▼
              Phase G: Checkout + Wompi Integration
               (shipping form, order creation, Wompi widget,
                webhook Edge Function, idempotency, deep-link)
                             │
                             ▼
              Phase H: Orders Module + Realtime
               (order list, detail with timeline,
                StreamProvider, FCM notifications)
                             │
                             ▼
              Phase I: Operator Dashboard
               (Flutter Web build OR Supabase Studio,
                state transition RPCs, shipment upload)
                             │
                             ▼
              Phase J: Polish (OPT-01/02/03)
               (performance, animations,
                Crashlytics, observability)
                             │
                             ▼
              Phase K: Subscriptions Premium (MKT-10)
               (RevenueCat extension already partially
                in codebase — finalize)
```

### Phase Ordering Rationale

- **A & B parallel:** Scanner (mobile_scanner iOS block) is independent. Don't block QR gen on it.
- **C before D:** Marketplace material preview NEEDS customized QR rendering; cannot show "your QR on wood" without QR style engine.
- **D & E parallel after C:** Catalog browsing and export pipeline are independent.
- **F after D + E:** Cart needs both products (D) AND pre-rasterized PNG capability (E, for order creation).
- **G after F:** Checkout creates orders; cart is the input.
- **H after G:** Orders module is meaningful only when orders can be created.
- **I after H:** Operator dashboard manipulates orders; orders must exist + have realtime/notifications wiring.
- **J after I:** Polish whole flow once functional.
- **K can shift earlier:** RevenueCat is partially in codebase; if business pressure pushes premium, can be K' = parallel to D-F.

### What Unlocks What

| Phase | Unlocks |
|-------|---------|
| A (QR gen) | C, D-preview, library |
| B (Scanner) | scan_history (already in DB) |
| C (Customize) | D-preview, E (need style data to export) |
| D (Catalog) | F (cart needs products) |
| E (Export) | F (order needs PNG), G (operator needs PNG) |
| F (Cart) | G (checkout needs cart) |
| G (Checkout+Wompi) | H (orders exist) |
| H (Orders+Realtime) | I (operator manipulates) |
| I (Operator) | end-to-end loop closed |
| J (Polish) | production launch |

### Component Boundaries (What Talks to What)

```
qr_generator        ───────► qr_codes table
qr_customization    ───────► qr_codes (UPDATE), qr_templates (READ)
qr_export           ───────► Storage (uploads PNG)
marketplace         ───────► products, variants, materials (READ)
                    ── reads ► qr_codes (for previews)
cart                ───────► cart_items, products (READ)
                    ── reads ► qr_codes (for snapshots)
checkout            ───────► orders, order_items, payments (CREATE)
                    ── reads ► cart_items, qr_codes
                    ── calls ► payments_service (Wompi)
                    ── calls ► qr_export (rasterize)
orders              ───────► orders, order_items, shipments (READ)
                    ── subscribes ► orders realtime
notifications       ───────► user_fcm_tokens (UPSERT)
                    ── handles ► FCM messages

Edge: wompi-webhook ───────► payments, orders, payment_events, notifications
Edge: send-fcm      ───── reads ► notifications, user_fcm_tokens
                    ───── calls ► FCM HTTP v1
Edge: notify-operator ── reads ► orders
                    ── sends ► email/Slack/dashboard
```

**Boundary rule:** Features NEVER cross-import each other's `data/` or `presentation/` layers. Allowed cross-feature reads happen via:
- Domain entity references (e.g., `cart_item.qr_code_id` is a string ID; cart doesn't import qr_generator's repository)
- Provider composition (e.g., a screen-level provider may `ref.watch` providers from two features and combine)

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-100 orders/month (v1.0 launch) | Manual operator dashboard, single Wompi account, Edge Functions free tier, Supabase free/pro tier. Current architecture is sufficient. |
| 100-1k orders/month | Add basic operator features: bulk status update, search, filters by city/material. Possibly add Hookdeck or Inngest for webhook reliability if free Edge Function quota strains. |
| 1k+ orders/month | Production printer queue (multiple operators), order auto-assignment, SLA tracking. Consider materializing operator views with `pg_cron`. Move FCM logic to a queue (RabbitMQ / GCP Pub/Sub) if notifications backlog. |
| Multi-machine future (post-v1.0) | Add `production_assignments` table, machine API integration. Architecture unchanged — just new feature module. |

### Scaling Priorities

1. **First bottleneck:** Operator throughput (manual). Mitigation: better dashboard UX (filters, batch transitions). Database is not the bottleneck at this scale.
2. **Second bottleneck:** Wompi webhook delivery reliability. Mitigation: Wompi already retries; Edge Function idempotency makes retries safe. If Edge Function downtime correlates with payment events, add a polling reconciliation job (`pg_cron` querying Wompi GET /transactions for `payment_pending` orders >5min old).
3. **Third bottleneck:** Storage costs from pre-rasterized PNGs. Mitigation: lifecycle policy — delete `order-assets/{order_id}/` 90 days after delivery (engraver no longer needs).

## Anti-Patterns

### Anti-Pattern 1: Trusting Wompi redirect for order status

**What people do:** App reads `?status=APPROVED` from the deep-link redirect and updates local order to "paid".
**Why it's wrong:** Redirect URL parameters can be spoofed by an attacker who knows the schema. Also, redirect can fire before the webhook completes the DB transition.
**Do this instead:** Redirect navigates to PaymentResultScreen which queries `orders.status` from Supabase (server-authoritative). Show "verifying payment..." spinner if still `payment_pending`; auto-refresh via realtime.

### Anti-Pattern 2: Mutating QR after order placement

**What people do:** Customer edits a QR in their library → engraver receives the edited version.
**Why it's wrong:** Customer ordered version A, engraver burns version B. Refund/dispute risk.
**Do this instead:** `order_items.customization_snapshot` is JSONB frozen at order creation. `qr_png_url` is the pre-rasterized 2160px PNG in Storage. Engraver consumes EITHER (PNG primary, JSON fallback). Library edits never propagate.

### Anti-Pattern 3: Operator dashboard inside the consumer app behind a flag

**What people do:** Add a hidden "/admin" tab in the consumer Flutter app.
**Why it's wrong:** Mobile UX is wrong for ops (small screens, no batch ops, limited keyboard). Mixes user/admin concerns. RLS bypass risk.
**Do this instead:** Either (a) Flutter Web build of a dedicated `lib_operator/` directory with its own ProviderScope and `service_role` Supabase auth, OR (b) Supabase Studio + a few RPC functions exposed via the Studio SQL editor. Option (b) ships fastest; (a) is the right v1.1 evolution.

### Anti-Pattern 4: Cart state in `SharedPreferences` only

**What people do:** Hive/SharedPrefs as sole source of truth.
**Why it's wrong:** User reinstalls → cart lost. Cross-device cart impossible. Premium feature gap.
**Do this instead:** Hybrid pattern (see Pattern 4). Local for instant UX, remote for durability.

### Anti-Pattern 5: Computing IVA/totals client-side as the source of truth

**What people do:** Flutter computes subtotal + 19% + shipping → sends total to Wompi.
**Why it's wrong:** Tampered build can pay any amount. Wompi accepts whatever amount the merchant sends.
**Do this instead:** Show client-side preview total. At order creation, server-side function `compute_order_totals(cart_items)` computes from `product_variants.price_cop` and CONFIG-defined IVA rate. Server-computed total is what goes to Wompi. Mismatch between preview and server = display server's total + warn user.

### Anti-Pattern 6: Skipping idempotency on the webhook

**What people do:** Trust that Wompi only delivers once.
**Why it's wrong:** Wompi explicitly retries on non-2xx responses; network blips cause duplicates. Result: order transitions twice = double FCM, possible data corruption.
**Do this instead:** `payment_events.event_id PRIMARY KEY` insert-or-fail. Process only on successful insert.

### Anti-Pattern 7: Embedding logo with default error correction

**What people do:** Use `qr_flutter` with default M-level EC and embed any-sized logo.
**Why it's wrong:** Logo covers data modules → scan failure → physical product unusable → refund.
**Do this instead:** Domain rule (validate_logo_size_use_case): if `logo != null` then `error_correction = H` AND `logo.size_pct <= 0.25`. Test scan in QA before shipping a customization version.

### Anti-Pattern 8: Single Wompi public key in client without integrity hash

**What people do:** Hardcode Wompi public key, send transaction without integrity signature.
**Why it's wrong:** Wompi requires `integrity_signature` for amount tampering protection on widget integration.
**Do this instead:** Compute `sha256(reference + amount + currency + integrity_secret)` server-side (Edge Function `create_payment_intent` returns `transaction_ref`, `amount`, `signature`). Client passes signature to Wompi widget. Integrity secret never touches client.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Wompi (payments) | Web Checkout via `webview_flutter` + webhook Edge Function. Public key in client; integrity secret + events secret server-side only. | Verify X-Event-Checksum (SHA256) on EVERY event. Use `transaction.updated` events. Final states: APPROVED/DECLINED/VOIDED/ERROR. |
| Supabase Auth | Existing — extend RLS policies for new tables. | All new tables get policies: `user_id = auth.uid()` for SELECT, restricted writes via RPC functions. |
| Supabase Postgres | Existing — add migrations for marketplace/orders/payments. | Use enum types for status fields (compile-time safety). Indexes critical for operator queries. |
| Supabase Realtime | Subscribe to `orders` UPDATE filtered by `user_id`. | Used for order detail screen. RLS automatically enforced. |
| Supabase Storage | New buckets: `order-assets/` (private, RLS-protected), `material-textures/` (public read). | PNG uploads happen at order creation, not at cart. |
| Supabase Edge Functions | Deno runtime. Three functions: wompi-webhook, send-fcm, notify-operator. | First two are webhook-triggered (no JWT required, set in `config.toml`); third is DB-trigger-driven. |
| Firebase Cloud Messaging | FCM HTTP v1 API from send-fcm Edge Function. App registers token via `firebase_messaging` plugin. | Existing Firebase project (`qraft-e8a1d`) already configured for Auth — add FCM scope. Tokens stored in `user_fcm_tokens`. |
| Google AdMob | Existing — keep separate from monetization-of-orders flow. | No interaction with marketplace path. |
| RevenueCat | Existing — for subscriptions only. | Premium tier may unlock advanced templates, larger logo size, bulk QR; integration point is `feature_gate_providers`. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| qr_generator ↔ qr_customization | Domain entity (`QRCodeEntity` passed as parameter) | qr_customization READS, doesn't write to qr_generator's datasource. Updates flow through use case → repository. |
| qr_customization ↔ qr_export | Direct service call (`QRRasterizerService`) | Export consumes the live `RepaintBoundary` key. No state coupling. |
| marketplace ↔ qr_library | Provider composition in screen | `productPreviewProvider` watches both. |
| cart ↔ checkout | `CartState` read-only by checkout | Checkout takes `CartState` as input to CreateOrderUseCase. Cart cleared on order creation success. |
| checkout ↔ payments_service | Direct service call | `LaunchWompiCheckoutUseCase` orchestrates. |
| orders ↔ Supabase realtime | StreamProvider via Supabase channel | Channel filter: `order_id = :id AND user_id = auth.uid()`. |
| Operator dashboard ↔ orders | RPC functions only (`transition_order`, `record_shipment`) | NO direct UPDATE on `orders` table from any client. Service role bypasses RLS but still calls RPC for FSM validation. |
| consumer app ↔ Edge Functions | Indirect — never call directly. | Edge Functions are webhook-receivers and DB-trigger-driven. App reads results via DB queries. |

## Sources

- [Wompi Events Documentation (signatures, X-Event-Checksum, transaction states)](https://docs.wompi.co/en/docs/colombia/eventos/)
- [Wompi Transactions Documentation (final states APPROVED/DECLINED/VOIDED/ERROR)](https://docs.wompi.co/en/docs/colombia/transacciones/)
- [Wompi Widget & Checkout Web Documentation](https://docs.wompi.co/en/docs/colombia/widget-checkout-web/)
- [Wompi Quick Start](https://docs.wompi.co/en/docs/colombia/inicio-rapido/)
- [Supabase Edge Functions: Stripe Webhooks Example (idempotency pattern)](https://supabase.com/docs/guides/functions/examples/stripe-webhooks)
- [Supabase Edge Function Error Handling, Retries, Logging, and Idempotency](https://dev.to/kanta13jp1/supabase-edge-function-error-handling-retries-logging-and-idempotency-2nh0)
- [Supabase Sending Push Notifications via FCM Edge Functions](https://supabase.com/docs/guides/functions/examples/push-notifications)
- [Supabase Database Webhooks](https://supabase.com/docs/guides/database/webhooks)
- [Real-Time Push Notifications with Supabase Edge Functions and Firebase (architecture)](https://medium.com/@vignarajj/real-time-push-notifications-with-supabase-edge-functions-and-firebase-581c691c610e)
- [qr_flutter package on pub.dev (embeddedImage, embeddedImageStyle, error correction)](https://pub.dev/packages/qr)
- [QR.Flutter GitHub - logo embedding issues at high coverage](https://github.com/theyakka/qr.flutter/issues/142)
- [Pageloot — Guidelines for Adding a Logo to a QR Code (25% rule, EC level H)](https://pageloot.com/blog/how-to-add-logos-to-qr-codes/)
- [Flutter RepaintBoundary class API](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- [Flutter RenderRepaintBoundary toImage() with pixelRatio](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
- [Exporting QR Codes in Flutter (RepaintBoundary→PNG pattern)](https://medium.com/codex/exporting-qr-codes-in-flutter-dd30220fcba4)
- [Flutter App Architecture with Riverpod (Code with Andrea — domain/data/presentation)](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
- [Flutter Riverpod 2.0 Ultimate Guide](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
- [Order State Machine pattern (state transitions, FSM enforcement)](https://medium.com/@udaykale/evolving-the-state-design-pattern-e6682a866fdd)
- [E-commerce Order State Machine Architecture (state pattern in fulfillment)](https://jinlow.medium.com/understanding-the-state-pattern-a-deep-dive-into-e-commerce-order-management-architecture-744b9f0761ab)

---
*Architecture research for: QRaft Flutter + Supabase + Wompi marketplace with manual laser fulfillment*
*Researched: 2026-05-01*
