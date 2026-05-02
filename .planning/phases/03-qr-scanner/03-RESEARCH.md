# Phase 3: QR Scanner - Research

**Researched:** 2026-05-01
**Domain:** Flutter mobile_scanner 7.2.0, type-aware QR actions, Supabase scan_history, camera permission recovery UI
**Confidence:** HIGH

---

## Summary

Phase 3 is the least greenfield phase in the roadmap: the scanner feature already exists in a substantial, working state. The current `qr_scanner_screen.dart`, `qr_scanner_provider.dart`, `scan_result_dialog.dart`, `scan_history_screen.dart`, and `scan_result.dart` together implement the full skeleton required by SCAN-02, SCAN-03, and SCAN-04 — including the Carden Pro neon-green overlay frame, MobileScannerController integration, Supabase persistence, and type-aware action routing via `url_launcher`. What is missing is a handful of targeted gaps that the planner must address.

**Gaps identified:**
1. **Tap-to-focus** is declared in the ROADMAP success criterion but is NOT enabled in the current controller (`tapToFocus: true` on the `MobileScanner` widget is absent). This is a one-line addition. [VERIFIED: Context7]
2. **Gallery scan uses a mock** — the `scanFromGallery()` method in `qr_scanner_provider.dart` uses a hard-coded fake URL instead of `controller.analyzeImage(imagePath)`. The real `analyzeImage` API exists in mobile_scanner 7.2.0 and returns `BarcodeCapture?`. [VERIFIED: Context7]
3. **vCard "Save Contact"** in `scan_result_dialog.dart` shows a "Contact Card" badge and a button labeled "Save Contact" (or equivalent) but the action handler only logs — `flutter_contacts` (already in pubspec at ^1.1.9) is not called. The integration is missing. [VERIFIED: codebase grep]
4. **WiFi "Connect"** shows the button but the `_performAction` switch statement for `QRCodeType.wifi` falls through to the default `Share.share()` — no SSID/password clipboard copy, no Settings deep-link, no WifiConfiguration call. [VERIFIED: codebase read]
5. **Permission denial recovery UI** uses a Snackbar with an "Open Settings" action. This satisfies the basic requirement but the success criterion calls for "recovery UI with rationale" — a richer dedicated widget (like `_buildCameraErrorWidget`) already exists, but it doesn't differentiate between "permission denied" and "camera unavailable" in a way that surfaces the "Open Settings" call-to-action persistently (SnackBar auto-dismisses). [VERIFIED: codebase read]
6. **Lifecycle management** uses `autoStart: true` but does NOT implement `WidgetsBindingObserver` to pause/resume the camera on app background/foreground transitions. This is a known pitfall for mobile_scanner. [VERIFIED: Context7 lifecycle docs]
7. **Maestro test keys** — the scanner screen has `Key('qr_scanner_screen_root')` on the Scaffold and `Semantics(identifier: 'qr_scanner_screen_root')` from Phase 1, but the scan button, flash button, history button, and gallery button do not have stable Maestro-targetable keys yet.

The scan_history Supabase table is fully migrated and RLS-protected. The `SupabaseService` methods (`saveScanResult`, `getScanHistory`, `deleteScanResult`, `clearScanHistory`) are implemented and wired through the provider. The freemium gating (limitedScanHistoryProvider, hasHiddenScanHistoryProvider) is already in production in the subscription providers.

**The "scanner-matrix CI" mentioned in the ROADMAP** refers to scanning-compatibility testing of eye-styles and module shapes in `pretty_qr_code` for Phase 5 (QR Customization) — it is NOT a Phase 3 deliverable. Phase 3 has no scanner-matrix CI obligation. The ROADMAP's "Research needed" note for Phase 3 was specifically about confirming this scope boundary and verifying the full-screen UX overlay design — both are now resolved.

