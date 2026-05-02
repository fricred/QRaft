---
phase: 02-qr-generation-core
plan: "01"
subsystem: qr-generator-domain
tags: [domain, qr-types, repository, pagination, i18n, ical]
dependency_graph:
  requires:
    - Phase 1 complete (Supabase wired, analyzer baseline 0 issues)
  provides:
    - QRType.event with VEVENT iCal serialization
    - getUserQRCodesPaginated(userId, page, pageSize) on repository stack
  affects:
    - lib/features/qr_generator/domain/
    - lib/features/qr_generator/data/
    - lib/features/subscription/domain/entities/feature_access.dart
    - lib/l10n/
tech_stack:
  added: []
  patterns:
    - EventData extends QRDataModel with VCALENDAR/VEVENT iCal format (YYYYMMDDTHHMMSS, no Z)
    - Supabase .range(from, to) for server-side pagination; local cache sublist fallback
    - FeatureType.qrTypeEvent added alongside existing qrType* values
key_files:
  created:
    - supabase/migrations/20260501100000_add_event_qr_type.sql
  modified:
    - lib/features/qr_generator/domain/entities/qr_type.dart
    - lib/features/qr_generator/domain/entities/qr_data_models.dart
    - lib/features/qr_generator/domain/repositories/qr_repository.dart
    - lib/features/qr_generator/data/datasources/qr_remote_data_source.dart
    - lib/features/qr_generator/data/datasources/qr_supabase_data_source.dart
    - lib/features/qr_generator/data/repositories/qr_repository_impl.dart
    - lib/features/subscription/domain/entities/feature_access.dart
    - lib/features/subscription/presentation/providers/feature_gate_providers.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_es.arb
    - lib/l10n/app_localizations.dart (generated)
    - lib/l10n/app_localizations_en.dart (generated)
    - lib/l10n/app_localizations_es.dart (generated)
    - lib/features/qr_generator/presentation/pages/qr_form_screen.dart
    - lib/features/qr_generator/presentation/widgets/qr_preview_widget.dart
    - lib/features/qr_generator/qr_generator_screen.dart
decisions:
  - "EventData iCal uses local time (no Z suffix) for v1 simplicity — avoids timezone complexity for first-party-generated events"
  - "QRType.event routes to ComingSoonQRScreen in qr_generator_screen.dart (form UI deferred to plan 02-02 or later)"
  - "FeatureType.qrTypeEvent added so feature gate infrastructure covers event type consistently with existing types"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-01"
  tasks_completed: 2
  files_modified: 16
---

# Phase 2 Plan 01: QR Generator Domain Layer — Event Type + Pagination Summary

QRType.event added (identifier: vevent, cyan gradient) with EventData VCALENDAR/VEVENT iCal model; getUserQRCodesPaginated wired through the full repository stack using Supabase .range() with local cache fallback.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Add QRType.event, EventData iCal model, i18n keys, regenerate l10n | `1d34017` |
| 2 | Add getUserQRCodesPaginated to repository + datasource + SQL migration | `057ce60` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Non-exhaustive switch statements in presentation layer**
- **Found during:** Task 1 verification (flutter analyze)
- **Issue:** Adding `QRType.event` to the enum caused 8 non-exhaustive switch errors across `qr_form_screen.dart` (5 switches), `qr_preview_widget.dart` (2 switches), and `qr_generator_screen.dart` (1 switch). These are compile-time errors, not warnings.
- **Fix:** Added `case QRType.event:` fallthrough to all 8 switches. `qr_form_screen.dart` routes event to the existing "coming soon" fallthrough branch. `qr_preview_widget.dart` returns sample iCal data and "Calendar event (iCal format)" text. `qr_generator_screen.dart` routes event to `ComingSoonQRScreen(qrType: qrType)`.
- **Files modified:** qr_form_screen.dart, qr_preview_widget.dart, qr_generator_screen.dart
- **Commit:** `1d34017`

**2. [Rule 1 - Bug] Non-exhaustive switch statements in subscription feature gate**
- **Found during:** Task 2 verification (full-project flutter analyze)
- **Issue:** `feature_gate_providers.dart` had two switch statements over `QRType` that were non-exhaustive after adding `event`. Additionally, `FeatureType` enum lacked `qrTypeEvent` which is required for consistent gate coverage.
- **Fix:** Added `FeatureType.qrTypeEvent` to `feature_access.dart` with `displayName = 'Event QR Code'`; added `QRType.event` cases in `_qrTypeToFeature()` and `_qrTypeDisplayName()` in `feature_gate_providers.dart`. `QRType.values` in the Pro plan's `allowedQRTypes` automatically includes `event` — no change needed there.
- **Files modified:** feature_access.dart, feature_gate_providers.dart
- **Commit:** `057ce60`

## Threat Flags

None found. No new network endpoints, auth paths, or trust boundary changes introduced. The `getUserQRCodesPaginated` query uses the same `qr_codes` table already protected by RLS (user_id = auth.uid()) per existing migration 20250728000000. The `.range()` addition only changes page slice, not data access scope — T-02-01 disposition `mitigate` satisfied.

## Known Stubs

- `qr_generator_screen.dart`: `QRType.event` routes to `ComingSoonQRScreen` — intentional for v1, event form UI deferred to plan 02-02 or later when the form suite is extended.
- `qr_form_screen.dart`: event falls through to `_buildComingSoonForm()` — same intentional stub as wifi/email/location.

These stubs do NOT prevent the plan's goal (domain layer foundation for plans 02-02 and 02-03) — the entity, repository interface, and implementation are fully wired.

## Verification

```
flutter analyze --no-fatal-warnings  → No issues found (0 errors, 0 warnings)
QRType.event in enum                 → FOUND (identifier: vevent, cyan gradient, event_rounded icon)
EventData.qrData serializes iCal     → BEGIN:VCALENDAR + BEGIN:VEVENT confirmed in source
getUserQRCodesPaginated abstract     → FOUND in qr_repository.dart
getUserQRCodesPaginated impl         → FOUND in qr_repository_impl.dart + qr_supabase_data_source.dart
Migration file                       → FOUND at supabase/migrations/20260501100000_add_event_qr_type.sql
```

## Self-Check: PASSED

- [x] `lib/features/qr_generator/domain/entities/qr_type.dart` exists and contains `event`
- [x] `lib/features/qr_generator/domain/entities/qr_data_models.dart` contains `EventData`
- [x] `lib/features/qr_generator/domain/repositories/qr_repository.dart` declares `getUserQRCodesPaginated`
- [x] `lib/features/qr_generator/data/repositories/qr_repository_impl.dart` implements `getUserQRCodesPaginated`
- [x] `supabase/migrations/20260501100000_add_event_qr_type.sql` exists
- [x] Commits `1d34017` and `057ce60` exist in git log
- [x] flutter analyze --no-fatal-warnings = 0 issues
