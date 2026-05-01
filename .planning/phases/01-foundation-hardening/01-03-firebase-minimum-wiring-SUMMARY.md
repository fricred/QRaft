---
phase: 01-foundation-hardening
plan: 03
subsystem: infra
tags: [firebase, firebase_core, gradle-plugin, cocoapods, ios-deployment-target, native-config, bootstrap]

# Dependency graph
requires:
  - phase: 01-foundation-hardening
    provides: "stable pub baseline (firebase_core ^4.7.0 dry-run path validated by plan 01-01)"
provides:
  - "firebase_core ^4.7.0 declared in pubspec; pubspec.lock resolves to 4.7.0 exactly"
  - "google-services.json + GoogleService-Info.plist committed for project qraft-e8a1d (D-02)"
  - "Android google-services Gradle plugin applied at app + project level (modern plugins{} apply false style)"
  - "iOS Podfile + Xcode project bumped from iOS 13.0 → 15.0 (firebase_core 4.7.0 hard requirement)"
  - "lib/firebase_options.dart hand-authored with FlutterFire-CLI-equivalent shape for android+ios"
  - "lib/main.dart calls Firebase.initializeApp() between Supabase and AdMob (PATTERNS.md ordering)"
  - "Both platforms build clean: flutter build apk --debug + flutter build ios --debug --no-codesign"
  - "D-01 boundary preserved: zero FCM/Crashlytics/Analytics imports in lib/"
affects:
  - "01-04-milestone-packages-install (firebase_messaging/crashlytics/analytics will install on top of this firebase_core foundation)"
  - "01-05-ump-consent-and-admob-gating (UMP gate moves AdMob init out of initializeApp; Firebase init stays where it is)"
  - "01-07-phase-verification (analyzer baseline 0 issues preserved; iOS 15+ floor noted for final verification)"
  - "Phase 10 — MKT-09 FCM (this plan establishes the Firebase entry point those services need)"
  - "Phase 12 — OPT-03 Crashlytics+Analytics (same as above)"

# Tech tracking
tech-stack:
  added: ["firebase_core ^4.7.0"]
  patterns:
    - "Hand-authored firebase_options.dart matching FlutterFire CLI output shape so future CLI re-runs produce a clean diff (skip CLI install per orchestrator instruction; preserve compatibility for re-generation later)"
    - "Modern Gradle plugins{} apply-false pattern in project-level build.gradle.kts (vs legacy buildscript{} classpath) — google-services 4.4.2"

key-files:
  created:
    - "lib/firebase_options.dart"
    - "android/app/google-services.json"
    - "ios/Runner/GoogleService-Info.plist"
  modified:
    - "android/app/build.gradle.kts"
    - "android/build.gradle.kts"
    - "ios/Podfile"
    - "ios/Podfile.lock"
    - "ios/Runner.xcodeproj/project.pbxproj"
    - "lib/main.dart"
    - "lib/l10n/app_localizations.dart (incidental Flutter-tool reformat during build)"

key-decisions:
  - "Bumped iOS deployment target 13.0 → 15.0 (Podfile + Xcode project) because firebase_core 4.7.0 podspec requires ios.deployment_target = 15.0. Mobile_scanner 7.x requires only iOS 13+, so 15+ is strictly compatible. Rule 3 deviation documented below."
  - "Hand-authored lib/firebase_options.dart instead of running `flutterfire configure` (per orchestrator instruction skip CLI install). Output shape matches FlutterFire CLI exactly so future regeneration is a clean diff."
  - "Modern Gradle plugins{} apply-false style chosen over legacy buildscript{} classpath in project-level build.gradle.kts (file had no buildscript{} block, only allprojects{} — modern style is the natural extension)."
  - "Kept AdMob init inside initializeApp() — UMP gating extraction is plan 01-05's job. This plan only inserts Firebase between Supabase and AdMob (single responsibility)."

patterns-established:
  - "Native config commit policy: google-services.json + GoogleService-Info.plist committed (NOT gitignored) — they contain only public client IDs, no secrets. Future Firebase project rotations must re-download both files."
  - "iOS deployment target = max of all dependency floors. Firebase Flutter 4.x bumps the floor to 15.0; downstream phases adding Firebase services must NOT regress this floor."

requirements-completed: []  # this plan is purely infra/foundation; no v1 requirements close here

# Metrics
duration: ~28m
completed: 2026-05-01
---

# Phase 1 Plan 03: Firebase Minimum Wiring Summary

