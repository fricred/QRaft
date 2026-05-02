---
phase: 03-qr-scanner
plan: 01
subsystem: scanner
tags: [mobile_scanner, lifecycle, permissions, maestro, accessibility]
requires:
  - phase: 01-foundation-hardening
    provides: mobile_scanner 7.2.0 installed
provides:
  - tapToFocus:true on MobileScanner widget
  - WidgetsBindingObserver lifecycle (stop/start camera on background/foreground)
  - _buildPermissionDeniedView with openAppSettings() (scanner_open_settings_button)
  - Maestro Keys on 4 scanner buttons (flash, gallery, history, scan)
  - Lifecycle test suite (4 tests)
requirements-completed: [SCAN-02]
duration: ~15min
completed: 2026-05-02
---

# Phase 3 / Plan 01: Scanner Core Fixes

**tapToFocus + WidgetsBindingObserver lifecycle + persistent permission-denied recovery + Maestro Keys on 4 scanner buttons.**

## Commits
- `e1f39c4` feat(03-01): scanner tapToFocus + lifecycle observer + permission recovery + Maestro keys

## Key changes
- `qr_scanner_screen.dart` +132/-17: mixes in WidgetsBindingObserver, tapToFocus:true, _buildPermissionDeniedView, 4 Maestro Keys
- `test/features/qr_scanner/qr_scanner_lifecycle_test.dart` (NEW): 4 lifecycle + permission test groups
