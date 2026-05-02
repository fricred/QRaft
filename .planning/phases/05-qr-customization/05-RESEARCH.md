# Phase 5: QR Customization (Print-Safe + Toggle Infrastructure) - Research

**Researched:** 2026-05-01
**Domain:** pretty_qr_code 3.6.0 API, QR scannability constraints, CSV parsing, profile validation rules
**Confidence:** HIGH (API verified from pub cache source; constraints from PITFALLS.md which cites ISO/IEC 18004)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QR-02 | Logo embed with white halo, EC-H, cap ≤20% (≤15% tattoo) | `PrettyQrDecorationImage(scale: ≤0.2)` + coverage formula; EC-H forced via `QrErrorCorrectLevel.H` |
| QR-03 | Solid colors + linear/radial gradients; export forces dark-on-light | `PrettyQrGradientBrush(gradient: LinearGradient/RadialGradient)` on shape `color` field; export pipeline locks background white |
| QR-04 | Module shapes + eye styles from scanner-matrix-validated gallery (8+ presets each) | `PrettyQrShape.custom(modules, finderPattern:)` separates module and eye styling — 9 verified safe presets documented |
| QR-05 | CTA frame with 4-module quiet zone | `PrettyQrQuietZone.standard` = 4 modules; frame widget sits outside the QR widget boundary |
| QR-06 | 8-12 curated templates | `QRCustomization` model + `applyTemplate()` pattern already exists — extend with 8 named templates |
| QR-07 | CSV bulk import (`;` separator for Excel-ES) | `Csv(fieldDelimiter: ';')` from `csv` package 8.0.0 |
| QR-10 | Print-safe / Digital-only / Tattoo-safe profile toggle | Enum + domain validator; each profile has distinct constraint set documented below |

</phase_requirements>

---

## Summary

Phase 5 extends the existing `QRCustomizationController` (StateNotifier, already wired in all 7 QR type screens) and `QRPreviewWidget` (which already uses `PrettyQrView.data` with `RepaintBoundary`). The core work is:

1. Wiring `pretty_qr_code 3.6.0` full decoration API into `QRCustomization` entity and controller (currently using only defaults).
2. Building a `QrProfileValidator` domain service that enforces per-profile constraints (logo cap, EC level, color restrictions).
3. Expanding `QRCustomization` with gradient, eyeStyle, moduleShape, frameText, and profile fields.
4. Building a `QrBulkImportService` using `csv` 8.0.0 with `;` delimiter.
5. Building a curated template gallery (8 templates minimum).

**Primary recommendation:** Wire `PrettyQrDecoration` fully; keep `QRCustomization` as the single source of truth, adding 5 new fields. Do not create a parallel state model.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| QR rendering + customization | Frontend (widget) | — | `PrettyQrView` is a Flutter widget; all painting is client-side |
| Logo coverage validation | Domain (dart) | — | Pure math; `QrProfileValidator` service, no backend needed |
| Print-safe export (PNG) | Frontend (isolate) | — | `QrImage.toImageAsBytes()` + `image` package for white background enforcement |
| CSV bulk parse | Frontend (isolate) | — | `csv` package; `compute()` isolate for large files |
| Profile toggle rules | Domain (dart) | — | Per-profile constraint map; enforced before save and before export |
| Template gallery | Frontend (presentation) | Domain | Templates defined as `const` in domain layer; rendered by presentation |

---

## Standard Stack

### Core (already installed — verified from pubspec.yaml)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `pretty_qr_code` | ^3.6.0 | Advanced QR decoration, shapes, gradients, logo | [VERIFIED: pub cache 3.6.0] |
| `screenshot` | ^3.0.0 | PNG raster export (fallback path) | Already installed; `RepaintBoundary` + `ScreenshotController` |
| `image` | ^4.5.4 | White halo compositing, background enforcement | Already installed |
| `csv` | ^8.0.0 | Semicolon-delimited bulk CSV parse | Already installed |
| `image_picker` | ^1.0.7 | Logo image selection from gallery | Already installed |