**firebase_core 4.7.0 wired end-to-end on Android + iOS with `Firebase.initializeApp()` between Supabase and AdMob; iOS deployment target bumped 13.0 → 15.0 to satisfy firebase_core 4.7.0 podspec; D-01 service-activation boundary preserved (zero FCM/Crashlytics/Analytics imports).**

## Performance

- **Duration:** ~28 min (continuation segment, after the user-action checkpoint)
- **Started (this segment):** 2026-05-01T22:02:00Z (approx — orchestrator resume point)
- **Completed:** 2026-05-01T22:30:28Z
- **Tasks:** 5 (Task 1 closed in prior segment, Tasks 2–5 closed here)
- **Files modified:** 9 (3 created, 6 modified — see key-files)

## Accomplishments

- `firebase_core ^4.7.0` declared and locked at exactly 4.7.0 (pubspec.lock sha256 `d5a94b88…`).
- google-services.json (`qraft-e8a1d` / `io.gothcorp.qraft`) and GoogleService-Info.plist (`qraft-e8a1d` / `io.gothcorp.qraft`) committed at canonical paths.
- Android `id("com.google.gms.google-services")` plugin applied in app-level `build.gradle.kts`; project-level `build.gradle.kts` declares `id("com.google.gms.google-services") version "4.4.2" apply false`.
- iOS Podfile `platform :ios, '13.0'` → `'15.0'`; Xcode project `IPHONEOS_DEPLOYMENT_TARGET 13.0 → 15.0` in all 3 build configs (Debug/Profile/Release).
- `pod install` resolved 25 pods including Firebase 12.12.0, FirebaseCore 12.12.1, firebase_core 4.7.0 (Podfile.lock contains "Firebase" 12 times).
- `lib/firebase_options.dart` hand-authored with FlutterFire-CLI-equivalent shape (android + ios concrete options; web/macos/windows/linux throw `UnsupportedError`).
- `lib/main.dart` imports `firebase_core` + `firebase_options.dart`; `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` runs between `SupabaseService.initialize()` (line 33) and `MobileAds.instance.initialize()` (line 43).
- D-01 boundary verified: `grep -rE 'FirebaseMessaging|FirebaseCrashlytics|FirebaseAnalytics' lib/` returns zero matches.
- Analyzer baseline preserved: `flutter analyze --no-fatal-warnings` → "No issues found! (ran in 5.0s)".
- Both platform builds succeed: `flutter build apk --debug` → "Built build/app/outputs/flutter-apk/app-debug.apk"; `flutter build ios --debug --no-codesign` → "Built build/ios/iphoneos/Runner.app".

## Task Commits

Each task was committed atomically on `feature/adds` (no `--no-verify`, hooks active):

1. **Task 1: Add firebase_core to pubspec** — `5da00cc` (feat) — closed in prior session
2. **Task 2: Commit Firebase config files** — `bff89cb` (chore) — google-services.json + GoogleService-Info.plist
3. **Task 3: Apply google-services Gradle plugin + bump iOS deployment target** — `82b09ba` (feat)
4. **Task 4: Hand-author lib/firebase_options.dart** — `4d0e9d8` (feat)
5. **Task 5: Wire Firebase.initializeApp into main bootstrap** — `e46e506` (feat)

**Plan metadata commit:** to follow this SUMMARY.

## Files Created/Modified

- `pubspec.yaml` — `firebase_core: ^4.7.0` under new `# Firebase` section (Task 1, prior session)
- `pubspec.lock` — firebase_core 4.7.0 + transitive `firebase_core_platform_interface` 6.0.3 (Task 1, prior session)
- `android/app/google-services.json` — created, vendor-issued config for project `qraft-e8a1d` (Task 2)
- `ios/Runner/GoogleService-Info.plist` — created, vendor-issued config for project `qraft-e8a1d` (Task 2)
- `android/app/build.gradle.kts` — appended `id("com.google.gms.google-services")` to plugins block (Task 3)
- `android/build.gradle.kts` — added `plugins {}` block declaring `com.google.gms.google-services 4.4.2 apply false` (Task 3)
- `ios/Podfile` — `platform :ios, '13.0'` → `'15.0'` with explanatory comment (Task 3)
- `ios/Podfile.lock` — auto-regenerated; 25 pods total, 12 Firebase-* entries (Task 3)
- `ios/Runner.xcodeproj/project.pbxproj` — `IPHONEOS_DEPLOYMENT_TARGET = 13.0` → `15.0` (3 occurrences, Task 3)
- `lib/firebase_options.dart` — created, FlutterFire-CLI-equivalent shape (Task 4)
- `lib/main.dart` — added 2 imports + `Firebase.initializeApp` block (Task 5)
- `lib/l10n/app_localizations.dart` — incidental Flutter-tool reformat during Task 3 build (whitespace only; included in Task 3 commit since the rebuild caused it)

