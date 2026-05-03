---
phase: 05-qr-customization
plan: "05"
subsystem: qr-generation
tags: [flutter, templates, csv, bulk-import, tdd, gallery]

requires:
  - phase: 05-qr-customization
    plan: "01"
    provides: QRCustomization entity with 9 Phase 5 fields
  - phase: 05-qr-customization
    plan: "04"
    provides: QrDecorationBuilder.buildDecoration (with shape) for mini preview cards

provides:
  - QrBulkImportService.parseCsv(String raw) — CSV parse with Csv(fieldDelimiter:';', autoDetect:false)
  - BulkQrRow(name, type, content) domain value object
  - QrBulkImportException(code) typed exception
  - 8 const QrFullTemplate objects in kQrTemplates list
  - QrFullTemplate class (id, name, customization)
  - QRCustomizationController.applyFullTemplate(QrFullTemplate) method
  - QrTemplateGalleryWidget — 2-column grid with profile badge + neon selected border
  - QrBulkImportSheet — CSV paste, live row-count preview, friendly error cards

affects:
  - QRCustomizationController (applyFullTemplate added; applyTemplate kept for backward compat)
  - Any UI screen composing template gallery or bulk import flow

tech-stack:
  added: []
  patterns:
    - "csv 8.0.0: CsvCodec renamed to Csv — used Csv(fieldDelimiter:';', autoDetect:false) not CsvCodec"
    - "1MB raw.length check before Csv.decoder.convert() — DoS prevention (T-05-05-02)"
    - "500-row cap on valid (non-empty) data rows after header skip (T-05-05-03)"
    - "kQrTemplates const list — templates are compile-time constants, no injection surface (T-05-05-04)"
    - "QrTemplateGalleryWidget reuses _MiniQrView pattern from QrPresetGalleryWidget"
    - "QrBulkImportSheet uses TextFormField CSV paste (file_picker not in pubspec — see TODO)"

key-files:
  created:
    - lib/features/qr_generator/domain/services/qr_bulk_import_service.dart
    - lib/features/qr_generator/presentation/widgets/qr_template_gallery.dart
    - lib/features/qr_generator/presentation/widgets/qr_bulk_import_sheet.dart
    - test/features/qr_generator/domain/qr_bulk_import_test.dart
  modified:
    - lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart

key-decisions:
  - "csv 8.0.0 deprecated CsvCodec → used Csv class; autoDetect:false forces semicolon delimiter"
  - "file_picker not in pubspec — QrBulkImportSheet uses CSV paste TextFormField with TODO for Phase 5 enhancement"
  - "Too-many-rows cap counts only valid (non-empty) rows, not all data rows including empties"
  - "kQrTemplates const list prevents user injection of custom templates via applyFullTemplate UI path"

metrics:
  duration: ~40min
  completed: 2026-05-03T02:05:00Z
  tasks: 2 (Task 1 TDD RED+GREEN, Task 2 standard)
  files-modified: 5 (4 created, 1 modified)
---

# Phase 5 Plan 05: 8 Curated Templates + CSV Bulk Import Summary

**8 curated const QrFullTemplate objects with gallery widget, applyFullTemplate() on controller, and QrBulkImportService using Csv(fieldDelimiter:';') with 1MB/500-row caps — completing Phase 5 QR Customization**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-05-03T01:25:00Z
- **Completed:** 2026-05-03T02:05:00Z
- **Tasks:** 2 (Task 1 TDD RED+GREEN, Task 2 standard)
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments

- `QrBulkImportService.parseCsv(String raw)` uses `Csv(fieldDelimiter:';', autoDetect:false)` (csv 8.0.0 API) to parse semicolon-delimited CSV including quoted fields with inner semicolons; enforces 1MB size cap (T-05-05-02) and 500-row cap on valid rows (T-05-05-03)
- `BulkQrRow(name, type, content)` value object with type normalised to lowercase; rows with empty name or content are silently skipped
- `QrBulkImportException(code)` typed exception with `'file_too_large'` and `'too_many_rows'` codes
- `kQrTemplates` const list of 8 `QrFullTemplate` objects matching research Template Gallery table exactly — Classic, Ocean Blue, Neon Green (digitalOnly, #00FF88/#1A1A1A), Elegant Purple, Charcoal, Sunset Gradient (linear gradient, digitalOnly), Corporate, Tattoo Safe (tattooSafe, logoCoverage=0.0)
- `QRCustomizationController.applyFullTemplate(QrFullTemplate)` replaces all QRCustomization fields atomically; legacy `applyTemplate(QRTemplate)` preserved for backward compat
- `QrTemplateGalleryWidget` 2-column GridView with mini PrettyQrView previews (64×64), template name, colour-coded profile badge (Print/Digital/Tattoo), neon green selected border; `Semantics(identifier:'qr_template_gallery')` for Maestro
- `QrBulkImportSheet` bottom sheet: CSV paste TextFormField (6 lines, monospace), live row-count preview card, inline error card with friendly messages, "Generate N QRs" confirm button; `Semantics(identifier:'qr_bulk_import_sheet')` for Maestro
- 7 bulk import tests: valid parse, quoted inner semicolon, 501-row cap, 1MB cap, empty content skip, empty name skip, type lowercase — all pass
- `flutter analyze lib/features/qr_generator/` = 0 issues

## Task Commits

1. **Task 1 RED: Failing tests for QrBulkImportService** - `64f2deb` (test)
2. **Task 1 GREEN: QrBulkImportService implementation** - `9575e8e` (feat)
3. **Task 2: Templates + gallery + bulk import sheet** - `2a41954` (feat)

## Files Created/Modified

- `lib/features/qr_generator/domain/services/qr_bulk_import_service.dart` — `QrBulkImportService`, `BulkQrRow`, `QrBulkImportException`
- `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` — `QrFullTemplate` class, `kQrTemplates` const list (8 entries), `applyFullTemplate()` method added
- `lib/features/qr_generator/presentation/widgets/qr_template_gallery.dart` — `QrTemplateGalleryWidget`, `_TemplateCard`, `_ProfileBadge`, `_MiniQrView`
- `lib/features/qr_generator/presentation/widgets/qr_bulk_import_sheet.dart` — `QrBulkImportSheet`, `_RowCountPreview`, `_ErrorCard`
- `test/features/qr_generator/domain/qr_bulk_import_test.dart` — 7 unit tests

## Decisions Made

- `CsvCodec` is deprecated in csv 8.0.0 and renamed to `Csv` — updated to `Csv(fieldDelimiter:';', autoDetect:false)`. The `autoDetect:true` default would ignore the configured delimiter.
- `file_picker` is not in the project's pubspec. Per plan instructions, implemented `QrBulkImportSheet` with a CSV paste `TextFormField` as fallback with a TODO comment pointing to Phase 5 enhancement path.
- Row count cap counts only valid non-empty rows (rows where both name and content are non-empty) — ensures the 500 cap is meaningful and not triggered by blank lines.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `CsvCodec` deprecated — must use `Csv` class from csv 8.0.0**
- **Found during:** Task 1 GREEN (flutter analyze warning after initial implementation)
- **Issue:** Plan specified `CsvCodec(fieldDelimiter: ';')` but csv 8.0.0 renamed the class to `Csv`; using `CsvCodec` emitted a deprecation warning breaking the 0-issues requirement
- **Fix:** Changed to `Csv(fieldDelimiter: ';', autoDetect: false)` using the new API
- **Files modified:** `lib/features/qr_generator/domain/services/qr_bulk_import_service.dart`
- **Commit:** `9575e8e`

**2. [Rule 1 - Bug] `static const CsvCodec _codec` not const-constructible**
- **Found during:** Task 1 GREEN (compile error)
- **Issue:** `const` field declaration failed because `Csv` constructor is not `const`
- **Fix:** Changed to `static final Csv _codec = Csv(...)` — the instance is still effectively immutable
- **Files modified:** `lib/features/qr_generator/domain/services/qr_bulk_import_service.dart`
- **Commit:** `9575e8e`

## Known Stubs

**1. File picker in QrBulkImportSheet**
- **File:** `lib/features/qr_generator/presentation/widgets/qr_bulk_import_sheet.dart`
- **Reason:** `file_picker` package not in pubspec.yaml; implemented with CSV paste TextFormField as documented fallback
- **TODO:** Add `file_picker: ^8.0.0` to pubspec and replace TextFormField with `FilePicker.platform.pickFiles()` — see TODO comment in file
- **Impact:** Users must paste CSV text manually rather than picking a file from device storage; full import functionality works correctly with paste input

## Threat Flags

No new threat surface beyond what was documented in the plan's threat model.

- T-05-05-02 mitigated: `raw.length > 1024*1024` check before `Csv.decoder.convert()` runs
- T-05-05-03 mitigated: 500-row hard cap on valid non-empty rows before building `BulkQrRow` list
- T-05-05-01 accepted: CSV content populates QR data only — not executed in spreadsheet context
- T-05-05-04 accepted: `kQrTemplates` is const; `applyFullTemplate` accepts only `QrFullTemplate` objects defined at compile time

## TDD Gate Compliance

Task 1 followed RED/GREEN cycle:
- RED: `64f2deb` (test) — 7 tests fail with "Undefined name 'QrBulkImportService'" (compilation error)
- GREEN: `9575e8e` (feat) — all 7 tests pass

## Self-Check: PASSED

- FOUND: `lib/features/qr_generator/domain/services/qr_bulk_import_service.dart`
- FOUND: `lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart` (contains applyFullTemplate + kQrTemplates)
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_template_gallery.dart`
- FOUND: `lib/features/qr_generator/presentation/widgets/qr_bulk_import_sheet.dart`
- FOUND: `test/features/qr_generator/domain/qr_bulk_import_test.dart`
- FOUND commit: `64f2deb` (RED gate)
- FOUND commit: `9575e8e` (GREEN gate)
- FOUND commit: `2a41954` (Task 2)
- No unexpected file deletions in any commit

---
*Phase: 05-qr-customization*
*Completed: 2026-05-03*