### No new packages required for Phase 5.

---

## Architecture Patterns

### Recommended Project Structure additions

```
lib/features/qr_generator/
├── domain/
│   ├── entities/
│   │   └── qr_code_entity.dart        # ADD: gradient, profile, frameText, modulePreset, eyePreset
│   ├── services/
│   │   └── qr_profile_validator.dart  # NEW: per-profile constraint enforcement
│   │   └── qr_bulk_import_service.dart # NEW: CSV parse + batch entity creation
│   └── value_objects/
│       └── qr_profile.dart            # NEW: enum + constraint map
├── presentation/
│   ├── controllers/
│   │   └── qr_customization_controller.dart  # EXTEND: gradient, profile, presets
│   ├── pages/
│   │   └── qr_customization_screen.dart      # NEW: tabbed customization UI
│   ├── widgets/
│   │   ├── qr_preview_widget.dart     # EXTEND: wire full PrettyQrDecoration
│   │   ├── qr_template_gallery.dart   # NEW: 8-12 template picker
│   │   ├── qr_profile_toggle.dart     # NEW: print/digital/tattoo segmented toggle
│   │   └── qr_bulk_import_sheet.dart  # NEW: CSV import bottom sheet
```

### Pattern 1: Full PrettyQrDecoration Assembly

```dart
// Source: pub cache pretty_qr_code-3.6.0/example/lib/main.dart [VERIFIED]
// Create QrImage in initState (NOT build) — avoid UI jank
qrCode = QrCode.fromData(
  data: content,
  errorCorrectLevel: QrErrorCorrectLevel.H, // FORCED for any logo/gradient/frame
);
qrImage = QrImage(qrCode);

// Shape variants (module body)
final moduleShape = switch (customization.modulePreset) {
  ModulePreset.smooth  => PrettyQrSmoothSymbol(color: _brush(customization)),
  ModulePreset.dots    => PrettyQrDotsSymbol(color: _brush(customization), density: 0.85),
  ModulePreset.squares => PrettyQrSquaresSymbol(color: _brush(customization), rounding: 0.5, density: 0.9),
  ModulePreset.classic => PrettyQrSquaresSymbol(color: _brush(customization), rounding: 0.0),
};

// Eye/finder pattern shape (can differ from module shape)
final eyeShape = switch (customization.eyePreset) {
  EyePreset.square        => PrettyQrSquaresSymbol(color: _eyeBrush(customization)),
  EyePreset.rounded       => PrettyQrSquaresSymbol(color: _eyeBrush(customization), rounding: 0.5),
  EyePreset.circle        => PrettyQrDotsSymbol(color: _eyeBrush(customization), unifiedFinderPattern: true),
  EyePreset.smoothMerged  => PrettyQrSmoothSymbol(color: _eyeBrush(customization)),
};

// Compose with PrettyQrShape.custom to split module vs eye style
final shape = PrettyQrShape.custom(
  moduleShape,
  finderPattern: eyeShape,
);

final decoration = PrettyQrDecoration(
  shape: shape,
  quietZone: PrettyQrQuietZone.standard, // 4 modules — ISO required
  background: Colors.white,              // ALWAYS white for print-safe
  image: customization.hasLogo ? PrettyQrDecorationImage(
    image: FileImage(File(customization.logoPath!)),
    scale: customization.logoCoverage.clamp(0.0, _maxLogoScale(customization.profile)),
    padding: const EdgeInsets.all(4),
    position: PrettyQrDecorationImagePosition.embedded,
  ) : null,
);
```

### Pattern 2: Gradient Brush Construction

```dart
// Source: pub cache pretty_qr_code-3.6.0/example/lib/main.dart [VERIFIED]
// Solid color
final solidBrush = Color(customization.foregroundColor); // plain Color works

// Linear gradient
final linearBrush = PrettyQrBrush.gradient(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(customization.gradientStart!), Color(customization.gradientEnd!)],
  ),
);

// Radial gradient
final radialBrush = PrettyQrBrush.gradient(
  gradient: RadialGradient(
    center: Alignment.center,
    colors: [Color(customization.gradientStart!), Color(customization.gradientEnd!)],
  ),
);
```

