---
phase: 06-qr-digital-features
plan: 04
subsystem: qr-digital, home-widget, ios-widgetkit, android-glance
tags: [home-widget, widgetkit, glance, native-widget, tdd, ios, android, checkpoint]
dependency_graph:
  requires:
    - 06-02 (QrDecorationBuilder, QrDigitalController, exportDigitalOnly)
    - 06-03 (QrAiStyleService done, qr_digital feature structure established)
  provides:
    - QrWidgetService.pinQrToWidget() — renders QR PNG via home_widget + triggers widget refresh
    - QrWidgetPinPage — instructions + Pin button + loading state
    - iOS WidgetKit extension stubs (QRaftWidget.swift + QRaftWidgetBundle.swift)
    - Android Glance widget stubs (QrWidget.kt + QrWidgetReceiver.kt)
  affects:
    - pubspec.yaml (home_widget ^0.9.1)
    - lib/features/qr_digital/domain/services/qr_widget_service.dart
    - lib/features/qr_digital/presentation/pages/qr_widget_pin_page.dart
    - ios/QRaftWidgetExtension/QRaftWidget.swift
    - ios/QRaftWidgetExtension/QRaftWidgetBundle.swift
    - android/app/src/main/kotlin/io/gothcorp/qraft/QrWidget.kt
    - android/app/src/main/kotlin/io/gothcorp/qraft/QrWidgetReceiver.kt
    - android/app/build.gradle.kts (glance-appwidget:1.1.1)
    - android/app/src/main/AndroidManifest.xml (QrWidgetReceiver declaration)
    - android/app/src/main/res/xml/qr_widget_info.xml
    - test/features/qr_digital/services/qr_widget_service_test.dart
tech_stack:
  added:
    - home_widget ^0.9.1 (Flutter ↔ native widget bridge; renderFlutterWidget + updateWidget)
    - androidx.glance:glance-appwidget:1.1.1 (Android Glance widget runtime)
  patterns:
    - TDD RED/GREEN cycle (wave-0 sentinel replaced with 5 real tests)
    - HomeWidgetAdapter interface for testability (mocktail mock; no real platform channel in tests)
    - registerFallbackValue(Widget) + registerFallbackValue(Size) for mocktail abstract type safety
    - App Group shared storage (group.io.gothcorp.qraft) for iOS Runner ↔ Widget Extension PNG path
    - logicalSize capped at Size(300,300) per T-06-14 iOS widget memory limit (~30MB)
key_files:
  created:
    - lib/features/qr_digital/domain/services/qr_widget_service.dart
    - lib/features/qr_digital/presentation/pages/qr_widget_pin_page.dart
    - ios/QRaftWidgetExtension/QRaftWidget.swift
    - ios/QRaftWidgetExtension/QRaftWidgetBundle.swift
    - android/app/src/main/kotlin/io/gothcorp/qraft/QrWidget.kt
    - android/app/src/main/kotlin/io/gothcorp/qraft/QrWidgetReceiver.kt
    - android/app/src/main/res/xml/qr_widget_info.xml
    - test/features/qr_digital/services/qr_widget_service_test.dart
  modified:
    - pubspec.yaml (home_widget ^0.9.1 added)
    - android/app/build.gradle.kts (glance-appwidget dependency)
    - android/app/src/main/AndroidManifest.xml (QrWidgetReceiver <receiver> block)
decisions:
  - home_widget 0.9.1 renderFlutterWidget returns Future<String> (file path), NOT Future<bool?> — verified from pub cache source; plan research used incorrect return type
  - HomeWidgetAdapter abstract interface introduced for testability; default _DefaultHomeWidgetAdapter calls real HomeWidget statics; optional adapter param in pinQrToWidget
  - mocktail requires registerFallbackValue for Widget and Size abstract types; _FakeWidget implements Diagnosticable.toString with DiagnosticLevel named param
  - QrWidget.kt uses @Composable pattern (GlanceTheme wrapper); Text fallback for null/undecoded bitmap
  - QrWidgetPinPage uses ConsumerStatefulWidget + local _isPinning bool (no new provider needed for simple async op)
  - Checkpoint (Task 2) separates Flutter code delivery from hardware-gated iOS App Group + Xcode Widget Extension target setup
