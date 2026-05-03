---
phase: 08-cart-customization-snapshot
plan: "03"
subsystem: cart-snapshot
tags: [flutter, riverpod, cart, supabase-storage, qr-export, snapshot, tdd]

requires:
  - phase: 08-01
    provides: CartRepository + CartException + cartRepositoryProvider
  - phase: 08-02
    provides: ProductDetailScreen._addToCart stub + CartItemTile icon placeholder

provides:
  - CustomizationSnapshotService (buildSnapshotJson + captureSnapshot)
  - SnapshotResult (customizationJson + pngBytes)
  - OrderAssetsStorageDataSource (upload + patchPngUrl + storagePath)
  - orderAssetsStorageDsProvider (Riverpod provider)
  - ProductDetailScreen._addToCart wired with snapshot pipeline
  - CartItemTile QR thumbnail via CachedNetworkImage

affects:
  - 09-checkout (PNG signed URL stored in cart_items.png_storage_url; Phase 9 regenerates at order creation)

tech-stack:
  added: []
  patterns:
    - "TDD RED/GREEN: failing tests committed before implementation; 4/4 tests pass GREEN"
    - "unawaited() pattern for non-blocking PNG upload (cart item lives even if PNG upload fails)"
    - "CustomizationSnapshotService.buildSnapshotJson() is pure — no Flutter binding; safe for unit tests"
    - "QrDecorationBuilder.buildQrImage() with hasLogo=true forces EC-H for all print-safe snapshots"
    - "OrderAssetsStorageDataSource uses upsert=true for idempotent retry safety"
    - "Signed URL valid 1h; Phase 9 regenerates at order creation time"
    - "CartItemTile _QrThumbnail: CachedNetworkImage with icon fallback (handles null pngStorageUrl gracefully)"

key-files:
  created:
    - lib/features/cart/domain/services/customization_snapshot_service.dart
    - lib/features/cart/data/datasources/order_assets_storage_data_source.dart
    - test/features/cart/domain/services/customization_snapshot_service_test.dart
  modified:
    - lib/features/marketplace/presentation/pages/product_detail_screen.dart
    - lib/features/cart/presentation/providers/cart_providers.dart
    - lib/features/cart/presentation/widgets/cart_item_tile.dart

key-decisions:
  - "Used QrDecorationBuilder.buildQrImage() with a hasLogo=true override to force EC-H rather than constructing QrImage(data:, errorCorrectLevel:) directly — the pretty_qr_code QrImage factory takes a QrCode object, not raw data"
  - "Uint8List cannot be faked (final class) — registered a real Uint8List(0) instance as mocktail fallback"
  - "patchPngUrl uses direct Supabase query rather than CartRepository to keep repository interface minimal (SRP)"
  - "catch variable renamed _ → e in _uploadSnapshotPng to allow $e interpolation inside assert closure"

requirements-completed:
  - MKT-12

duration: 4min
completed: 2026-05-03
---

# Phase 8 Plan 03: Customization Snapshot Capture Summary

**Snapshot pipeline: QRCustomization frozen to JSONB + 2160px PNG rasterized and uploaded to Supabase Storage order-assets/ at add-to-cart time, satisfying MKT-12**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-03T16:42:32Z
- **Completed:** 2026-05-03T16:46:52Z
- **Tasks:** 2
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `CustomizationSnapshotService` implements both `buildSnapshotJson()` (pure, unit-testable) and `captureSnapshot()` (async, rasterizes 2160px PNG via `QrExportService.exportPrintSafe`); the JSON snapshot merges all `QRCustomization` fields with `data`/`display_data`/`qr_type` for the engraver
- `OrderAssetsStorageDataSource` uploads PNG bytes to `order-assets/` bucket using `uploadBinary` with `upsert=true`; returns a 1h signed URL; wraps `StorageException` in `CartException('png_upload_failed', ...)`
- `ProductDetailScreen._addToCart` now calls `captureSnapshot()` before `addItem()`; PNG upload runs `unawaited` — cart item is created even if Storage is unavailable
- `CartItemTile` replaces the icon stub with `_QrThumbnail`, which shows `CachedNetworkImage(pngStorageUrl)` when available and falls back to the QR icon gracefully
- `orderAssetsStorageDsProvider` added to `cart_providers.dart` for injection flexibility in tests