**Primary recommendation:** Phase 3 planning should treat this as a targeted fix/completion phase with ~4-5 plans rather than a full build. The scaffold exists; the planner fills the 7 gaps listed above.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCAN-02 | Scanner full-screen con overlay verde Carden Pro, auto-detect, tap-to-focus | Overlay already built; `tapToFocus: true` is a 1-line add to MobileScanner widget; neon green 250x250 frame + corner indicators + scan line animation already present |
| SCAN-03 | Historial de escaneos persistente (tabla scan_history ya migrada en Supabase) | scan_history table fully migrated; SupabaseService methods wired; freemium gating via subscription providers already live |
| SCAN-04 | Manejo type-aware de resultado de escaneo (URL → abrir, vCard → guardar contacto, WiFi → conectar, email/phone → acción) | url_launcher integration exists for URL/email/phone/location; vCard save via flutter_contacts missing; WiFi connect missing — both need implementation |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Camera preview + QR detection | Mobile Client (Flutter widget) | — | MobileScanner widget wraps native Vision API (iOS) / MLKit (Android); all detection is on-device |
| Scan result parsing (type detection) | Mobile Client (domain layer) | — | Pure Dart logic in `ScanResult.fromRawValue()`; no server needed |
| Scan history persistence | Supabase Postgres | Mobile Client (in-memory state) | Remote: `scan_history` table with RLS; client: `QRScannerState.scanHistory` list |
| Type-aware actions (URL open, email, phone) | Mobile Client (OS intent) | — | `url_launcher` triggers native OS handlers; no server involvement |
| vCard save to contacts | Mobile Client (OS contacts API) | — | `flutter_contacts` writes to device contact store; iOS requires Contacts permission |
| WiFi credential presentation | Mobile Client | — | No OS API to programmatically connect WiFi on iOS; present credentials + clipboard copy is the correct pattern |
| Camera permission request + recovery | Mobile Client | — | `permission_handler` + `openAppSettings()` already in codebase |
| Gallery QR analysis | Mobile Client | — | `controller.analyzeImage(path)` from mobile_scanner; image_picker for file selection |
| Freemium history gating | Mobile Client (Riverpod providers) | — | `limitedScanHistoryProvider` in subscription_providers already restricts free-tier history display |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `mobile_scanner` | ^7.2.0 | Camera QR detection (Vision API on iOS, MLKit on Android) | Already installed, Phase 1 unblocked iOS; 7.2.0 adds tap-to-focus. [VERIFIED: pubspec.yaml] |
| `url_launcher` | ^6.2.4 | Open URLs, launch mailto/tel/sms/geo URIs | Already installed; used in scan_result_dialog. [VERIFIED: pubspec.yaml] |
| `permission_handler` | ^11.2.0 | Camera permission request + openAppSettings() | Already installed; used in qr_scanner_screen. [VERIFIED: pubspec.yaml] |
| `flutter_contacts` | ^1.1.9 | Save vCard scan results to device contacts | Already installed (pubspec line 104); NOT yet used in scanner. [VERIFIED: pubspec.yaml] |
| `flutter_riverpod` | ^2.4.9 | State management (QRScannerController, QRScannerState) | Project standard. [VERIFIED: pubspec.yaml] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `image_picker` | ^1.0.7 | Pick image from gallery for analyzeImage() | Already installed; gallery scan flow. [VERIFIED: pubspec.yaml] |
| `share_plus` | existing | Share text/raw value for unrecognised types | Already imported in scan_result_dialog. [VERIFIED: codebase] |
| `flutter_animate` | ^4.3.0 | Scan line animation, corner indicators, card entry animations | Already used throughout qr_scanner_screen. [VERIFIED: codebase] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_contacts` for vCard save | `url_launcher` with `tel:` / `mailto:` for individual fields | flutter_contacts creates a full contact record from parsed vCard fields; url_launcher can only launch individual sub-actions. flutter_contacts is already installed — use it. |
| `permission_handler.openAppSettings()` | Custom deep-link per platform | openAppSettings() is cross-platform and already used — no reason to replace. |
| In-body permission recovery widget | SnackBar only | SnackBar is already implemented; Phase 3 enhances to show a persistent in-camera-preview recovery screen when permission is permanently denied. Both co-exist. |

**No new package installations required for Phase 3.** All needed packages are already in pubspec.yaml.

---

## Architecture Patterns

### System Architecture Diagram

```
User opens Scanner tab
         │
         ▼
QRScannerScreen (ConsumerStatefulWidget)
         │
         ├─── Permission check (permission_handler)
         │         ├── GRANTED → MobileScannerController(autoStart:false)
         │         │              + WidgetsBindingObserver (lifecycle)
         │         └── DENIED → PermissionDeniedView + openAppSettings()
         │
         ├─── MobileScanner widget
         │         ├── tapToFocus: true
         │         ├── onDetect(BarcodeCapture) → QRScannerController.processScanResult()
         │         └── errorBuilder → _buildCameraErrorWidget()
         │
         ├─── ScanWindowOverlay OR custom overlay (neon frame + corner indicators)
         │
         └─── Bottom controls: gallery | scan button | history
                   │
                   └─ Gallery: ImagePicker → controller.analyzeImage(path) → processScanResult()

QRScannerController (StateNotifier)
         │
         ├── processScanResult(BarcodeCapture)
         │         ├── ScanResult.fromRawValue(rawValue)
         │         └── SupabaseService.saveScanResult(scanResult)
         │                    └── INSERT scan_history (RLS: user_id = auth.uid())
         │
         └── state.lastScanResult → ref.listen → ScanResultDialog