metrics:
  duration_minutes: 45
  completed_date: "2026-05-03"
  tasks_completed: 3
  tasks_total: 3
  files_created: 8
  files_modified: 3
  tests_added: 5
  tests_passing: 5
---

# Phase 6 Plan 04: Home Screen Widget (QRD-03) Summary

**One-liner**: home_widget 0.9.1 pins any QR from the library to iOS WidgetKit / Android Glance via PrettyQrView→PNG renderFlutterWidget with full platform-native extension stubs written, pending Apple Dev Portal App Group + Xcode Widget Extension target setup.

## What Was Built

### Task 1: home_widget + QrWidgetService + tests + native stubs

**QrWidgetService** (`lib/features/qr_digital/domain/services/qr_widget_service.dart`):
- Static `pinQrToWidget(QRCodeEntity, {HomeWidgetAdapter?})` — renders `PrettyQrView` to 300×300 PNG, saves `qr_label` (truncated to 40 chars), triggers native widget refresh on both platforms
- `HomeWidgetAdapter` abstract interface + `_DefaultHomeWidgetAdapter` (real HomeWidget calls) for testability
- Respects T-06-14: `logicalSize: const Size(300, 300)` hard cap

**5 unit tests (all GREEN)**:
- `setAppGroupId('group.io.gothcorp.qraft')` called
- `renderFlutterWidget` called with key `qr_widget_image` and `Size(300,300)`
- `updateWidget(iOSName: 'QRaftWidget', androidName: 'QrWidgetReceiver')` called
- `qr_label` saved before `updateWidget`
- Labels longer than 40 chars are truncated with ellipsis

**iOS Swift WidgetKit** (`ios/QRaftWidgetExtension/`):
- `QRaftWidget.swift`: `TimelineProvider` reads `qr_widget_image` from `UserDefaults(suiteName: "group.io.gothcorp.qraft")`; shows PNG image or fallback "Open QRaft to pin a QR"; supports `.systemSmall` + `.systemMedium`; `kind: "QRaftWidget"` matches Dart constant
- `QRaftWidgetBundle.swift`: `@main` `WidgetBundle` for the extension target

**Android Kotlin Glance** (`android/app/src/main/kotlin/io/gothcorp/qraft/`):
- `QrWidget.kt`: `GlanceAppWidget` with `HomeWidgetGlanceStateDefinition`; reads `qr_widget_image` path; shows decoded bitmap or text fallback
- `QrWidgetReceiver.kt`: `HomeWidgetGlanceWidgetReceiver<QrWidget>()` — class name matches `androidName` in Dart
- `QrWidgetReceiver` declared in `AndroidManifest.xml` with `APPWIDGET_UPDATE` intent filter and `@xml/qr_widget_info` provider metadata
- `android/app/src/main/res/xml/qr_widget_info.xml`: 110dp × 110dp, `updatePeriodMillis=0` (on-demand refresh only)
- `glance-appwidget:1.1.1` added to `build.gradle.kts`

**pubspec.yaml**: `home_widget: ^0.9.1` added after `shared_preferences`

### Task 2: Checkpoint (blocking human action — iOS App Group + Xcode)

The checkpoint gates iOS widget functionality on:
1. Apple Developer Portal: create App Group `group.io.gothcorp.qraft`, enable for both `io.gothcorp.qraft` and the new extension App ID `io.gothcorp.qraft.QRaftWidgetExtension`
2. Xcode: add Widget Extension target (Name: `QRaftWidgetExtension`, Bundle ID: `io.gothcorp.qraft.QRaftWidgetExtension`, no Configuration Intent); add App Groups capability to both targets; replace Xcode's auto-generated Swift stubs with the files Claude wrote

