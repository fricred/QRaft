---
phase: 08-cart-customization-snapshot
plan: "02"
subsystem: cart-ui
tags: [flutter, riverpod, cart, ui, shimmer, semantics]

requires:
  - phase: 08-01
    provides: cartRepositoryProvider + cartItemsProvider + CartItemEntity + CartException

provides:
  - CartScreen (full item list UI with empty state, shimmer, error retry)
  - CartItemTile (quantity controls ± capped 99, swipe/tap remove, Semantics identifiers)
  - ProductDetailScreen wired Agregar al carrito button (real addItem call + navigate)

affects:
  - 08-03 (PNG thumbnail upload — cart_item_tile shows icon until pngStorageUrl populated)
  - 09-checkout (CartSummaryPlaceholder stub awaits Phase 9 checkout button wire-up)

tech-stack:
  added: []
  patterns:
    - "ConsumerStatefulWidget pattern for async button loading state (_isLoading bool)"
    - "cartItemsProvider StreamProvider.when() driving three UI paths: loading/error/data"
    - "Quantity decrement-to-zero triggers removeItem (not updateQuantity) — T-08-02-01 mitigation"
    - "CartException caught in _addToCart and _safeCall; SnackBar message surfaced to user"
    - "Semantics(identifier:) on CartItemTile and remove button for Maestro automation"

key-files:
  created:
    - lib/features/cart/presentation/pages/cart_screen.dart
    - lib/features/cart/presentation/widgets/cart_item_tile.dart
  modified:
    - lib/features/marketplace/presentation/pages/product_detail_screen.dart

key-decisions:
  - "ProductDetailScreen converted to ConsumerStatefulWidget (not StatefulWidget + HookConsumerWidget) to stay consistent with app-wide ConsumerStatefulWidget pattern"
  - "CartSummaryPlaceholder shows snackbar stub — Phase 9 replaces with real server_compute_order_totals RPC total"
  - "CartItemTile product name derived from customizationSnapshot['product_name'] with 'Producto' fallback; real variant name lookup deferred to phase when product catalog query is co-located"
  - "QR thumbnail always shows Icons.qr_code_2_rounded until Plan 03 populates pngStorageUrl"

requirements-completed:
  - MKT-03

duration: 2min
completed: 2026-05-03
---

# Phase 8 Plan 02: Cart UI + AddToCart Button Summary

**CartScreen + CartItemTile + wired Agregar al carrito button delivering the complete user-visible cart experience**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-03T16:37:12Z
- **Completed:** 2026-05-03T16:39:27Z
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 modified)

## Accomplishments

- ProductDetailScreen converted from ConsumerWidget to ConsumerStatefulWidget; "Agregar al carrito" button replaced snackbar stub with real CartRepository.addItem() call including auth guard, QR-selection guard, customizationSnapshot, and navigation to CartScreen on success
- CartScreen delivers all three stream states: 3-rectangle shimmer skeleton, error + retry, and item list with CartSummaryPlaceholder stub
- CartItemTile has full quantity control (increment/decrement; decrement-to-zero triggers removeItem; cap at 99 per T-08-02-01) and delete button; Semantics identifiers on tile + remove for Maestro automation

## Task Commits

1. **Task 1: Wire Agregar al carrito button** — `1a9ccce` (feat)
2. **Task 2: CartScreen + CartItemTile** — `79aa86b` (feat)

## Files Created/Modified

- `lib/features/marketplace/presentation/pages/product_detail_screen.dart` — ConsumerStatefulWidget with _addToCart(), _isLoading state, cartRepositoryProvider.addItem(), CartScreen navigation
- `lib/features/cart/presentation/pages/cart_screen.dart` — Full cart UI: shimmer, error retry, empty state, ListView, _CartSummaryPlaceholder
- `lib/features/cart/presentation/widgets/cart_item_tile.dart` — Single item row: QR icon, product name, quantity ±, remove button, Semantics identifiers

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| QR thumbnail = Icons.qr_code_2_rounded | cart_item_tile.dart | 35 | pngStorageUrl is null until Plan 03 uploads PNG |
| Checkout button = SnackBar placeholder | cart_screen.dart | 171 | Phase 9 checkout flow wires real payment button |
| Product name = 'Producto' fallback | cart_item_tile.dart | 95 | variant name lookup deferred; snapshot key 'product_name' used if present |

These stubs do not prevent Plan 08-02's goal (cart item list UI is fully functional).

## Self-Check: PASSED

Files exist:
- FOUND: lib/features/cart/presentation/pages/cart_screen.dart
- FOUND: lib/features/cart/presentation/widgets/cart_item_tile.dart
- FOUND: lib/features/marketplace/presentation/pages/product_detail_screen.dart (modified)

Commits:
- FOUND: 1a9ccce
- FOUND: 79aa86b