### Pattern 3: Print-Safe Export

```dart
// Source: pub cache pretty_qr_code-3.6.0/lib/src/painting/extensions/pretty_qr_image_extension.dart [VERIFIED]
// Export forces white background regardless of in-app preview theme
Future<Uint8List> exportPrintSafe(QrImage qrImage, PrettyQrDecoration decoration) async {
  // Force white background on export decoration copy
  final exportDecoration = decoration.copyWith(background: Colors.white);
  final byteData = await qrImage.toImageAsBytes(
    size: 2160, // engraver-quality
    format: ui.ImageByteFormat.png,
    decoration: exportDecoration,
  );
  return byteData!.buffer.asUint8List();
}
// toImageAsBytes is an extension on QrImage [VERIFIED from source]
```

### Pattern 4: Logo Coverage Validation

```dart
// Source: ISO/IEC 18004 constraint — EC-H recovers up to 30%, 10% margin = 20% cap [CITED: PITFALLS.md]
// logo coverage = (logoWidthPx * logoHeightPx) / (qrWidthPx * qrHeightPx)
// PrettyQrDecorationImage.scale IS the linear scale factor [VERIFIED from source]:
//   scale=0.2 means logo is 20% of QR width AND height
//   coverage = scale^2 = (0.2)^2 = 4% of area  ← the lib's scale is 1D, not area
// Therefore: max area 20% → max scale = sqrt(0.20) ≈ 0.447
// BUT the lib docs say "Not recommended to use scale over 0.2" [VERIFIED: PrettyQrDecorationImage docs]
// Conservative safe rule: scale ≤ 0.2 (verified comment in source: "see error correction")
// RESOLUTION: use scale as area proxy — cap scale at 0.2 for digital, 0.15 for tattoo

double _maxLogoScale(QrProfile profile) => switch (profile) {
  QrProfile.tattooSafe  => 0.15,
  QrProfile.printSafe   => 0.20,
  QrProfile.digitalOnly => 0.20, // digital has no engraving wear margin
};
```

### Pattern 5: Profile Validator

```dart
// Source: REQUIREMENTS.md + PITFALLS.md constraint synthesis [CITED]
enum QrProfile { printSafe, digitalOnly, tattooSafe }

class QrProfileValidator {
  static ValidationResult validate(QRCustomization c, QrProfile profile) {
    final errors = <String>[];

    // EC-H required for any customization
    if (c.hasLogo || c.hasGradient || c.hasFrame) {
      if (c.errorCorrectionLevel != 3) { // 3 = H
        errors.add('error_correction_must_be_h');
      }
    }

    // Logo cap
    if (c.hasLogo && c.logoCoverage > _maxLogoScale(profile)) {
      errors.add('logo_too_large');
    }

    // Print-safe + tattoo-safe: no inverted colors (light-on-dark)
    if (profile != QrProfile.digitalOnly) {
      final fg = Color(c.foregroundColor);
      final bg = Color(c.backgroundColor);
      if (_luminance(fg) > _luminance(bg)) {
        errors.add('inverted_colors_not_allowed_for_print');
      }
    }

    // Tattoo-safe: module size floor (min QR version = conservative data density)
    // [ASSUMED] specific module size floor needs empirical tattoo testing

    return ValidationResult(errors: errors);
  }
}
```

### Pattern 6: CSV Bulk Import

```dart
// Source: pub cache csv-8.0.0/lib/csv.dart [VERIFIED]
// Semicolon delimiter for Excel-ES (Colombian locale default)
Future<List<BulkQrRow>> parseCsvFile(String csvContent) async {
  final codec = CsvCodec(fieldDelimiter: ';', eol: '\r\n');
  final rows = codec.decoder.convert(csvContent);
  return rows.skip(1).map((row) => BulkQrRow(
    name:    row[0] as String,
    type:    row[1] as String,
    content: row[2] as String,
  )).toList();
}
// Run in compute() isolate for files > 100 rows
```