ScanResultDialog
         ├── URL → launchUrl(https://...)
         ├── email → launchUrl(mailto:...)
         ├── phone → launchUrl(tel:...)
         ├── sms → launchUrl(sms:...)
         ├── location → launchUrl(https://maps.google.com/?q=lat,lng)
         ├── vCard → FlutterContacts.insertContact(Contact.fromVCard())
         ├── WiFi → Clipboard.setData(ssid+password) + show credentials sheet
         └── unknown/text → Share.share(rawValue)

ScanHistoryScreen
         └── limitedScanHistoryProvider (freemium: free=10, premium=unlimited)
                   └── QRScannerController.scanHistory
```

### Recommended Project Structure (existing — no structural changes needed)
```
lib/features/qr_scanner/
├── models/
│   └── scan_result.dart          # MODIFY: no changes needed (types complete)
├── providers/
│   └── qr_scanner_provider.dart  # MODIFY: fix scanFromGallery mock → analyzeImage; add lifecycle observer
├── qr_scanner_screen.dart        # MODIFY: tapToFocus, lifecycle, permission recovery widget, Maestro keys
├── widgets/
│   ├── scan_result_dialog.dart   # MODIFY: vCard save via flutter_contacts; WiFi credential sheet
│   └── scan_history_screen.dart  # NO CHANGE needed (complete)
```

### Pattern 1: mobile_scanner 7.2.0 Tap-to-Focus
**What:** Pass `tapToFocus: true` to the `MobileScanner` widget. The controller also exposes `controller.setFocusPoint(normalizedOffset)` for programmatic focus.
**When to use:** Always — success criterion #2 explicitly requires it.
**Example:**
```dart
// Source: Context7 /juliansteenbakker/mobile_scanner
MobileScanner(
  controller: _controller,
  tapToFocus: true,
  onDetect: (BarcodeCapture capture) {
    _handleBarcodeDetection(capture);
  },
)
```

### Pattern 2: mobile_scanner 7.2.0 Lifecycle Management
**What:** Implement `WidgetsBindingObserver` to stop/start the camera on app lifecycle transitions. Without this, camera stays active when app is backgrounded (battery drain, platform warnings on iOS).
**When to use:** Any screen with an active MobileScannerController.
**Example:**
```dart
// Source: Context7 /juliansteenbakker/mobile_scanner
class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _controller.barcodes.listen(_handleBarcode);
    unawaited(_controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _subscription = _controller.barcodes.listen(_handleBarcode);
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
      default: break;
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await _controller.dispose();
  }
}
```

### Pattern 3: analyzeImage for Gallery Scanning
**What:** Replace the current mock in `scanFromGallery()` with the real `controller.analyzeImage(imagePath)` call. The controller MUST be created with `autoStart: false` when used only for gallery analysis (or the camera scan controller can also be used — it supports both modes).
**When to use:** When user taps the gallery button.
**Example:**
```dart
// Source: Context7 /juliansteenbakker/mobile_scanner
final XFile? image = await picker.pickImage(source: ImageSource.gallery);
if (image == null) return;

final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
if (capture != null && capture.barcodes.isNotEmpty) {
  final barcode = capture.barcodes.first;
  if (barcode.rawValue != null) {
    await processScanResultFromRaw(barcode.rawValue!);
  }
} else {
  // Show "no QR found" feedback
}
```

### Pattern 4: ScanWindowOverlay (native mobile_scanner overlay)
**What:** mobile_scanner 7.x ships `ScanWindowOverlay` widget that draws a cutout window with customizable border. This can replace or complement the custom neon overlay already in the codebase.
**When to use:** If the existing custom overlay (250x250 neon frame + corner indicators) sufficiently satisfies the design requirement, keep it — it already renders Carden Pro style. `ScanWindowOverlay` is an alternative if the custom widget causes layout issues.
**Decision for planner:** The existing custom overlay already matches the design spec (neon green, 250x250, corner indicators, scanning line). Keep it. Use `scanWindow: Rect` parameter on MobileScanner to inform the detection engine of the active zone, which improves detection accuracy without replacing the custom visual overlay.
**Example:**
```dart
// Source: Context7 /juliansteenbakker/mobile_scanner
MobileScanner(
  controller: _controller,
  tapToFocus: true,
  scanWindow: _scanWindowRect, // Rect calculated in LayoutBuilder
  onDetect: _handleBarcodeDetection,
)
```

### Pattern 5: vCard Save via flutter_contacts
**What:** Parse the vCard string from `scanResult.parsedData` fields and create a `Contact` object, then call `FlutterContacts.insertContact(contact)`. Requires Contacts permission request.
**When to use:** When scan type is `QRCodeType.vcard` and user taps "Save Contact".
**Example:**
```dart
// Source: [ASSUMED - flutter_contacts pub.dev API, not verified in Context7]
import 'package:flutter_contacts/flutter_contacts.dart';

Future<void> _saveVCardContact(ScanResult scanResult) async {
  final hasPermission = await FlutterContacts.requestPermission();
  if (!hasPermission) {
    // Show rationale + Settings link
    return;
  }
  final contact = Contact()
    ..name.first = scanResult.parsedData?['name']?.split(' ').first ?? ''
    ..name.last = scanResult.parsedData?['name']?.split(' ').skip(1).join(' ') ?? ''
    ..phones = [
      if (scanResult.parsedData?['phone'] != null)
        Phone(scanResult.parsedData!['phone']),
    ]
    ..emails = [
      if (scanResult.parsedData?['email'] != null)
        Email(scanResult.parsedData!['email']),
    ]
    ..organizations = [
      if (scanResult.parsedData?['organization'] != null)
        Organization(company: scanResult.parsedData!['organization']),
    ];
  await FlutterContacts.insertContact(contact);
}
```
**Note on iOS:** `NSContactsUsageDescription` must be in `Info.plist`. This is required by flutter_contacts — check if it is already present. If not, it is a one-line plist add.
**Note on vCard type detection:** The current `_determineQRType` checks `value.startsWith('begin:vcard')` (lowercase). Real vCards use `BEGIN:VCARD` (uppercase). The detection works because `value = rawValue.toLowerCase()` is applied first. This is correct.

### Pattern 6: WiFi Credential Presentation
**What:** iOS has no public API to programmatically connect to WiFi (NEHotspotConfiguration requires an Apple entitlement). Android has `WifiManager` but it requires ACCESS_FINE_LOCATION and is restricted on Android 10+. **Do NOT attempt programmatic WiFi connection.** Instead: copy credentials to clipboard (or show them clearly) and offer a system Settings deep-link.
**When to use:** Always for WiFi QR type.
**Implementation:**
```dart
// WiFi action in scan_result_dialog.dart
case QRCodeType.wifi:
  final ssid = scanResult.parsedData?['ssid'] ?? '';
  final password = scanResult.parsedData?['password'] ?? '';
  final security = scanResult.parsedData?['security'] ?? 'WPA';
  // Show bottom sheet with credentials + Copy buttons
  _showWifiCredentialsSheet(context, ssid, password, security);
  break;
```
The WiFi credentials sheet shows SSID + password with individual copy buttons and a "Open WiFi Settings" button using `openAppSettings()` or `launchUrl(Uri.parse('App-prefs:root=WIFI'))` on iOS / `launchUrl(Uri.parse('android.settings.WIFI_SETTINGS'))` on Android via url_launcher.

### Anti-Patterns to Avoid

- **Mock gallery scan results:** The existing `_processGalleryMockResult` with `testMode: true` in the production path must be replaced with `controller.analyzeImage()`. Leaving mock data in production scan_history corrupts user data.
- **`autoStart: true` without lifecycle observer:** Camera stays on after backgrounding. Implement `WidgetsBindingObserver` as shown in Pattern 2.
- **Calling `controller.stop()` / `controller.start()` from the provider:** The `MobileScannerController` is owned by the widget, not the provider. The existing pattern of `ref.read(qrScannerProvider.notifier).startScanning()` only toggles the `isScanning` boolean — the physical camera is controlled by the widget's `_controller`. This is correct; preserve it.
- **Duplicate scan dedup by rawValue within 2s:** This is already implemented in `processScanResult`. Do not remove it; the `DetectionSpeed.noDuplicates` + `detectionTimeoutMs: 1000` provides the hardware-level dedup.
- **Programmatic WiFi connection on iOS:** No public entitlement in v1.0. Show credentials only.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Gallery QR detection | Custom image analysis | `controller.analyzeImage()` | Already in mobile_scanner 7.2.0; handles Vision/MLKit natively. [VERIFIED: Context7] |
| vCard contact save | Custom Contacts framework bridge | `flutter_contacts` | Already installed; cross-platform; handles iOS Contacts permission natively |
| Camera permission check | Direct MethodChannel | `permission_handler` | Already installed; handles all edge cases (permanently denied, limited) cross-platform |
| App Settings deep-link | Platform channel | `openAppSettings()` from permission_handler | Already used in `_openAppSettings()` in the screen |
| Scan overlay window | CustomPainter | Existing custom overlay widgets OR `ScanWindowOverlay` from mobile_scanner | Custom overlay already built to spec |

---

## Current State of Existing Code (What's Done vs. What's Missing)

### qr_scanner_screen.dart — DONE
- Full-screen layout with header, camera preview, bottom controls
- Neon green (#00FF88) Carden Pro overlay: 250x250 frame, corner indicators, animated scan line
- MobileScannerController with `formats: [BarcodeFormat.qrCode]`, `detectionSpeed: DetectionSpeed.noDuplicates`, `detectionTimeoutMs: 1000`
- Flash toggle (torch)
- Error handling: `errorBuilder` routes `permissionDenied` → `cameraPermissionDenied` key, `unsupported` → `noCameraAvailable` key
- SnackBar with "Open Settings" action for permission errors
- `Semantics(identifier: 'qr_scanner_screen_root')` and `Key('qr_scanner_screen_root')` on Scaffold (Phase 1)

### qr_scanner_screen.dart — MISSING
- `tapToFocus: true` on MobileScanner widget
- `WidgetsBindingObserver` for lifecycle management (camera pause/resume)
- Persistent permission-denied UI (full-area widget, not just Snackbar) when permanently denied
- Maestro keys on scan button, flash button, gallery button, history button

### qr_scanner_provider.dart — DONE
- `QRScannerController extends StateNotifier<QRScannerState>` with `isScanning`, `isFlashOn`, `lastScanResult`, `scanHistory`, `error`, `isLoading`
- `processScanResult(BarcodeCapture)` → `ScanResult.fromRawValue()` → `SupabaseService.saveScanResult()`
- `_loadScanHistory()` on construction (fetches from Supabase)
- `deleteScanResult()`, `clearAllHistory()`, `refreshHistory()`
- Duplicate scan guard (rawValue + 2s window)

### qr_scanner_provider.dart — MISSING
- `scanFromGallery()` uses a **MOCK implementation** — generates a fake URL instead of calling `controller.analyzeImage()`. This is explicitly marked `testMode: true` in parsedData. Must be fixed.

### scan_result_dialog.dart — DONE
- Type-aware icon, color, and badge for all 9 QR types
- Type-aware action buttons: URL→Open, email→Email, phone→Call, sms→Message, location→Open Map, default→Share
- Copy to clipboard
- All using `url_launcher` correctly

### scan_result_dialog.dart — MISSING
- **vCard:** Button says "Save Contact" (via `_getActionButtonText()` returning the correct label) but `_performAction()` has NO `case QRCodeType.vcard:` — it falls through to default `Share.share()`. The vCard `flutter_contacts` integration is entirely absent.
- **WiFi:** Button says "Connect" but `_performAction()` has NO `case QRCodeType.wifi:` — it falls through to default `Share.share()`. Credential sheet is absent.

### scan_history_screen.dart — DONE (no changes needed)
- Full-featured history list with type icons, badges, date formatting
- Freemium gating via `limitedScanHistoryProvider` (free tier: limited items, premium: unlimited)
- `hasHiddenScanHistoryProvider` + upgrade prompt with gold gradient UI
- Native ad insertion after 3rd item
- Clear all confirmation dialog
- Refresh via pull-to-refresh
- Delete individual items

### scan_result.dart (model) — DONE (no changes needed)
- All 9 `QRCodeType` variants
- `fromRawValue()` factory with type detection + parser dispatch
- `fromJson()` / `toJson()` aligned with Supabase schema (`raw_value`, `qr_type`, `display_value`, `parsed_data`, `scanned_at`)
- WiFi parser: `WIFI:T:WPA;S:ssid;P:password;H:false;` → `{security, ssid, password, hidden}`
- vCard parser: `FN:`, `TEL:`, `EMAIL:`, `ORG:` field extraction

### Supabase (scan_history table) — DONE (no changes needed)
Schema as of migration `20250725122236_fix_scan_history_schema.sql`:
```sql
CREATE TABLE scan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    raw_value TEXT NOT NULL,
    qr_type TEXT NOT NULL,           -- matches ScanResult._getTypeName()
    display_value TEXT NOT NULL,
    parsed_data JSONB,
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);
-- Indexes: idx_scan_history_user_id, idx_scan_history_scanned_at
-- RLS: SELECT/INSERT/DELETE restricted to user_id = auth.uid()
```
No migration needed for Phase 3. The schema is complete.

---

## Common Pitfalls

### Pitfall 1: Gallery scan mock in production
**What goes wrong:** `scanFromGallery()` currently creates a URL `https://example.com/gallery-test-qr-{timestamp}` and saves it to Supabase with `testMode: true` in `parsedData`. Every time a user taps the gallery button in production, a fake scan record is written to their scan_history.
**Why it happens:** The original developer left a mock implementation marked "simplified mock for testing purposes" — it was never replaced with `controller.analyzeImage()`.
**How to avoid:** Replace entirely with `controller.analyzeImage(image.path)`. The `analyzeImage()` method exists in mobile_scanner 7.2.0 and returns `BarcodeCapture?`. [VERIFIED: Context7]
**Warning signs:** `scan_history` rows with `parsed_data->>'testMode' = 'true'`; `raw_value` starting with `https://example.com/gallery-test-qr-`