## Decisions Made

- **iOS deployment target 13.0 → 15.0** (Rule 3 deviation, see below). Forced by firebase_core 4.7.0 podspec; mobile_scanner 7.x is satisfied with 15.0 (its floor is 13). Downstream phases adding more Firebase services MUST NOT regress this floor.
- **Hand-authored firebase_options.dart shape matches FlutterFire CLI output exactly** so any future `flutterfire configure` run produces a clean diff (no noise on values that haven't changed). Includes the `// ignore_for_file: type=lint` directive the CLI emits, the same `kIsWeb` early throw, the same `defaultTargetPlatform` switch, and the same `iosClientId` + `iosBundleId` fields on the iOS block.
- **Modern Gradle plugins{} apply-false** chosen over legacy `buildscript{} { dependencies { classpath(...) } }`. The project-level `android/build.gradle.kts` had no buildscript block at all (only `allprojects { repositories {} }`), so modern style is the natural minimal-diff extension. AGP supports both styles for the google-services plugin.
- **AdMob init stays inside initializeApp().** Plan 01-05 will extract it for UMP gating. Plan 01-03's single responsibility is to insert Firebase between Supabase and AdMob — extracting AdMob would conflate two plans' concerns.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bumped iOS deployment target 13.0 → 15.0**

- **Found during:** Task 3 (`pod install --repo-update`)
- **Issue:** First `pod install` failed with `[!] CocoaPods could not find compatible versions for pod "firebase_core" … they required a higher minimum deployment target.` Inspecting `firebase_core 4.7.0/ios/firebase_core.podspec` confirmed `s.ios.deployment_target = '15.0'`. The Podfile was pinned at `platform :ios, '13.0'` (set in earlier work for mobile_scanner 7.x).
- **Fix:** Bumped `ios/Podfile` to `platform :ios, '15.0'` with an explanatory comment, and bumped `IPHONEOS_DEPLOYMENT_TARGET = 13.0` → `15.0` in all 3 build configurations of `ios/Runner.xcodeproj/project.pbxproj` (Debug/Profile/Release).
- **Why this is Rule 3, not Rule 4 (escalate):** The plan's stated success criteria require both `flutter build apk --debug` and `flutter build ios --debug --no-codesign` to succeed. Without bumping the iOS floor, iOS would not even pod-install, let alone build. The bump is a mechanical floor-raise, not an architectural change — mobile_scanner 7.x already required iOS 13, so the baseline was within shouting distance, and 15.0 is a current Apple-supported floor (iOS 15 released Sept 2021; >99% device coverage in 2026 per official Apple stats). No alternate dependency path exists: firebase_core 4.7.0 is the planner-pinned version (D-01 baseline for plan 01-04 milestone packages).
- **Files modified:** `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`
- **Verification:** Second `pod install` succeeded ("Pod installation complete! 25 pods"); `flutter build ios --debug --no-codesign` succeeded ("Xcode build done. 43.2s").
- **Committed in:** `82b09ba` (Task 3 commit)

**2. [Rule 3 - Blocking] Hand-authored firebase_options.dart instead of FlutterFire CLI**

- **Found during:** Task 4 (per orchestrator instruction)
- **Issue:** The plan as authored expected `flutterfire configure` to generate the file. The orchestrator continuation instruction explicitly directed: "Hand-author `lib/firebase_options.dart` from the values in google-services.json + GoogleService-Info.plist. Skip installing FlutterFire CLI / Firebase CLI." Reasoning: avoid pulling a dart-pub-global tool into the developer environment for a one-shot transcription task.
- **Fix:** Hand-wrote the file matching the FlutterFire CLI's exact output shape: `import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;`, `kIsWeb` early throw, `defaultTargetPlatform` switch, concrete `android` + `ios` `FirebaseOptions` constants populated from the two config files, `UnsupportedError` for web/macos/windows/linux.
- **Why this is Rule 3, not Rule 1/4:** The orchestrator explicitly authorized this deviation in the continuation prompt's `<important>` block. Hand-authoring is an alternate execution path for the same goal (file with `DefaultFirebaseOptions.currentPlatform` exposing android+ios). Future `flutterfire configure` runs will produce a clean diff because the shape matches.
- **Files modified:** `lib/firebase_options.dart` (created)
- **Verification:** All Task 4 acceptance criteria pass: file exists, contains `class DefaultFirebaseOptions`, contains `qraft-e8a1d` (5 matches), contains both `TargetPlatform.android` and `TargetPlatform.iOS`, `flutter analyze` on the file returns "No issues found!".
- **Committed in:** `4d0e9d8` (Task 4 commit)

**3. [Out-of-scope, included] Incidental reformat of `lib/l10n/app_localizations.dart`**

- **Found during:** Task 3 (after `flutter build apk --debug`)
- **Issue:** `flutter build apk` regenerated `lib/l10n/app_localizations.dart` with whitespace-only changes (e.g., colon indentation in initializer list). This file is auto-generated from `.arb` sources; the reformat is from a newer Flutter SDK version touching the file during build.
- **Fix:** Included in the Task 3 commit since the build that generated it was run as part of Task 3's verification gate. Not a substantive change.
- **Why not deferred:** Leaving the file dirty would have polluted Task 4's working tree. The change is mechanical and trivially reversible by a clean re-run of `flutter gen-l10n`.
- **Files modified:** `lib/l10n/app_localizations.dart` (whitespace only)
- **Committed in:** `82b09ba` (Task 3 commit)

---

**Total deviations:** 3 (2 Rule 3 blocking, 1 incidental scope-adjacent file)
**Impact on plan:** Zero scope creep. Both Rule 3 deviations were essential to satisfy the plan's own success criteria (iOS build success). The incidental l10n reformat is a Flutter-tool side effect and not a meaningful change. The hand-authored firebase_options.dart was orchestrator-authorized.

## Issues Encountered

- **Initial pod install rejected firebase_core 4.7.0 due to iOS floor mismatch** — resolved via Rule 3 deviation #1 above.
- **CocoaPods CDN intermittent HTTP/2 framing error during `pod install --repo-update`** — resolved by retrying without `--repo-update` (the local CDN cache was current). Documented for future executors: prefer `pod install` over `pod install --repo-update` when repo state is known good.
- **CocoaPods warning** about `Pods-Runner.profile.xcconfig` base configuration — pre-existing (unrelated to Firebase), no impact on builds. Documented in deferred items below.

## User Setup Required

None — both Firebase config files were placed by the developer during the human-action checkpoint (resolved before this segment resumed). No additional environment variables, dashboard configuration, or external service activation needed in plan 01-03 (D-01 boundary explicit on this).

## Next Phase Readiness

- **Plan 01-04 (milestone packages install):** ✅ Ready. firebase_messaging 16.x / firebase_crashlytics 5.x / firebase_analytics 12.x all declare `firebase_core: ^4.7.0` as their constraint — they will resolve cleanly on top of this baseline (verified via pub.dev API 2026-05-01 in plan-author notes).
- **Plan 01-05 (UMP consent + AdMob gating):** ✅ Ready. The AdMob init line that plan 01-05 will extract is at `lib/main.dart:43` (post-Firebase, pre-runApp) — straightforward to lift out behind the UMP gate.
- **Plan 01-06 (forgot password controller refactor):** ✅ Independent of this plan. No interactions.
- **Plan 01-07 (phase verification):** Note that the analyzer baseline is **still 0 issues** — this plan introduced zero analyzer warnings. iOS deployment target now 15.0 (was 13.0); plan 01-07 should record this in the final phase verification.
- **Phase 10 (FCM)** and **Phase 12 (Crashlytics + Analytics)** can layer on top of `Firebase.initializeApp()` without re-doing native config. Both phases inherit the iOS 15.0 floor.

### Deferred items

- The CocoaPods warning about `Pods-Runner.profile.xcconfig` base configuration is pre-existing and not introduced by this plan. Logged here for plan 01-07 verifier to confirm whether to suppress or fix in a follow-up plan.
- Carry-over from plan 01-01: `01-PATTERNS.md:498` snippet still says `sdk: ^3.29.0` (incorrect). Not touched by this plan (out of scope). Stays in the deferred queue for plan 01-07 or a one-line doc fix.

## TDD Gate Compliance

N/A — plan declared `tdd="false"` on all 5 tasks (config + bootstrap changes only). No test gates required. Service-activation tests (FCM/Crashlytics/Analytics) are deliberately deferred per D-01.

## Self-Check: PASSED

**Commits exist (verified via `git log --oneline -7`):**

```
e46e506 feat(01-03): wire Firebase.initializeApp into main bootstrap before AdMob
4d0e9d8 feat(01-03): hand-author lib/firebase_options.dart for project qraft-e8a1d
82b09ba feat(01-03): apply google-services Gradle plugin and bump iOS deployment target
bff89cb chore(01-03): add Firebase config files for project qraft-e8a1d
5da00cc feat(01-03): add firebase_core ^4.7.0 dependency
ff9b454 docs(01-02): complete Maestro foundation scaffolding plan
8849773 feat(01-02): add Maestro helper flow scaffolds (dismiss-permissions + login)
```

**Files created/modified exist:**

- `lib/firebase_options.dart` — present, contains `DefaultFirebaseOptions`, `qraft-e8a1d`, both target platforms.
- `android/app/google-services.json` — present, contains `"project_id": "qraft-e8a1d"` and `"package_name": "io.gothcorp.qraft"`.
- `ios/Runner/GoogleService-Info.plist` — present, contains `<string>io.gothcorp.qraft</string>` and `<string>qraft-e8a1d</string>`.
- `android/app/build.gradle.kts` — `id("com.google.gms.google-services")` in plugins block.
- `android/build.gradle.kts` — `id("com.google.gms.google-services") version "4.4.2" apply false`.
- `ios/Podfile` — `platform :ios, '15.0'`.
- `ios/Podfile.lock` — 12 lines containing `Firebase`.
- `lib/main.dart` — Firebase imports present, `Firebase.initializeApp` between Supabase (line 33) and AdMob (line 43).

**Acceptance criteria mapping:**

| Plan acceptance criterion | Status |
|---|---|
| `grep -E '^\s*firebase_core:\s*\^4\.7\.' pubspec.yaml` matches | ✅ Pass |
| `pubspec.lock` shows `firebase_core: version: "4.7.0"` | ✅ Pass |
| `flutter pub get` exits 0 | ✅ Pass (Task 1, prior session) |
| `flutter analyze --no-fatal-warnings` exits 0 (baseline preserved) | ✅ Pass (0 issues) |
| `android/app/google-services.json` exists with `qraft-e8a1d` | ✅ Pass |
| `ios/Runner/GoogleService-Info.plist` exists with `io.gothcorp.qraft` | ✅ Pass |
| `android/app/build.gradle.kts` plugins block has `id("com.google.gms.google-services")` | ✅ Pass |
| `android/build.gradle.kts` declares classpath/plugin | ✅ Pass (modern plugins{} apply false) |
| `ios/Podfile` `platform :ios, '13.x'` | ⚠️ Adjusted via Rule 3 deviation: now `'15.0'` (firebase_core 4.7.0 podspec requires 15+) |
| `ios/Podfile.lock` contains `Firebase` | ✅ Pass (12 matches) |
| `lib/firebase_options.dart` contains `class DefaultFirebaseOptions` | ✅ Pass |
| `lib/firebase_options.dart` contains `qraft-e8a1d` (>= 2) | ✅ Pass (5 matches) |
| `lib/firebase_options.dart` contains `TargetPlatform.android` and `TargetPlatform.iOS` | ✅ Pass (1 each) |
| `lib/main.dart` imports `firebase_core` and `firebase_options.dart` | ✅ Pass (1 each) |
| `lib/main.dart` calls `Firebase.initializeApp` once | ✅ Pass (1 match) |
| `Firebase.initializeApp` line is AFTER `SupabaseService.initialize` and BEFORE `MobileAds.instance.initialize` | ✅ Pass (33 < 37 < 43) |
| `flutter build apk --debug` exits 0 | ✅ Pass |
| `flutter build ios --debug --no-codesign` exits 0 | ✅ Pass |
| `grep -rE 'FirebaseMessaging\|FirebaseCrashlytics\|FirebaseAnalytics' lib/` returns no matches | ✅ Pass (D-01 boundary) |

The single ⚠️ row is a documented Rule 3 deviation that strictly raises (not lowers) the iOS floor and is necessary for the plan's iOS-build success criterion. Intent (`platform :ios, 'X'` with X >= mobile_scanner floor) is fully preserved.

---

*Phase: 01-foundation-hardening*
*Completed: 2026-05-01*
