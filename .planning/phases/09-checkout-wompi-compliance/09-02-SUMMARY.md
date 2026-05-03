---
phase: 09-checkout-wompi-compliance
plan: 02
subsystem: checkout
tags: [supabase, edge-function, wompi, payments, flutter, shipping, dane, rls]

# Dependency graph
requires:
  - phase: 09-checkout-wompi-compliance
    plan: 01
    provides: orders/payments tables, create_order RPC, apply_payment_event RPC
  - phase: 08-cart-customization-snapshot
    provides: cart_items table, cartItemsProvider, CartItemEntity

provides:
  - create-payment-intent Supabase Edge Function (Deno, server-side integrity hash)
  - ShippingAddress domain entity with toJson() matching create_order RPC p_shipping JSONB
  - CheckoutSession.fromJson() / toJson()
  - WompiPaymentConfig (core/config)
  - PaymentsService + PaymentServiceException
  - CreateOrderUseCase (UUID v4 idempotency key per attempt)
  - CheckoutRepositoryImpl
  - checkout_providers (shippingAddressProvider, createOrderProvider.family)
  - ShippingScreen with DANE cascading dropdowns (33 departments, all municipalities)
  - CartScreen button wired to ShippingScreen (replaces SnackBar stub)
  - assets/data/colombia_dane.json (<100KB)

affects:
  - 09-03 (WompiWebViewScreen receives CheckoutSession from ShippingScreen)
  - 09-04 (Wompi webhook calls apply_payment_event on the order created here)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Server-side integrity signature via crypto.subtle (T-09-06)
    - Idempotency key as UUID v4 per checkout attempt; stored as payments.transaction_ref UNIQUE
    - DANE cascading dropdowns loaded from bundled JSON asset (offline-capable)
    - PaymentsService.createPaymentIntent → functions.invoke (JWT auto-forwarded by supabase_flutter)

key-files:
  created:
    - supabase/functions/create-payment-intent/index.ts
    - lib/core/config/wompi_config.dart
    - lib/core/services/payments_service.dart
    - lib/features/checkout/domain/entities/shipping_address.dart
    - lib/features/checkout/domain/use_cases/create_order_use_case.dart
    - lib/features/checkout/data/repositories/checkout_repository_impl.dart
    - lib/features/checkout/presentation/providers/checkout_providers.dart
    - lib/features/checkout/presentation/pages/shipping_screen.dart
    - assets/data/colombia_dane.json
  modified:
    - lib/features/checkout/domain/entities/checkout_session.dart
    - lib/features/cart/presentation/pages/cart_screen.dart
    - pubspec.yaml

key-decisions:
  - "Integrity signature computed server-side in Edge Function via crypto.subtle (Deno built-in); Flutter binary never sees WOMPI_INTEGRITY_SECRET (T-09-06)"
  - "Amount in cents fetched from orders.total_cop after create_order RPC completes; client has no amount field in the request body (T-09-07)"
  - "Edge Function uses service_role Supabase client for RPC calls to bypass user RLS"
  - "Idempotency: duplicate 23505 error from create_order RPC triggers lookup of existing order by transaction_ref"
  - "DANE dataset bundled as JSON asset (offline-capable, no API calls, <100KB)"
  - "CartScreen uses direct MaterialPageRoute push to ShippingScreen (no GoRouter needed for linear stack)"

# Metrics
duration: 5min
completed: 2026-05-03
---

# Phase 9 Plan 02: create-payment-intent Edge Function + ShippingScreen Summary

**Deno Edge Function computes Wompi integrity hash server-side (crypto.subtle) and returns a pre-built checkout URL; ShippingScreen collects DANE-validated Colombian address and drives the full cart-to-checkout navigation path**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-03T17:20:33Z
- **Completed:** 2026-05-03T17:25:13Z
- **Tasks completed:** 2 of 3 (stopped at checkpoint:human-verify as expected)
- **Files created/modified:** 11

## Accomplishments

- `create-payment-intent` Edge Function: JWT-authenticated, calls `create_order` RPC, fetches server-authoritative total, computes SHA-256 integrity signature with `crypto.subtle`, builds Wompi Web Checkout URL, returns `{order_id, transaction_ref, integrity_signature, wompi_checkout_url, amount_cop}` — no secrets in response
- `ShippingAddress` entity serializes to exact JSON shape expected by `create_order` RPC `p_shipping` parameter
- `CheckoutSession.fromJson()` and `toJson()` added (Plan 03 WebView already uses this entity)
- `PaymentsService.createPaymentIntent()` invokes Edge Function via `Supabase.instance.client.functions.invoke`; catches `FunctionException` and redacts shipping fields from error messages (T-09-10)
- `CreateOrderUseCase` generates a fresh UUID v4 per checkout attempt
- `ShippingScreen`: DANE cascading dropdowns (33 departments → municipalities from bundled JSON), phone Colombian regex validator, Semantics identifiers matching CONVENTIONS.md
- `CartScreen._onProceedToCheckout()`: SnackBar stub replaced with `Navigator.push` to `ShippingScreen`