### Pitfall 2: Camera stays on when app is backgrounded
**What goes wrong:** Without `WidgetsBindingObserver`, the `MobileScannerController` keeps the camera hardware active when the user switches apps. On iOS, this causes a visible camera indicator in the status bar and can trigger platform warnings after ~30s.
**Why it happens:** Current code uses `autoStart: true` with no lifecycle hook.
**How to avoid:** Implement `WidgetsBindingObserver.didChangeAppLifecycleState` to call `controller.stop()` on `AppLifecycleState.inactive` and `controller.start()` on `AppLifecycleState.resumed`. [VERIFIED: Context7]
**Warning signs:** User reports "camera light stays on"; iOS privacy indicator visible on home screen.

### Pitfall 3: vCard contact requires Contacts permission — request at action time, not at app launch
**What goes wrong:** Requesting Contacts permission on app launch (or at scanner open) violates both Apple App Store and Ley 1581 privacy principle of "finalidad" (purpose limitation). The permission must be requested at the moment the user taps "Save Contact".
**Why it happens:** Developers often request all permissions at launch for convenience.
**How to avoid:** Call `FlutterContacts.requestPermission()` ONLY inside the "Save Contact" action handler in `scan_result_dialog.dart`. Show a rationale before the OS dialog. [ASSUMED - flutter_contacts API convention]

