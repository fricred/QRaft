---
phase: 02-qr-generation-core
plan: "03"
subsystem: qr-generator-presentation
tags: [event-qr, ical, vcalendar, flutter_form_builder, filter-chips, i18n]
dependency_graph:
  requires:
    - Phase 2 Plan 01 complete (QRType.event enum value, EventData iCal model)
    - Phase 2 Plan 02 complete (RepaintBoundary + QRPreviewWidget pattern)
  provides:
    - EventQRScreen ConsumerStatefulWidget with Form/Style tabs and edit-mode support
    - EventFormController StateNotifier + EventFormState + eventFormProvider (autoDispose)
    - EventForm widget (flutter_form_builder: 6 fields, title+startDT required)
    - QRType.event wired to EventQRScreen in generator grid (was ComingSoonQRScreen)
    - vevent filter chip in QRLibraryScreen with edit navigation to EventQRScreen
    - filterEvent i18n key in en + es ARBs
  affects:
    - lib/features/qr_generator/qr_generator_screen.dart
    - lib/features/qr_library/qr_library_screen.dart
    - lib/l10n/
tech_stack:
  added: []
  patterns:
    - EventFormController follows WiFiFormController/TextFormController StateNotifier pattern (autoDispose)
    - EventQRScreen mirrors TextQRScreen 2-tab Form/Style layout with RepaintBoundary + GlobalKey
    - description maxLength: 500 enforced in EventForm (T-02-07 DoS mitigation)
    - Edit mode in EventQRScreen: Phase 2 simplification pre-fills name only; full iCal re-parse deferred to Phase 5
key_files:
  created:
    - lib/features/qr_generator/presentation/controllers/event_form_controller.dart
    - lib/features/qr_generator/presentation/widgets/forms/event_form.dart
    - lib/features/qr_generator/presentation/pages/event_qr_screen.dart
  modified:
    - lib/features/qr_generator/qr_generator_screen.dart
    - lib/features/qr_library/qr_library_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_es.arb
    - lib/l10n/app_localizations.dart (regenerated)
    - lib/l10n/app_localizations_en.dart (regenerated)
    - lib/l10n/app_localizations_es.dart (regenerated)
decisions:
  - "Edit mode for EventQRScreen: Phase 2 pre-fills name only (no iCal re-parse) — full round-trip parse deferred to Phase 5 per plan spec"
  - "coming_soon_qr_screen.dart import removed from qr_generator_screen.dart — event type no longer routes to coming soon, making the import unused"
  - "EventForm uses flutter_form_builder (already in pubspec from Phase 9 checkout) rather than raw TextFields to get DateTimePicker support"
requirements-completed:
  - QR-01
metrics:
  duration: "~15 minutes"
  completed: "2026-05-02"
  tasks_completed: 2
  files_modified: 9
---

# Phase 2 Plan 03: Event QR Screen + Generator Wiring + Library Filter Summary

EventQRScreen implemented (6th QR type completing QR-01), wired into the generator type grid replacing the ComingSoonQRScreen stub, with vevent filter chip added to QRLibraryScreen and filterEvent i18n keys in both locales.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Create EventFormController + EventFormState + EventForm widget + EventQRScreen | `9b244f9` |
| 2 | Wire EventQRScreen into generator grid; add vevent filter chip + filterEvent i18n | `51cae1c` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused import in event_qr_screen.dart**
- **Found during:** Task 1 flutter analyze
- **Issue:** `qr_data_models.dart` was imported but `EventData` type not referenced directly in the file (only used through `EventFormState.toEventData()` return value with inferred type)
- **Fix:** Removed the unused import
- **Files modified:** event_qr_screen.dart
- **Commit:** `9b244f9`

**2. [Rule 1 - Bug] Unused import in qr_generator_screen.dart**
- **Found during:** Task 2 flutter analyze
- **Issue:** After replacing `ComingSoonQRScreen(qrType: qrType)` with `EventQRScreen()`, the `coming_soon_qr_screen.dart` import became unused (event was the only place that screen was referenced)
- **Fix:** Removed the unused import
- **Files modified:** qr_generator_screen.dart
- **Commit:** `51cae1c`

**3. [Rule 2 - Missing functionality] Added edit navigation for vevent in _getEditScreenForQRType**
- **Found during:** Task 2 code inspection
- **Issue:** The plan spec said to add the vevent filter chip, but the library screen's `_getEditScreenForQRType` switch also needed a `case 'vevent':` entry otherwise editing an Event QR from the library would fall through to the "coming soon" stub
- **Fix:** Added `case 'vevent': return EventQRScreen(editingQRCode: qrEntity);` to the switch
- **Files modified:** qr_library_screen.dart
- **Commit:** `51cae1c`

## Threat Surface Scan

No new network endpoints or auth paths. T-02-07 (description maxLength: 500) implemented in EventForm via `maxLength: 500` on the description `FormBuilderTextField`. T-02-06 (iCal field injection accepted) — no server-side validation added as per disposition.

## Known Stubs

- `EventQRScreen` edit mode: pre-fills name only from `qrCode.name` — the iCal VCALENDAR string is NOT re-parsed back into individual fields (title, startDateTime, etc.). Full round-trip parse is a Phase 5 concern. This is documented in the plan spec as intentional for Phase 2.

This stub does NOT prevent the plan's goal (Event QR form screen functional for CREATE mode, edit wired at navigation level).

## Verification

```
flutter analyze --no-fatal-warnings          → No issues found (0 errors, 0 warnings)
EventQRScreen file exists                    → FOUND at lib/features/qr_generator/presentation/pages/event_qr_screen.dart
EventQRScreen in generator switch            → FOUND at qr_generator_screen.dart:271
vevent filter chip in library                → FOUND at qr_library_screen.dart:52
filterEvent in _getFilterLabel               → FOUND at qr_library_screen.dart:64
EventQRScreen in _getEditScreenForQRType     → FOUND at qr_library_screen.dart:1648
filterEvent in app_en.arb                    → FOUND ("Event")
filterEvent in app_es.arb                    → FOUND ("Evento")
```

## Self-Check: PASSED

- [x] `lib/features/qr_generator/presentation/controllers/event_form_controller.dart` exists with EventFormState + EventFormController + eventFormProvider
- [x] `lib/features/qr_generator/presentation/widgets/forms/event_form.dart` uses flutter_form_builder with 6 fields (name, title required, startDT required, endDT/location/description optional)
- [x] `lib/features/qr_generator/presentation/pages/event_qr_screen.dart` is ConsumerStatefulWidget with 2-tab Form/Style layout and RepaintBoundary
- [x] `qr_generator_screen.dart` routes `QRType.event` to `EventQRScreen` (not ComingSoonQRScreen)
- [x] `qr_library_screen.dart` has `{'id': 'vevent', ...}` filter chip entry
- [x] `qr_library_screen.dart` has `case 'vevent': return EventQRScreen(editingQRCode: qrEntity)` in edit switch
- [x] `app_en.arb` has `"filterEvent": "Event"` and `app_es.arb` has `"filterEvent": "Evento"`
- [x] Commits `9b244f9` and `51cae1c` exist in git log
- [x] `flutter analyze --no-fatal-warnings` = 0 issues
