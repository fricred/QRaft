---
phase: 04-redirect-service-foundation
plan: 03
type: execute
wave: 3
depends_on:
  - 04-01
files_modified:
  - lib/features/redirect/presentation/screens/redirect_edit_screen.dart
  - lib/features/redirect/presentation/providers/redirect_providers.dart
  - lib/features/qr_library/qr_library_screen.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_es.arb
autonomous: true
requirements:
  - RDR-04
must_haves:
  truths:
    - "Authenticated user can edit `destination_url` of QRs they own from inside the app (RDR-04 — free in v1)"
    - "`RedirectEditScreen` exists with a text field for the new destination URL (validation: non-empty, valid URL format)"
    - "Save action calls `redirectRepository.updateDestinationUrl(slug, newUrl)` and pops with success"
    - "The QR library screen surfaces an 'Edit destination' action for URL-type QRs that have a redirect slug"
    - "`flutter analyze --no-fatal-warnings` exits 0"
  artifacts:
    - path: "lib/features/redirect/presentation/screens/redirect_edit_screen.dart"
      provides: "Screen for editing destination URL of a redirect"
      contains: "RedirectEditScreen"
---

# Plan 04-03: Flutter Destination URL Editing

## Objective
Build the Flutter UI that lets users edit the destination URL of their QRs (RDR-04). A QR that encodes `qraft.link/{slug}` can have its destination updated without re-printing.

## Tasks

### Task 1 — RedirectEditScreen + providers

Create `lib/features/redirect/presentation/screens/redirect_edit_screen.dart`:
- ConsumerStatefulWidget
- TextFormField for new destination URL with validation (non-empty + URI.tryParse check)
- PrimaryGlassButton "Save" calls `ref.read(redirectRepositoryProvider).updateDestinationUrl(slug, newUrl)`
- Shows loading + success SnackBar
- Maestro Key: `redirect_edit_screen_root`, `redirect_url_field`, `redirect_save_button`

Update providers in `redirect_providers.dart`:
- `redirectRepositoryProvider` — provides `RedirectRepositoryImpl`

### Task 2 — Wire into QR library

In `qr_library_screen.dart`: add "Edit redirect destination" option in QR item long-press menu for `QRType.url` items that have a slug. Navigate to `RedirectEditScreen(slug: qrEntity.slug)`.

Add i18n: `editRedirectDestination`, `redirectDestinationUpdated`.

Commit, create SUMMARY.md, update STATE/ROADMAP.