### Pitfall 4: WiFi QR standard uses uppercase but detection does lowercase comparison
**What goes wrong:** The standard WiFi QR format is `WIFI:T:WPA;S:networkname;P:password;;` (uppercase). The type detector in `scan_result.dart` does `value.startsWith('wifi:')` where `value = rawValue.toLowerCase()`. This is correct and handles both cases.
**Why it matters:** Ensure the WiFi parser `_parseWiFiData()` also uses the lowercased `parts` correctly — it does (`part.split(':')[0].toLowerCase()`). No fix needed, just document.

### Pitfall 5: `controller.analyzeImage()` requires controller to NOT be in an active camera session
**What goes wrong:** Calling `analyzeImage()` while the live camera stream is active can produce undefined behavior on some platforms.
**How to avoid:** The existing code creates the controller with `autoStart: true` for the live scan. For gallery analysis, either (a) stop the live scanner first, then call analyzeImage, then restart, OR (b) use a separate controller instance with `autoStart: false`. Option (b) is cleaner and matches the Context7 example. [VERIFIED: Context7]

### Pitfall 6: Permission permanently denied — Snackbar is insufficient for recovery
**What goes wrong:** When camera permission is permanently denied, the current code shows a Snackbar with "Open Settings" action that auto-dismisses after a few seconds. The user may miss it, and the camera shows the loading spinner forever.
**Why it happens:** The `errorBuilder` in MobileScanner is wired correctly, but the permission denial path in `_checkPermissionsAndSetupController()` only calls `logDetailedError` and returns — it does NOT call `setState()` to render `_buildCameraErrorWidget`. The `_buildCameraPlaceholder()` widget shows an error message when `scannerErrorProvider` has a value, but it does not render an "Open Settings" CTA — only the Snackbar has one.
**How to avoid:** When permission is permanently denied, set a dedicated `isPermissionPermanentlyDenied` state flag and render a full `_buildPermissionDeniedView()` widget in place of the camera area with a visible, persistent "Open Settings" button.