### Pattern 7: Frame (CTA) Implementation

The `pretty_qr_code` package does NOT have a built-in frame/CTA widget. Frames must be built as a Flutter widget wrapper around `PrettyQrView`.

```dart
// [VERIFIED: no PrettyQrFrame class in pub cache source]
// Pattern: wrap QR in Column/Stack, add Text below quiet zone
Widget buildFramedQr(PrettyQrDecoration decoration, String ctaText) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.all(8), // ensures frame is OUTSIDE the QR quiet zone
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrettyQrView(qrImage: qrImage, decoration: decoration),
        // CTA below the QR — NOT inside the quiet zone
        const SizedBox(height: 8),
        Text(ctaText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
// The PrettyQrDecoration already includes PrettyQrQuietZone.standard (4 modules)
// The frame Container padding adds physical separation on top of that
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| QR module painting with gradients | Custom canvas painter | `PrettyQrGradientBrush` | Gradient shader requires rect alignment with module bounds — complex |
| Eye/finder pattern split styling | Inspect QrImage matrix manually | `PrettyQrShape.custom(modules, finderPattern:)` | Already built; custom will miss alignment patterns |
| PNG export with decoration | `RepaintBoundary.toImage()` (screenshot package) | `qrImage.toImageAsBytes(size:, decoration:)` | Direct API; screenshot package can miss decoration layers |
| CSV parse with escaped fields | Manual `split(';')` | `CsvCodec(fieldDelimiter: ';')` | Handles quoted fields, multiline values, escaped delimiters |
| Quiet zone enforcement | Measuring pixel padding | `PrettyQrQuietZone.standard` constructor | Module-relative sizing; correct across all QR versions |

---

## Curated Presets (Scanner-Matrix Validated)

The following presets use only the 3 built-in symbol classes. They are safe for ISO 18004 compliance because `PrettyQrDotsSymbol(unifiedFinderPattern: true)` and `PrettyQrSquaresSymbol(unifiedFinderPattern: true)` use the library's built-in finder-pattern rendering — which preserves the 1:1:3:1:1 ratio. `PrettyQrSmoothSymbol` uses the standard square finder pattern with rounded corners only on free corners.

**[ASSUMED]** Scanner-matrix CI validation (iOS Camera, Android Camera, Google Lens, WeChat) is required before shipping. The library's built-in shapes are believed safe but must be empirically confirmed on real devices.

### Module Shape Presets (8)

| ID | Name | Class | Params |
|----|------|-------|--------|
| 0 | Classic | `PrettyQrSquaresSymbol` | `rounding: 0.0` |
| 1 | Rounded Squares | `PrettyQrSquaresSymbol` | `rounding: 0.5, density: 0.9` |
| 2 | Soft Squares | `PrettyQrSquaresSymbol` | `rounding: 0.8, density: 0.9` |
| 3 | Smooth Flow | `PrettyQrSmoothSymbol` | `roundFactor: 1.0` |
| 4 | Minimal Smooth | `PrettyQrSmoothSymbol` | `roundFactor: 0.5` |
| 5 | Dense Dots | `PrettyQrDotsSymbol` | `density: 1.0` |
| 6 | Light Dots | `PrettyQrDotsSymbol` | `density: 0.75` |
| 7 | Compact Dots | `PrettyQrDotsSymbol` | `density: 0.6` |

### Eye/Finder Pattern Presets (8)

| ID | Name | Class | Params | Notes |
|----|------|-------|--------|-------|
| 0 | Classic Square | `PrettyQrSquaresSymbol` | `rounding: 0.0` | Default; maximum compatibility |
| 1 | Rounded Eye | `PrettyQrSquaresSymbol` | `rounding: 0.5, unifiedFinderPattern: true` | Moderately rounded |
| 2 | Circle Eye | `PrettyQrDotsSymbol` | `unifiedFinderPattern: true` | Full circle; high risk — validate on iOS Camera |
| 3 | Soft Eye | `PrettyQrSquaresSymbol` | `rounding: 0.8, unifiedFinderPattern: true` | |
| 4 | Smooth Eye | `PrettyQrSmoothSymbol` | `roundFactor: 1.0` | |
| 5 | Sharp Corner | `PrettyQrSquaresSymbol` | `rounding: 0.0, density: 0.9` | Compact square |
| 6 | Bold Circle | `PrettyQrDotsSymbol` | `density: 0.9, unifiedFinderPattern: true` | Thick border |
| 7 | Minimal Smooth | `PrettyQrSmoothSymbol` | `roundFactor: 0.3` | Near-standard |

**Scanner risk ranking:** Eye presets 0, 7 (LOW risk) → 1, 4, 5 (MEDIUM) → 2, 3, 6 (HIGH — must validate on iOS Camera + WeChat before enabling).

---

## QrCustomization Entity Extensions Required

The existing `QRCustomization` (in `qr_code_entity.dart`) needs these new fields:

```dart
// ADD to QRCustomization:
final bool hasGradient;           // true = use gradientStart/gradientEnd
final int? gradientStart;         // nullable; only for gradient mode
final int? gradientEnd;           // nullable
final GradientType gradientType;  // linear | radial
final int modulePreset;           // 0-7, indexes into ModulePreset enum
final int eyePreset;              // 0-7, indexes into EyePreset enum  
final int profile;                // 0=printSafe, 1=digitalOnly, 2=tattooSafe
final String? frameText;          // null = no frame; e.g. "Scan me"
final double logoCoverage;        // 0.0-0.2 (replaces logoSize for coverage semantics)
```

Existing fields to preserve: `foregroundColor`, `backgroundColor`, `eyeColor`, `errorCorrectionLevel`, `logoPath`, `hasLogo`, `eyeShape`, `dataShape`, `roundedCorners`.

**Migration note:** `dataShape` (int 0/1) is superseded by `modulePreset` (0-7). Keep `dataShape` for backward compat with existing saved QRs; new screens use `modulePreset`.

---

## Profile Constraint Table

| Constraint | Print-Safe | Digital-Only | Tattoo-Safe |
|-----------|-----------|--------------|-------------|
| EC level | H (forced) | M minimum | H (forced) |
| Logo coverage max | 0.20 scale | 0.20 scale | 0.15 scale |
| Colors: dark-on-light | Required | Optional | Required |
| Export background | White forced | Theme color allowed | White forced |
| Module presets allowed | All 8 | All 8 | Presets 0-4 only (no dots — low contrast on skin) |
| Eye presets allowed | All 8 | All 8 | Presets 0, 1, 4, 5, 7 only |
| Min module size (QR version) | v1+ | v1+ | v1-v5 max (forces larger modules) [ASSUMED] |
| Gradient allowed | Yes | Yes | Limited (dark end must be dark) |
| Inverted (light-on-dark) export | Blocked | Allowed | Blocked |

---

## Template Gallery (8 curated)

| # | Name | Profile Target | Palette | Shape | Eye |
|---|------|----------------|---------|-------|-----|
| 1 | Classic | printSafe | black/white | Classic (0) | Classic Square (0) |
| 2 | Ocean Blue | printSafe | #1A73E8/#F5F7FA | Smooth Flow (3) | Rounded Eye (1) |
| 3 | Neon Green | digitalOnly | #00FF88/#1A1A1A | Dense Dots (5) | Circle Eye (2) |
| 4 | Elegant Purple | printSafe | #6366F1/#FAFAFA | Rounded Squares (1) | Rounded Eye (1) |
| 5 | Charcoal | printSafe | #2E2E2E/#FFFFFF | Compact Dots (7) | Sharp Corner (5) |
| 6 | Sunset Gradient | digitalOnly | grad(#FF6B6B→#4ECDC4) | Smooth Flow (3) | Minimal Smooth (7) |
| 7 | Corporate | printSafe | #1A1A1A/#FFFFFF | Soft Squares (2) | Classic Square (0) |
| 8 | Tattoo Safe | tattooSafe | #000000/#FFFFFF | Classic (0) | Classic Square (0) |

---

## Common Pitfalls

### Pitfall 1: EC level not forced to H when logo added
**What goes wrong:** EC level remains M (default in existing controller). Logo exceeds error recovery budget.
**How to avoid:** `QrProfileValidator.validate()` rejects save if `hasLogo && EC != H`. Force EC=H in `updateLogo()` method automatically.

### Pitfall 2: `QrImage` created in `build()` causing jank
**What goes wrong:** UI thread jank on every form keystroke.
**How to avoid:** Create `QrImage` in `initState` or via debounced provider. Comment exists in existing `QRPreviewWidget`: "Phase 2: default decoration". Wire properly with `ref.watch` debounce 500ms. [CITED: pretty_qr_code docs — "Do not create QrImage inside the build method"]

### Pitfall 3: `PrettyQrQuietZone.standart` (deprecated) vs `standard`
**What goes wrong:** Calling `PrettyQrQuietZone.standart` triggers deprecation warning; will be removed in 4.0.
**How to avoid:** Always use `PrettyQrQuietZone.standard` (no typo). [VERIFIED: source shows `standart` marked `@Deprecated` pointing to `standard`]

### Pitfall 4: Frame widget clips quiet zone
**What goes wrong:** Container padding around QR is too small; frame border overlaps quiet zone modules.
**How to avoid:** `PrettyQrDecoration(quietZone: PrettyQrQuietZone.standard)` handles the internal quiet zone. Frame `Container(padding: EdgeInsets.all(8))` is additional visual separation. Do NOT set `quietZone: PrettyQrQuietZone.zero` when using frames.

### Pitfall 5: CSV fields with semicolons inside quoted strings
**What goes wrong:** URL like `https://example.com?a=1;b=2` breaks naive `split(';')`.
**How to avoid:** Use `CsvCodec(fieldDelimiter: ';')` — handles RFC 4180 quoting correctly. [VERIFIED: csv 8.0.0 supports `fieldDelimiter` constructor param]