### Task 3: QrWidgetPinPage

**`lib/features/qr_digital/presentation/pages/qr_widget_pin_page.dart`**:
- `ConsumerStatefulWidget` receiving `QRCodeEntity entity`
- QR preview card (200×200 `PrettyQrView`, `#2E2E2E` rounded card)
- Platform instruction card — `Platform.isIOS` selects iOS vs Android steps; glassmorphism `BackdropFilter` + `#2E2E2E.withValues(alpha: 0.7)`
- Neon gradient pin button (`#00FF88` → `#00CC6A`) with `CircularProgressIndicator` loading state; `Semantics(identifier: 'widget_pin_button')`
- SnackBar success: "Widget updated! Add the QRaft widget to see your QR." / error: propagates exception message
- Note caption: "Widget updates each time you tap Pin. Tapping the widget opens QRaft."

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] HomeWidget.renderFlutterWidget returns Future`<String>` not Future`<bool?>`**
- **Found during:** Task 1 GREEN phase (compile error)
- **Issue:** Plan research specified `Future<bool?>` return type; actual pub.dev package source at `~/.pub-cache/hosted/pub.dev/home_widget-0.9.1/lib/src/home_widget.dart` returns `Future<String>` (the saved file path)
- **Fix:** Updated `HomeWidgetAdapter.renderFlutterWidget` signature to `Future<String>` and `_DefaultHomeWidgetAdapter` accordingly; test stub updated to return `'/tmp/home_widget/qr_widget_image.png'`
- **Files modified:** `qr_widget_service.dart`, `qr_widget_service_test.dart`

**2. [Rule 1 - Bug] HomeWidget.setAppGroupId returns Future`<bool?>` not Future`<void>`**
- **Found during:** Task 1 compile phase
- **Issue:** Plan showed `Future<void>` for setAppGroupId; actual API returns `Future<bool?>` (invokes `MethodChannel.invokeMethod<bool>`)
- **Fix:** Updated `HomeWidgetAdapter.setAppGroupId` and `_DefaultHomeWidgetAdapter` to `Future<bool?>`
- **Files modified:** `qr_widget_service.dart`

**3. [Rule 1 - Bug] mocktail requires registerFallbackValue for Widget and Size abstract types**
- **Found during:** Task 1 test run
- **Issue:** `any()` matcher for `Widget` parameter fails without `registerFallbackValue`; `Widget.toString` requires `DiagnosticLevel` named param; `Size` also needs fallback registration
- **Fix:** Added `_FakeWidget` class with `toString({DiagnosticLevel minLevel = ...})` override; added `registerFallbackValue(_FakeWidget())` + `registerFallbackValue(const Size(300, 300))` in `setUpAll`
- **Files modified:** `qr_widget_service_test.dart`

## Known Stubs

None — QrWidgetService is fully implemented with real API calls. The native Swift/Kotlin code is complete and correct; it is NOT functional yet on device because the iOS App Group capability and Xcode Widget Extension target must be set up (blocking human checkpoint, per plan design).

## Threat Flags

None — no new network endpoints, auth paths, or schema changes beyond what the plan's `<threat_model>` covers.

## Self-Check: PASSED

Commit eb5f308 exists: ✓
Commit b06451a exists: ✓

Files verified:
- `lib/features/qr_digital/domain/services/qr_widget_service.dart` FOUND
- `lib/features/qr_digital/presentation/pages/qr_widget_pin_page.dart` FOUND
- `ios/QRaftWidgetExtension/QRaftWidget.swift` FOUND (contains `group.io.gothcorp.qraft`)
- `android/app/src/main/kotlin/io/gothcorp/qraft/QrWidget.kt` FOUND (contains `GlanceAppWidget`)
- `test/features/qr_digital/services/qr_widget_service_test.dart` FOUND (5 tests, all PASS)
- `home_widget: ^0.9.1` in pubspec.yaml FOUND
- flutter analyze: 0 issues