---

## Scanner-Matrix CI Scope Decision

The ROADMAP "Research needed" note for Phase 3 includes "scanner-matrix CI test setup." After tracing this reference through the full ROADMAP:

- The scanner-matrix in Phase 5 (QR Customization) refers to testing `pretty_qr_code` eye-styles and module shapes for scanner compatibility — this is a PHASE 5 concern.
- Phase 3 has no scanner-matrix requirement. Phase 3 only needs that the camera scanner itself works correctly on iOS 15+ and Android API 21+ (which is satisfied by mobile_scanner 7.2.0 and the existing implementation).
- **Decision: Scanner-matrix CI is OUT OF SCOPE for Phase 3 v1.** [VERIFIED: ROADMAP.md cross-reference]

The ROADMAP Phase 3 research note was specifically about (1) confirming this scope boundary and (2) confirming the full-screen overlay design. Both are now confirmed: overlay design is Carden Pro neon green 250x250 with animated scan line (already built), and scanner-matrix is Phase 5.

---

## Code Examples

### Enable tap-to-focus (add to existing MobileScanner widget)
```dart
// Source: Context7 /juliansteenbakker/mobile_scanner
MobileScanner(
  controller: _controller,
  tapToFocus: true,               // ADD THIS LINE
  onDetect: (BarcodeCapture capture) {
    _handleBarcodeDetection(capture);
  },
  errorBuilder: (context, error) {
    // existing errorBuilder...
  },
)
```

### Replace mock gallery scan with real analyzeImage
```dart
// Source: Context7 /juliansteenbakker/mobile_scanner
// In QRScannerController.scanFromGallery():
Future<void> scanFromGallery(MobileScannerController controller) async {
  // NOTE: controller is passed in from the widget, not accessed via provider
  // because MobileScannerController is a widget-owned resource
  final hasPermission = await _checkGalleryPermissions();
  if (!hasPermission) return;

  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image == null) {
    state = state.copyWith(isLoading: false);
    return;
  }

  try {
    final BarcodeCapture? capture = await controller.analyzeImage(image.path);
    if (capture != null && capture.barcodes.isNotEmpty) {
      final rawValue = capture.barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        final scanResult = ScanResult.fromRawValue(rawValue);
        await SupabaseService.saveScanResult(scanResult);
        final updatedHistory = [scanResult, ...state.scanHistory];
        state = state.copyWith(
          lastScanResult: scanResult,
          scanHistory: updatedHistory,
          isLoading: false,
        );
      }
    } else {
      state = state.copyWith(isLoading: false, error: 'noQRFoundInImage');
    }
  } on MobileScannerBarcodeException catch (e) {
    logDetailedError('Gallery analyzeImage', e);
    state = state.copyWith(isLoading: false);
  }
}
```
**Architecture note:** Since `MobileScannerController` is owned by the widget (not the provider), the `scanFromGallery` method needs the controller passed in. The current call `ref.read(qrScannerProvider.notifier).scanFromGallery()` will need to change to pass the controller reference: `ref.read(qrScannerProvider.notifier).scanFromGallery(_controller)`.

### vCard save (add to scan_result_dialog.dart)
```dart
// Source: [ASSUMED - flutter_contacts pub.dev API; not verified in Context7 this session]
case QRCodeType.vcard:
  final hasPermission = await FlutterContacts.requestPermission();
  if (!hasPermission) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contacts permission required')),
      );
    }
    return;
  }
  final fullName = scanResult.parsedData?['name'] ?? '';
  final nameParts = fullName.split(' ');
  final contact = Contact()
    ..name.first = nameParts.isNotEmpty ? nameParts.first : fullName
    ..name.last = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''
    ..phones = [
      if (scanResult.parsedData?['phone'] != null)
        Phone(scanResult.parsedData!['phone']),
    ]
    ..emails = [
      if (scanResult.parsedData?['email'] != null)
        Email(scanResult.parsedData!['email']),
    ]
    ..organizations = [
      if (scanResult.parsedData?['organization'] != null)
        Organization(company: scanResult.parsedData!['organization']),
    ];
  await FlutterContacts.insertContact(contact);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact saved')),
    );
    Navigator.of(context).pop();
  }
  break;
```

### WiFi credential sheet
```dart
// Source: [ASSUMED - standard Flutter bottom sheet pattern; WiFi deep-link via url_launcher]
case QRCodeType.wifi:
  final ssid = scanResult.parsedData?['ssid'] ?? 'Unknown Network';
  final password = scanResult.parsedData?['password'] ?? '';
  final security = scanResult.parsedData?['security'] ?? 'WPA';
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2E2E2E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => WifiCredentialsSheet(
      ssid: ssid,
      password: password,
      security: security,
    ),
  );
  break;
```