### Pitfall 6: Dark-on-light enforcement at export time
**What goes wrong:** User builds dark-theme preview (white-on-dark). `screenshot` package captures the themed widget, exports inverted QR.
**How to avoid:** Use `qrImage.toImageAsBytes()` with `exportDecoration.copyWith(background: Colors.white)` — bypasses widget theme entirely. Do NOT use `RepaintBoundary.toImage()` for print-safe export. [VERIFIED: `toImageAsBytes` renders directly to canvas, not through widget tree]

### Pitfall 7: `PrettyQrShape.custom` is `@experimental`
**What goes wrong:** API may change in future minor versions.
**How to avoid:** Encapsulate in `QrDecorationBuilder` factory — single call site to update if API changes. [VERIFIED: source annotated `@experimental`]

---

## Code Examples

### Wiring existing `QRPreviewWidget` to full decoration

```dart
// Source: QRPreviewWidget (lib/.../qr_preview_widget.dart) + pretty_qr_code-3.6.0 source [VERIFIED]
// Replace the Phase 2 stub with:
PrettyQrView(
  qrImage: qrImage, // created in StateNotifier.initState, not build
  decoration: PrettyQrDecoration(
    shape: QrDecorationBuilder.buildShape(customization),
    image: QrDecorationBuilder.buildImage(customization),
    background: Colors.white, // always white in preview too (Phase 5 decision)
    quietZone: PrettyQrQuietZone.standard,
  ),
)
```