## Task Commits

1. **RED — failing tests** — `8cc89db` (test)
2. **Task 1: CustomizationSnapshotService + OrderAssetsStorageDataSource** — `acb0d0b` (feat)
3. **Task 2: Wire snapshot capture into ProductDetailScreen + CartItemTile** — `73ad8c0` (feat)

## Files Created/Modified

- `lib/features/cart/domain/services/customization_snapshot_service.dart` — SnapshotResult + CustomizationSnapshotService (buildSnapshotJson + captureSnapshot)
- `lib/features/cart/data/datasources/order_assets_storage_data_source.dart` — Storage upload + patchPngUrl + storagePath
- `test/features/cart/domain/services/customization_snapshot_service_test.dart` — 4 unit tests (TDD RED/GREEN)
- `lib/features/marketplace/presentation/pages/product_detail_screen.dart` — _addToCart wired with captureSnapshot + unawaited _uploadSnapshotPng
- `lib/features/cart/presentation/providers/cart_providers.dart` — orderAssetsStorageDsProvider added
- `lib/features/cart/presentation/widgets/cart_item_tile.dart` — _QrThumbnail replaces icon placeholder

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] QrImage factory takes QrCode object, not data string**
- **Found during:** Task 1 GREEN phase
- **Issue:** Plan specified `QrImage(data: ..., errorCorrectLevel: ...)` but the actual `pretty_qr_code` `QrImage` factory is `QrImage(QrCode qrCode)`. The named-parameter form used in the plan's pseudo-code does not exist in this version.
- **Fix:** Used `QrDecorationBuilder.buildQrImage(qrCode.data, ecHCustomization)` with `hasLogo=true` override to force EC-H, which matches the existing codebase pattern.
- **Files modified:** `customization_snapshot_service.dart`
- **Commit:** `acb0d0b`

**2. [Rule 1 - Bug] const storagePath() call in test**
- **Found during:** Task 1 GREEN phase
- **Issue:** Test used `const path = OrderAssetsStorageDataSource.storagePath(...)` which is invalid — static method calls cannot be `const` expressions.
- **Fix:** Changed to `final path = ...`
- **Files modified:** `customization_snapshot_service_test.dart`
- **Commit:** `acb0d0b`

**3. [Rule 1 - Bug] Uint8List is a final class — cannot be faked with mocktail**
- **Found during:** Task 1 GREEN phase
- **Issue:** `class FakeUint8List extends Fake implements Uint8List {}` fails — `Uint8List` is a Dart SDK final class.
- **Fix:** Registered `registerFallbackValue(Uint8List(0))` instead.
- **Files modified:** `customization_snapshot_service_test.dart`
- **Commit:** `acb0d0b`

**4. [Rule 1 - Bug] Catch variable `_` not accessible inside assert closure**
- **Found during:** Task 2 implementation
- **Issue:** `catch (_) { assert(() { print('... $_') }()); }` — `$_` inside the nested closure triggers `undefined_identifier` (Dart 3 scoping rule for `_`-named catch params).
- **Fix:** Renamed catch variable to `e`.
- **Files modified:** `product_detail_screen.dart`
- **Commit:** `73ad8c0`

## Known Stubs

None — all stubs from Plan 02 replaced by this plan:
- QR thumbnail icon stub in CartItemTile replaced with `_QrThumbnail` (CachedNetworkImage)
- `customizationSnapshot: qrCode.customization.toJson()` stub replaced with `CustomizationSnapshotService.captureSnapshot()` full pipeline

Remaining stubs (out of scope for this plan):
| Stub | File | Line | Reason |
|------|------|------|--------|
| Checkout button = SnackBar | cart_screen.dart | 171 | Phase 9 checkout flow |
| Product name = 'Producto' fallback | cart_item_tile.dart | 95 | variant name lookup deferred |

## Self-Check: PASSED

Files exist:
- FOUND: lib/features/cart/domain/services/customization_snapshot_service.dart
- FOUND: lib/features/cart/data/datasources/order_assets_storage_data_source.dart
- FOUND: test/features/cart/domain/services/customization_snapshot_service_test.dart

Commits:
- FOUND: 8cc89db (RED test commit)
- FOUND: acb0d0b (Task 1 feat commit)
- FOUND: 73ad8c0 (Task 2 feat commit)