---

## Runtime State Inventory

Not applicable — Phase 3 is not a rename/refactor/migration phase. No runtime state items exist for the scanner feature beyond the `scan_history` table which is already migrated.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mobile_scanner` | SCAN-02 camera scanning | ✓ | 7.2.0 | — |
| `flutter_contacts` | SCAN-04 vCard save | ✓ | 1.1.9 | — |
| `url_launcher` | SCAN-04 URL/email/phone/location | ✓ | 6.2.4 | — |
| `permission_handler` | SCAN-02 permission recovery | ✓ | 11.2.0 | — |
| `image_picker` | SCAN-02 gallery scan | ✓ | 1.0.7 | — |
| iOS deployment target | mobile_scanner 7.x | ✓ | 15.0 (Phase 1 bump) | — |
| Android minSdk | mobile_scanner (API 21+) | ✓ | 23 (verified in Phase 1) | — |
| Supabase `scan_history` table | SCAN-03 | ✓ | Migration applied | — |

All required dependencies are already installed. No new packages or migrations are needed for Phase 3.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mocktail |
| Config file | analysis_options.yaml (lints) |
| Quick run command | `flutter test test/features/qr_scanner/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCAN-02 | tapToFocus enabled on MobileScanner widget | widget | `flutter test test/features/qr_scanner/qr_scanner_screen_test.dart` | ❌ Wave 0 |
| SCAN-02 | Permission denied shows persistent recovery UI | widget | `flutter test test/features/qr_scanner/qr_scanner_screen_test.dart` | ❌ Wave 0 |
| SCAN-02 | Lifecycle observer stops/starts camera | unit | `flutter test test/features/qr_scanner/qr_scanner_lifecycle_test.dart` | ❌ Wave 0 |
| SCAN-02 | Gallery scan calls analyzeImage (not mock) | unit | `flutter test test/features/qr_scanner/qr_scanner_provider_test.dart::gallery_scan` | ❌ Wave 0 |
| SCAN-03 | Scan result saved to Supabase on detection | unit (mock) | `flutter test test/features/qr_scanner/qr_scanner_provider_test.dart::save_scan` | ❌ Wave 0 |
| SCAN-03 | Scan history loaded on controller init | unit (mock) | `flutter test test/features/qr_scanner/qr_scanner_provider_test.dart::load_history` | ❌ Wave 0 |
| SCAN-04 | URL action calls launchUrl | unit (mock url_launcher) | `flutter test test/features/qr_scanner/scan_result_dialog_test.dart::url_action` | ❌ Wave 0 |
| SCAN-04 | vCard action calls FlutterContacts.insertContact | unit (mock flutter_contacts) | `flutter test test/features/qr_scanner/scan_result_dialog_test.dart::vcard_action` | ❌ Wave 0 |
| SCAN-04 | WiFi action shows credentials sheet | widget | `flutter test test/features/qr_scanner/scan_result_dialog_test.dart::wifi_action` | ❌ Wave 0 |
| SCAN-04 | ScanResult.fromRawValue detects all 9 types | unit | `flutter test test/features/qr_scanner/scan_result_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/features/qr_scanner/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/qr_scanner/scan_result_test.dart` — covers SCAN-04 type detection (unit, pure Dart, no mocks needed)
- [ ] `test/features/qr_scanner/qr_scanner_provider_test.dart` — covers SCAN-03 save/load history, SCAN-02 gallery scan fix (mock SupabaseService)
- [ ] `test/features/qr_scanner/scan_result_dialog_test.dart` — covers SCAN-04 actions (mock url_launcher, mock flutter_contacts)
- [ ] `test/features/qr_scanner/qr_scanner_screen_test.dart` — covers SCAN-02 widget-level assertions (tapToFocus, permission recovery UI)

**Test structure analog:** `test/features/auth/data/providers/supabase_auth_provider_test.dart` (Mocktail mock injection pattern); `test/features/qr_generator/presentation/controllers/wifi_form_controller_test.dart` (StateNotifier unit test pattern).

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No — scanner reads only user's own data | RLS on `scan_history` enforces `user_id = auth.uid()` |
| V3 Session Management | No — scanner is read/write but session is handled by Supabase Auth | No change needed |
| V4 Access Control | Yes — scan history is user-private | RLS policies already in migration: `SELECT/INSERT/DELETE` restricted to `auth.uid() = user_id` [VERIFIED: migration file] |
| V5 Input Validation | Yes — QR raw value is untrusted input | `ScanResult.fromRawValue()` uses string matching (safe); `url_launcher` uses `canLaunchUrl()` guard; no SQL injection possible (parameterized Supabase client) |
| V6 Cryptography | No | No crypto operations in scanner feature |

