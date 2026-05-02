---
phase: 03-qr-scanner
plan: 02
subsystem: qr-scanner
tags: [gallery-scan, vcard, wifi, flutter-contacts, mobile-scanner]
dependency_graph:
  requires: [03-01]
  provides: [real-gallery-scan, vcard-contact-save, wifi-credential-sheet]
  affects: [scan_result_dialog, qr_scanner_provider, qr_scanner_screen]
tech_stack:
  added: []
  patterns: [analyzeImage-stop-start, FlutterContacts.insertContact, showModalBottomSheet-wifi]
key_files:
  created: []
  modified:
    - lib/features/qr_scanner/providers/qr_scanner_provider.dart
    - lib/features/qr_scanner/qr_scanner_screen.dart
    - lib/features/qr_scanner/widgets/scan_result_dialog.dart
decisions:
  - id: D-03-02-A
    choice: "scanFromGallery accepts MobileScannerController parameter (not stored in state)"
    rationale: "Controller is owned by the screen widget; passing by argument avoids provider coupling and is simpler to test"
  - id: D-03-02-B
    choice: "vCard and WiFi cases use early return instead of break+pop to avoid HapticFeedback after pop"
    rationale: "Calling Navigator.pop then HapticFeedback.mediumImpact on a disposed context causes mounted assertion; returning early skips the shared post-switch code"
  - id: D-03-02-C
    choice: "Added missing QRCodeType.vcard case in _getActionButtonText() and _getActionButtonIcon()"
    rationale: "Rule 2: button label was falling to default Share; correctness fix applied inline as part of Task 2"
metrics:
  duration: "31m"
  completed: "2026-05-02"
  tasks_completed: 2
  files_modified: 3
---

# Phase 3 Plan 02: Gallery Scan Real Implementation + vCard + WiFi Summary

Real gallery QR scanning via `controller.analyzeImage()`, vCard save via `flutter_contacts`, and WiFi credential bottom sheet with copy + settings navigation.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Replace mock gallery scan with controller.analyzeImage() | c6c1319 | qr_scanner_provider.dart, qr_scanner_screen.dart |
| 2 | vCard flutter_contacts save + WiFi credential bottom sheet | aa481bb | scan_result_dialog.dart |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added vcard case to _getActionButtonText() and _getActionButtonIcon()**
- **Found during:** Task 2
- **Issue:** `_getActionButtonText()` had no `QRCodeType.vcard` case so the button showed "Share" instead of "Save Contact"; `_getActionButtonIcon()` similarly showed the share icon
- **Fix:** Added `case QRCodeType.vcard: return 'Save Contact';` and matching `Icons.contact_page_rounded`
- **Files modified:** lib/features/qr_scanner/widgets/scan_result_dialog.dart
- **Commit:** aa481bb

## Implementation Notes

### Task 1: Gallery Scan

- `_processGalleryMockResult` deleted entirely — zero `testMode` keys will appear in scan_history
- `scanFromGallery` signature changed to `Future<void> scanFromGallery(MobileScannerController controller)`
- Camera stop/start wraps `analyzeImage` call: `await controller.stop()` before, `controller.start()` in `finally`
- `noQRFoundInImage` error state set when capture is null or barcodes list is empty — no Supabase write occurs
- `MobileScannerBarcodeException` caught specifically; camera always resumes via `finally`
- `qr_scanner_screen.dart` updated: `_scanFromGallery()` guards `_controller == null`, passes `_controller!`

### Task 2: vCard + WiFi

**vCard path:**
- `FlutterContacts.requestPermission()` called first
- Permission denied: orange SnackBar "Contacts permission required", early return (no insertContact)
- Permission granted: builds `Contact` with first/last name split, Phone, Email, Organization from parsedData
- `FlutterContacts.insertContact(contact)` called, success SnackBar shown, dialog dismissed
- Uses early `return` instead of `break` to avoid post-switch haptic on dismissed context

**WiFi path:**
- Reads ssid, password, security from parsedData with safe defaults
- `showModalBottomSheet` presents `_WifiCredentialsSheet` (dark, rounded top)
- Sheet: WiFi icon + "WiFi Network" title + security badge (e.g., "WPA")
- `_CredentialRow` for SSID (plain) and Password (obscured with bullets, max 16)
- Copy button in each row: `Clipboard.setData` + haptic + green SnackBar
- "Open WiFi Settings": iOS `App-prefs:root=WIFI`, Android `android.settings.WIFI_SETTINGS`, fallback `openAppSettings()`
- Uses early `return` (sheet stays open for user interaction)

## Threat Mitigations Applied

| Threat | Mitigation |
|--------|-----------|
| T-03-02-A: vCard injection | flutter_contacts only maps name/phone/email/org from parsedData; raw vCard not passed to Contacts API |
| T-03-02-C: analyzeImage crash | MobileScannerBarcodeException catch; controller.start() in finally guarantees camera resume |

## Known Stubs

None.

## Threat Flags

None — no new trust boundaries introduced beyond those in the plan's threat model.

## Self-Check: PASSED

- [x] qr_scanner_provider.dart exists with analyzeImage and no testMode/mock
- [x] qr_scanner_screen.dart exists with `_controller!` passed to scanFromGallery
- [x] scan_result_dialog.dart exists with FlutterContacts, _WifiCredentialsSheet, vcard/wifi cases
- [x] Commit c6c1319 verified (feat(03-02): replace mock gallery scan)
- [x] Commit aa481bb verified (feat(03-02): vCard flutter_contacts save + WiFi credential bottom sheet)
- [x] flutter analyze lib/features/qr_scanner/ = 0 issues