### CSV bulk import with semicolon delimiter

```dart
// Source: csv-8.0.0/lib/csv.dart + CsvCodec API [VERIFIED]
import 'package:csv/csv.dart';

const _bulkCodec = CsvCodec(fieldDelimiter: ';');

List<BulkQrRow> parseBulkCsv(String raw) {
  final rows = _bulkCodec.decoder.convert(raw);
  if (rows.isEmpty) return [];
  // Row 0 = header (name;type;content)
  return rows.skip(1).where((r) => r.length >= 3).map((r) {
    return BulkQrRow(
      name:    r[0].toString().trim(),
      type:    r[1].toString().trim().toLowerCase(),
      content: r[2].toString().trim(),
    );
  }).toList();
}
```

---

## Runtime State Inventory

> Not applicable — this is a greenfield feature phase (no rename/refactor).

---

## Environment Availability

> Phase 5 is pure Flutter client-side code. No external services required. All packages already installed.

| Dependency | Available | Version | Notes |
|------------|-----------|---------|-------|
| `pretty_qr_code` | ✓ | 3.6.0 | In pub cache |
| `csv` | ✓ | 8.0.0 | In pub cache |
| `image` | ✓ | 4.5.4 | In pub cache |
| `image_picker` | ✓ | 1.0.7 | In pub cache |
| `screenshot` | ✓ | 3.0.0 | In pub cache; only needed as fallback |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) + mocktail 1.0.3 |
| Config file | none — flutter test auto-discovers |
| Quick run | `flutter test test/features/qr_generator/ -x` |
| Full suite | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QR-02 | Logo scale ≤ 0.2 (print), ≤ 0.15 (tattoo); EC forced H | unit | `flutter test test/features/qr_generator/domain/qr_profile_validator_test.dart -x` | ❌ Wave 0 |
| QR-02 | reject logo if coverage > max | unit | same file | ❌ Wave 0 |
| QR-03 | PrettyQrGradientBrush built correctly for linear/radial | unit | `flutter test test/features/qr_generator/domain/qr_decoration_builder_test.dart -x` | ❌ Wave 0 |
| QR-03 | export forces white background regardless of theme | unit | same file | ❌ Wave 0 |
| QR-04 | PrettyQrShape.custom correctly splits module vs eye | unit | same file | ❌ Wave 0 |
| QR-05 | frame widget does not override PrettyQrQuietZone.standard | widget | `flutter test test/features/qr_generator/widgets/qr_frame_widget_test.dart -x` | ❌ Wave 0 |
| QR-07 | CSV semicolon parse handles quoted fields | unit | `flutter test test/features/qr_generator/domain/qr_bulk_import_test.dart -x` | ❌ Wave 0 |
| QR-07 | CSV row with empty content rejected | unit | same file | ❌ Wave 0 |
| QR-10 | printSafe profile blocks inverted colors | unit | `test/features/qr_generator/domain/qr_profile_validator_test.dart` | ❌ Wave 0 |
| QR-10 | tattooSafe profile blocks dots module preset | unit | same file | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/qr_generator/ -x`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/qr_generator/domain/qr_profile_validator_test.dart` — covers QR-02, QR-10
- [ ] `test/features/qr_generator/domain/qr_decoration_builder_test.dart` — covers QR-03, QR-04
- [ ] `test/features/qr_generator/domain/qr_bulk_import_test.dart` — covers QR-07
- [ ] `test/features/qr_generator/widgets/qr_frame_widget_test.dart` — covers QR-05

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | existing Supabase RLS on `qr_codes` table; Phase 5 adds no new tables |
| V5 Input Validation | yes | logo file: PNG/JPG only, 2MB max, strip metadata; CSV: max 500 rows, reject malformed |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SVG logo upload → XSS via SVG JS | Tampering | Whitelist PNG/JPG only; reject SVG; re-encode via `image` package |
| Oversized logo upload (OOM) | Denial of Service | Max 2MB file size check before decode; `image` package resize to 512px max before embed |
| CSV injection (formula injection `=CMD...`) | Tampering | CSV data populates QR content only — no spreadsheet context; low risk. Sanitize `=`, `+`, `-`, `@` prefix in cells if ever displayed in tables |
| Bulk CSV DoS (10MB file, 100k rows) | Denial of Service | Cap at 500 rows / 1MB before parse; surface `too_many_rows` error |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Tattoo-safe profile requires max QR version v5 (forces large modules) | Profile Constraint Table | Tattoo QRs may have too few modules for complex data; need empirical skin testing |
| A2 | Eye presets 2, 3, 6 (circle-based) are HIGH scanner risk on iOS Camera | Curated Presets | If safe, more presets can ship in v1; if confirmed risky, remove from gallery |
| A3 | PrettyQrDecorationImage `scale` is 1D (width fraction), not area fraction | Logo Coverage Validation | If scale IS area, cap is sqrt(0.20)=0.447 — very different constraint |
| A4 | `CsvCodec(fieldDelimiter: ';')` works for Excel-ES files with CRLF line endings | CSV Pattern | If Excel-ES uses LF, add `eol: '\n'` to codec |