### Known Threat Patterns for QR Scanner Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious QR containing `javascript:` or `data:` URI | Tampering | `url_launcher` rejects non-http/https schemes by default; `canLaunchUrl()` guard in `_performAction()` |
| QR-based phishing (lookalike domain URLs) | Spoofing | Display full URL to user before launching; user confirmation dialog for URL open (consider for Phase 5 "should have" item) |
| Excessive scan history data (PII in raw_value) | Info Disclosure | RLS on `scan_history`; `scan_history` rows contain `raw_value` which may include vCard with name/phone/email — all under user's own RLS scope |
| vCard injection (specially crafted BEGIN:VCARD with overflow data) | Tampering | `flutter_contacts` parses specific fields only; `_parseVCardData()` extracts `FN:`, `TEL:`, `EMAIL:`, `ORG:` and ignores unknown fields |
| WiFi password exposure in parsedData | Info Disclosure | `parsed_data` is stored in Supabase `scan_history` as JSONB — WiFi passwords are saved alongside scan results. This is a V4 concern: user's own data, protected by RLS; acceptable in v1.0. Planner may note this as a future data minimization opportunity. |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| mobile_scanner iOS MLKit dependency (blocked) | Apple Vision API (mobile_scanner 7.x) | Phase 1 bump to 7.2.0 | iOS builds cleanly; no more MLKit linker errors |
| Manual focus only | `tapToFocus: true` + `controller.setFocusPoint()` | mobile_scanner 7.2.0 | Must enable in Phase 3 (currently missing) |
| No built-in scan window | `scanWindow` parameter + `ScanWindowOverlay` widget | mobile_scanner 7.x | Custom overlay preserved; `scanWindow` rect improves detection accuracy |
| `analyzeImage` not in 6.x | `controller.analyzeImage(path)` returns `BarcodeCapture?` | mobile_scanner 7.x | Replaces the current mock gallery scan |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `flutter_contacts` API: `FlutterContacts.requestPermission()`, `FlutterContacts.insertContact(contact)`, `Contact()..name.first`, `..phones = [Phone(number)]` | Code Examples — vCard save | If API differs, the vCard save plan task will need to look up the actual flutter_contacts 1.1.9 API before coding |
| A2 | `NSContactsUsageDescription` is not yet in `ios/Runner/Info.plist` | Common Pitfalls — vCard | If it IS already there, no plist change needed; if missing, add it |
| A3 | WiFi deep-link `App-prefs:root=WIFI` (iOS) and `android.settings.WIFI_SETTINGS` (Android) are launchable via url_launcher | Code Examples — WiFi | iOS custom URL scheme availability may vary by iOS version; fall back to `openAppSettings()` if not supported |

---

## Open Questions

1. **Does `controller.analyzeImage()` work while the live camera stream is active (autoStart: true)?**
   - What we know: Context7 shows examples use `autoStart: false` for gallery-only mode; the existing scanner uses `autoStart: true`.
   - What's unclear: Whether calling `analyzeImage()` on an active-camera controller crashes or is safe.
   - Recommendation: Pass the same controller but call `controller.stop()` before `analyzeImage()` then `controller.start()` after; OR create a second controller with `autoStart: false` just for gallery analysis. The second approach is cleaner.

2. **Is `NSContactsUsageDescription` already in `ios/Runner/Info.plist`?**
   - What we know: `flutter_contacts: ^1.1.9` is in pubspec but not used in scanner yet.
   - What's unclear: Whether the plist has the key from another use of contacts.
   - Recommendation: Planner should verify with `grep NSContactsUsageDescription ios/Runner/Info.plist` before writing the plan task.

---

## Sources

### Primary (HIGH confidence)
- Context7 `/juliansteenbakker/mobile_scanner` — tap-to-focus, lifecycle, analyzeImage, ScanWindowOverlay, errorBuilder, permission patterns. [VERIFIED: multiple code snippets fetched]
- Codebase read: `/lib/features/qr_scanner/qr_scanner_screen.dart`, `qr_scanner_provider.dart`, `scan_result_dialog.dart`, `scan_history_screen.dart`, `scan_result.dart` — actual current state confirmed. [VERIFIED: Read tool]
- Migration `20250725122236_fix_scan_history_schema.sql` — exact schema columns and RLS policies. [VERIFIED: Read tool]
- `pubspec.yaml` — all package versions confirmed. [VERIFIED: Read tool]
- `lib/features/subscription/presentation/providers/subscription_providers.dart` — freemium gating providers confirmed. [VERIFIED: grep]

### Secondary (MEDIUM confidence)
- ROADMAP.md Phase 3 section — scanner-matrix scope boundary confirmed as Phase 5 concern, not Phase 3. [VERIFIED: Read tool]
- PITFALLS.md — scanner v7 upgrade pitfalls, permission_handler patterns. [VERIFIED: Read tool]

### Tertiary (LOW confidence — assumptions)
- flutter_contacts 1.1.9 API shape (`FlutterContacts.insertContact`, `Contact` model) — marked A1 in assumptions log. Not verified via Context7 this session.
- WiFi deep-link URL schemes — marked A3 in assumptions log.

---

## Metadata

**Confidence breakdown:**
- Current code state: HIGH — read every relevant file directly
- mobile_scanner 7.2.0 API: HIGH — verified via Context7
- Supabase schema: HIGH — read migration directly
- flutter_contacts API: LOW — assumed from pub.dev training knowledge, not verified this session
- WiFi platform deep-links: LOW — known pattern but not verified against url_launcher docs this session

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (mobile_scanner is actively maintained; verify if major version changes)