## Task Commits

1. **Task 1: create-payment-intent Edge Function + Flutter checkout domain** — `dfb7e90`
2. **Task 2: ShippingScreen with DANE dropdowns + wire CartScreen** — `6552b94`

## Files Created/Modified

- `supabase/functions/create-payment-intent/index.ts` — Deno Edge Function: JWT extraction, create_order RPC, order total fetch, SHA-256 integrity hash, Wompi URL builder
- `lib/core/config/wompi_config.dart` — `WompiPaymentConfig` with public key, base URLs, redirect deep link
- `lib/core/services/payments_service.dart` — `PaymentsService` + `PaymentServiceException`
- `lib/features/checkout/domain/entities/shipping_address.dart` — `ShippingAddress` Equatable entity with `toJson()`
- `lib/features/checkout/domain/entities/checkout_session.dart` — Added `fromJson()` + `toJson()` to existing entity
- `lib/features/checkout/domain/use_cases/create_order_use_case.dart` — `CreateOrderUseCase`
- `lib/features/checkout/data/repositories/checkout_repository_impl.dart` — `CheckoutRepositoryImpl`
- `lib/features/checkout/presentation/providers/checkout_providers.dart` — `shippingAddressProvider` + `createOrderProvider.family`
- `lib/features/checkout/presentation/pages/shipping_screen.dart` — `ShippingScreen` ConsumerStatefulWidget
- `lib/features/cart/presentation/pages/cart_screen.dart` — `_onProceedToCheckout` navigates to `ShippingScreen`
- `pubspec.yaml` — Adds `assets/data/` bundle
- `assets/data/colombia_dane.json` — 33 DANE departments + municipalities, <100KB

## Decisions Made

- Integrity signature computed in Edge Function via `crypto.subtle` (Deno built-in) — avoids third-party SHA-256 import
- Client provides `cart_item_ids` + `shipping` + `idempotency_key`; amount is NOT a client input — fetched from `orders.total_cop` after `create_order` (T-09-07)
- Duplicate order idempotency: `23505` from `create_order` RPC → look up existing `payments.transaction_ref` and reuse `order_id`
- DANE dataset bundled as a JSON asset file for offline-capable department/city selection without an API dependency
- `MaterialPageRoute` push for ShippingScreen → avoids GoRouter refactor in this plan (route is linear stack from cart)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `FormBuilderValidators.match` requires `RegExp`, not `String`**
- **Found during:** Task 2 verification (flutter analyze)
- **Issue:** Plan spec used a raw string for the phone regex; `form_builder_validators ^11.x` `match()` requires a `RegExp` argument
- **Fix:** Wrapped regex literal in `RegExp(r'...')` on the `match()` call
- **Files modified:** `lib/features/checkout/presentation/pages/shipping_screen.dart`
- **Commit:** 6552b94

## Known Stubs

None — all checkout flow is wired. `PaymentResultScreen` has a placeholder (`OrderDetailPlaceholder`) from Plan 03, but that is tracked in the Plan 03 summary and is out of scope here.

## Threat Flags

No new security-relevant surface beyond what is listed in the plan's threat model.

All T-09-06 through T-09-10 mitigations are implemented:
| Threat | Mitigation |
|--------|-----------|
| T-09-06: WOMPI_INTEGRITY_SECRET in Flutter binary | Secret accessed only in Edge Function `Deno.env.get()`; never returned in response |
| T-09-07: Amount tampered client-side | Amount fetched from `orders.total_cop` (server-computed by `create_order` RPC) |
| T-09-08: Unauthenticated Edge Function call | JWT verification enabled (default); function extracts `sub` from Bearer token |
| T-09-09: Duplicate order on retry | `23505` unique_violation on `payments.transaction_ref` → idempotent retry path |
| T-09-10: ShippingAddress in logs | `PaymentServiceException` logs only HTTP status code; no address fields |

## Self-Check: PASSED

- `supabase/functions/create-payment-intent/index.ts` — FOUND
- `lib/core/config/wompi_config.dart` — FOUND
- `lib/core/services/payments_service.dart` — FOUND
- `lib/features/checkout/domain/entities/shipping_address.dart` — FOUND
- `lib/features/checkout/domain/entities/checkout_session.dart` — FOUND (updated)
- `lib/features/checkout/domain/use_cases/create_order_use_case.dart` — FOUND
- `lib/features/checkout/data/repositories/checkout_repository_impl.dart` — FOUND
- `lib/features/checkout/presentation/providers/checkout_providers.dart` — FOUND
- `lib/features/checkout/presentation/pages/shipping_screen.dart` — FOUND
- `lib/features/cart/presentation/pages/cart_screen.dart` — FOUND (updated)
- `assets/data/colombia_dane.json` — FOUND
- Commit `dfb7e90` — FOUND
- Commit `6552b94` — FOUND