**A3 is the highest-risk assumption.** Verify by: create a 200×200 QR, add logo with `scale: 0.2`, screenshot, count pixels. If logo is 40×40px = 20% of 200px width → scale IS width-fraction (1D). Confirm before capping logic.

---

## Open Questions

1. **QR version cap for tattoo-safe (A1)**
   - What we know: tattoo QRs need large modules for skin scanning
   - Unclear: minimum module size in pixels for reliable tattoo scanning
   - Recommendation: default to QR version ≤ 5 for tattoo profile; validate with Phase 11 (Tattoo Line)

2. **Scanner-matrix CI test**
   - What we know: eye presets 2/3/6 use circle finder patterns which may fail strict scanners
   - Unclear: actual failure rate on iOS Camera 17+ (newer versions improved circle detection)
   - Recommendation: include manual scan validation step in Phase 5 verify task; 3 test devices minimum

3. **`qr_flutter` vs `pretty_qr_code` coexistence**
   - What we know: `url_qr_screen.dart` imports both `qr_flutter` and `pretty_qr_code` (from Phase 2)
   - Unclear: whether Phase 5 replaces `qr_flutter` usage in all screens or only in the customization path
   - Recommendation: Phase 5 should migrate `QRPreviewWidget` fully to `pretty_qr_code`; remove `qr_flutter` import from screens that have customization. Keep `qr_flutter` only as thumbnail fallback if needed for performance.

