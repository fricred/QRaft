---
phase: 09-checkout-wompi-compliance
plan: "05"
subsystem: legal
tags: [ley-1480, ley-1581, habeas-data, pqrs, retracto, garantia, colombia-compliance]

requires:
  - phase: 09-03
    provides: PaymentResultScreen with Wompi WebView flow
  - phase: 09-04
    provides: Wompi webhook Edge Function + orders/payment_events schema

provides:
  - PrivacyPolicyScreen (8-section Ley 1581 full policy, Spanish)
  - HabeasDataScreen (data export + account deletion with pqrs audit trail)
  - PqrsScreen (FormBuilder form → pqrs_submissions table)
  - GarantiaScreen (3-month warranty claim form, Ley 1480 Art. 7-11)
  - TermsScreen (T&C with Ley 1480 retracto exclusion, IVA 19%, garantia)
  - RetractoDisclaimerWidget (canonical Ley 1480 Art. 47 amber card)
  - pqrs_submissions Supabase table + RLS (INSERT/SELECT own)
  - Profile "Legal y soporte" section with 5 tiles + Semantics identifiers
  - SignUpScreen privacy policy link below register button

affects:
  - Phase 10 (order detail screen — GarantiaScreen links via pqrs_submissions)
  - Phase 12 (account deletion automation — HabeasDataScreen creates paper trail)

tech-stack:
  added:
    - flutter_form_builder 10.3.0 (used in PqrsScreen)
    - form_builder_validators 11.1.2 (field validation in PqrsScreen)
  patterns:
    - Supabase RLS INSERT WITH CHECK user_id = auth.uid() for PQRS audit trail
    - Operator-manual deletion flow (Phase 12 will automate; pqrs row as paper trail)
    - RetractoDisclaimerWidget as reusable legal widget (not inline amber Container)

key-files:
  created:
    - lib/features/legal/presentation/pages/privacy_policy_screen.dart
    - lib/features/legal/presentation/pages/habeas_data_screen.dart
    - lib/features/legal/presentation/pages/pqrs_screen.dart
    - lib/features/legal/presentation/pages/garantia_screen.dart
    - lib/features/legal/presentation/pages/terms_screen.dart
    - lib/features/checkout/presentation/widgets/retracto_disclaimer_widget.dart
    - supabase/migrations/20260505000001_pqrs_schema.sql
  modified:
    - lib/features/checkout/presentation/pages/payment_result_screen.dart
    - lib/features/profile/presentation/pages/profile_screen.dart
    - lib/features/auth/presentation/pages/signup_screen.dart

key-decisions:
  - "Habeas data deletion is operator-manual until Phase 12; pqrs_submissions row provides Ley 1581 audit trail for SIC compliance"
  - "order_id FK in garantia/pqrs uses display number in subject/body; UUID lookup deferred to Phase 10 when OrderDetailScreen lands"
  - "RetractoDisclaimerWidget replaces inline amber Container from Plan 09-03 — single source of truth for Ley 1480 Art. 47 text"
  - "PqrsScreen uses flutter_form_builder already in pubspec; no new dependency needed"

requirements-completed: [LGL-02, LGL-03, LGL-04, LGL-05]

duration: 18min
completed: 2026-05-03
---

# Phase 09 Plan 05: Colombian Legal Compliance (LGL-02..LGL-05) Summary

**Full Ley 1480/1581 compliance: 5 legal screens, canonical RetractoDisclaimerWidget, pqrs_submissions table, and profile legal navigation — all wired before any paid transaction goes live.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-05-03T17:20:00Z
- **Completed:** 2026-05-03T17:38:40Z
- **Tasks:** 2/2
- **Files modified:** 10 (7 created, 3 modified)

## Accomplishments

- Created 5 Spanish-language legal screens covering all Colombian consumer law requirements (Ley 1480 + Ley 1581)
- Implemented PQRS module with FormBuilder form submitting to pqrs_submissions Supabase table with RLS
- Replaced inline amber Container in PaymentResultScreen with canonical RetractoDisclaimerWidget
- Added "Legal y soporte" section to ProfileScreen with 5 navigable tiles and Semantics identifiers per CONVENTIONS.md
- Added privacy/terms link to SignUpScreen below register button (Ley 1581 LGL-03)
- HabeasDataScreen provides data export request and account deletion with pqrs audit trail (Ley 1581 compliance)
- GarantiaScreen provides 3-month warranty claim (Ley 1480 Art. 7-11), clearly separate from retracto path

## Task Commits

1. **Task 1: PQRS migration + legal screens** - `cf05f56` (feat)
2. **Task 2: RetractoDisclaimerWidget + profile wiring + signup link** - `747cd62` (feat)

## Files Created/Modified

- `lib/features/legal/presentation/pages/privacy_policy_screen.dart` — 8-section Ley 1581 policy (StatelessWidget)
- `lib/features/legal/presentation/pages/habeas_data_screen.dart` — export + deletion flows, pqrs audit trail (ConsumerWidget)
- `lib/features/legal/presentation/pages/pqrs_screen.dart` — PQRS FormBuilder form → Supabase (ConsumerStatefulWidget)
- `lib/features/legal/presentation/pages/garantia_screen.dart` — 3-month warranty claim (ConsumerStatefulWidget)
- `lib/features/legal/presentation/pages/terms_screen.dart` — T&C with retracto exclusion (StatelessWidget)
- `lib/features/checkout/presentation/widgets/retracto_disclaimer_widget.dart` — canonical Ley 1480 Art. 47 amber card
- `supabase/migrations/20260505000001_pqrs_schema.sql` — pqrs_submissions DDL + RLS + indexes
- `lib/features/checkout/presentation/pages/payment_result_screen.dart` — replaced inline amber Container, added Terms link
- `lib/features/profile/presentation/pages/profile_screen.dart` — added "Legal y soporte" section with 5 tiles
- `lib/features/auth/presentation/pages/signup_screen.dart` — added privacy policy link below register button

## Deviations from Plan

None — plan executed exactly as written.

The plan noted that `flutter_form_builder` was already in pubspec.yaml — confirmed and used directly.

The plan specified replacing the "inline amber Container that was added in Plan 03" — done. The `RetractoDisclaimerWidget` is now the single source of truth.

## Known Stubs

- `GarantiaScreen`: "Adjuntar foto (próximamente)" button is disabled. Intentional — Storage photo upload deferred to Phase 10+ as documented in the plan.
- `pqrs_submissions.order_id` (UUID FK): GarantiaScreen and PqrsScreen store the order display number in subject/body text, not as a UUID FK, because Phase 10 will add the order lookup UI. This is intentional and documented.

## Threat Surface Scan

No new network endpoints or auth paths beyond those in the plan's threat model.

pqrs_submissions RLS mitigations applied:
- T-09-20: INSERT WITH CHECK user_id = auth.uid() — user_id is enforced server-side
- T-09-21: Habeas data deletion inserts audit pqrs_submissions row before signOut
- T-09-23: No UPDATE/DELETE client-side RLS policy on pqrs_submissions

## Self-Check: PASSED

All 7 created files confirmed present on disk. Both task commits confirmed in git log:
- cf05f56 — Task 1 legal screens + migration
- 747cd62 — Task 2 RetractoDisclaimerWidget + wiring

`flutter analyze --no-fatal-warnings` reports 0 issues project-wide.