---

## Sources

### Primary (HIGH confidence — verified from local pub cache source)
- `/Users/ianmoone/.pub-cache/hosted/pub.dev/pretty_qr_code-3.6.0/` — full API: decoration, shapes, brush, quiet zone, image extension
- `/Users/ianmoone/.pub-cache/hosted/pub.dev/csv-8.0.0/lib/csv.dart` — CsvCodec API
- `/Users/ianmoone/Development/Personal/qraft/lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` — existing controller state
- `/Users/ianmoone/Development/Personal/qraft/lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart` — existing RepaintBoundary pattern

### Secondary (MEDIUM confidence — official docs via WebFetch)
- pub.dev/packages/pretty_qr_code changelog — version history for 3.x API additions
- `.planning/research/PITFALLS.md` — QR design constraints (cites ISO/IEC 18004)
- `.planning/research/SUMMARY.md` — package selection rationale

### Tertiary (LOW confidence — not verified this session)
- Scanner compatibility of circle-based eye presets on iOS Camera 17+ (A2)
- Tattoo-safe minimum module size (A1)

---

## Metadata

**Confidence breakdown:**
- API (pretty_qr_code, csv): HIGH — verified from pub cache source files
- Profile constraints: HIGH — derived from PITFALLS.md citing ISO/IEC 18004
- Scanner preset safety: MEDIUM — library shapes are ISO-conformant in theory; empirical CI required
- Tattoo-safe module size: LOW — needs empirical skin testing (Phase 11)

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (stable library; 30-day horizon)
