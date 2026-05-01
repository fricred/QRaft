---
phase: 01-foundation-hardening
plan: 04
subsystem: infra
tags: [pubspec, dependencies, firebase, pretty_qr_code, screenshot, csv, image, flutter_form_builder, form_builder_validators, flutter_local_notifications, core-library-desugaring, android-gradle, cocoapods]

# Dependency graph
requires:
  - phase: 01-foundation-hardening
    provides: "firebase_core ^4.7.0 baseline pinned by plan 03 (cohort that aligns with firebase_messaging 16.x / firebase_crashlytics 5.x / firebase_analytics 12.x)"
  - phase: 01-foundation-hardening
    provides: "Flutter SDK ^3.7.0 + flutter >=3.29.0 + iOS deployment target 15.0 (plans 01-01 + 01-03)"
provides:
  - "10 milestone packages declared in pubspec.yaml under labeled section comments (D-01)"
  - "firebase_messaging ^16.2.0, firebase_crashlytics ^5.2.0, firebase_analytics ^12.3.0 share firebase_core ^4.7.0 cohort — clean pub get"
  - "pretty_qr_code ^3.6.0, screenshot ^3.0.0, image ^4.5.4, csv ^8.0.0 under # Advanced QR Generation"
  - "flutter_form_builder ^10.3.0, form_builder_validators ^11.1.2 under # Forms"
  - "flutter_local_notifications ^17.2.4 under # Notifications"
  - "Android core library desugaring enabled (isCoreLibraryDesugaringEnabled = true + desugar_jdk_libs 2.1.4) — required by flutter_local_notifications 17.x"
  - "iOS Podfile.lock regenerated with FirebaseMessaging, FirebaseCrashlytics, FirebaseAnalytics pods (42 pods total)"
  - "macOS GeneratedPluginRegistrant.swift auto-regenerated to register Firebase + flutter_local_notifications plugins"
  - "D-01 boundary preserved: zero FCM/Crashlytics/Analytics/UMP imports in lib/ — packages are available but unused"
  - "ROADMAP success criterion #5 satisfied"
affects:
  - "01-05-ump-consent-and-admob-gating (will import ConsentInformation/ConsentForm from already-installed google_mobile_ads ^5.1.0 — no separate UMP package needed)"
  - "01-07-phase-verification (analyzer baseline 0 issues preserved; iOS 15+ floor preserved; Android core library desugaring noted)"
  - "Phase 5 — QR-02..06 (pretty_qr_code, screenshot, image for advanced visual customization + export)"
  - "Phase 7 — MKT-* (csv for catalog ingest)"
  - "Phase 9 — MKT-04 checkout (flutter_form_builder + form_builder_validators)"
  - "Phase 10 — MKT-09 (firebase_messaging + flutter_local_notifications activation)"
  - "Phase 12 — OPT-03 (firebase_crashlytics + firebase_analytics activation)"

# Tech tracking
tech-stack:
  added:
    - "firebase_messaging ^16.2.0"
    - "firebase_crashlytics ^5.2.0"
    - "firebase_analytics ^12.3.0"
    - "pretty_qr_code ^3.6.0"
    - "screenshot ^3.0.0"
    - "image ^4.5.4"
    - "csv ^8.0.0"
    - "flutter_form_builder ^10.3.0"
    - "form_builder_validators ^11.1.2"
    - "flutter_local_notifications ^17.2.4"
    - "desugar_jdk_libs 2.1.4 (Android core library desugaring runtime)"
  patterns:
    - "pubspec.yaml dep grouping by purpose: # Firebase, # Advanced QR Generation, # Forms, # Notifications — section comments precede grouped entries (extends plan 01-PATTERNS pattern)"
    - "Firebase service trio (messaging/crashlytics/analytics) pinned to versions that all declare firebase_core ^4.7.0 — verified via pub.dev API 2026-05-01 — keeps the Firebase cohort in lockstep"
    - "UMP gating uses google_mobile_ads ^5.1.0 (already in pubspec) for ConsentInformation/ConsentForm — no separate user_messaging_platform package (discontinued third-party) and no nonexistent google_user_messaging_platform — modern Google-recommended path per https://developers.google.com/admob/flutter/privacy"
    - "Android core library desugaring pattern: isCoreLibraryDesugaringEnabled = true in compileOptions + coreLibraryDesugaring(\"com.android.tools:desugar_jdk_libs:2.1.4\") in dependencies block — established for flutter_local_notifications 17.x; future packages requiring desugaring inherit this floor"

key-files:
  created: []
  modified:
    - "pubspec.yaml"
    - "pubspec.lock"
    - "ios/Podfile.lock"
    - "android/app/build.gradle.kts"
    - "macos/Flutter/GeneratedPluginRegistrant.swift"

key-decisions:
  - "Pinned firebase_messaging 16.2.0 / firebase_crashlytics 5.2.0 / firebase_analytics 12.3.0 — verified each declares firebase_core ^4.7.0, preserving plan 03's pin without bump"
  - "Did NOT install user_messaging_platform (discontinued) or google_user_messaging_platform (does not exist on pub.dev). Modern UMP API ships INSIDE google_mobile_ads ^5.1.0; plan 05 imports ConsentInformation/ConsentForm from there"
  - "Enabled Android core library desugaring (Rule 3 deviation, see below) — required by flutter_local_notifications 17.x; mechanical Gradle change, parallel in spirit to plan 03's iOS deployment-target bump"
  - "Included macos/Flutter/GeneratedPluginRegistrant.swift auto-regen in commit — Flutter tooling regenerates it on pub get to register new plugins for the macOS embedder; mechanical plumbing, NOT Dart wiring (D-01 boundary still passes since lib/ has zero imports of the new packages)"

patterns-established:
  - "Android core library desugaring: when a Flutter dep requires Java 8 desugaring (e.g., flutter_local_notifications 17.x, future stdlib-using packages), enable in android/app/build.gradle.kts compileOptions + add desugar_jdk_libs 2.1.4 to dependencies block. AGP 8+ supports this with the modern plugins{} model used by this project."
  - "Auto-regenerated platform registrant files (macos/Flutter/GeneratedPluginRegistrant.swift, ios equivalent if present) commit alongside the dep install that triggered them — they are inseparable from the install and would otherwise produce a dirty working tree on every clone-then-pub-get."

requirements-completed: []  # plan 01-04 has no v1 requirements (purely milestone-package install per D-01)

# Metrics
duration: 20m
completed: 2026-05-01
---

# Phase 1 Plan 04: Milestone Packages Install Summary

**10 milestone packages installed in pubspec.yaml under purpose-labeled sections (Firebase trio + advanced QR + forms + notifications); firebase_core stays pinned at 4.7.0; D-01 boundary preserved with zero Dart wiring; both platform debug builds succeed.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-01T22:36:03Z
- **Completed:** 2026-05-01T22:56:48Z
- **Tasks:** 1 (single-task plan per the PLAN.md task list)
- **Files modified:** 5 (pubspec.yaml, pubspec.lock, ios/Podfile.lock, android/app/build.gradle.kts, macos/Flutter/GeneratedPluginRegistrant.swift)

## Accomplishments

- All 10 milestone packages declared in `pubspec.yaml` under labeled section comments (`# Firebase`, `# Advanced QR Generation`, `# Forms`, `# Notifications`).
- `flutter pub get` resolved cleanly with `Changed 20 dependencies` (10 direct + 10 transitive); zero version conflicts.
- `firebase_core` stayed pinned at `4.7.0` exactly (no bump from plan 03's pin) — verified the Firebase service trio cohort assumption from the plan author's pub.dev API audit.
- `pod install` succeeded (after the documented `--repo-update` CDN HTTP/2 retry workaround from plan 03 deferred items): 42 pods total, including FirebaseAnalytics 12.12.0, FirebaseCrashlytics 12.12.1, FirebaseMessaging 12.12.0.
- Android `flutter build apk --debug` succeeded after enabling core library desugaring (Rule 3 deviation, see below).
- iOS `flutter build ios --debug --no-codesign` succeeded.
- Analyzer baseline preserved: `flutter analyze --no-fatal-warnings` → "No issues found! (ran in 5.1s)" — same as plan 03 baseline.
- D-01 boundary verified: `grep -rE 'FirebaseMessaging|FirebaseCrashlytics|FirebaseAnalytics|ConsentInformation|ConsentForm' lib/` returns zero matches.
- No standalone UMP package installed (modern UMP API ships in `google_mobile_ads ^5.1.0` already at pubspec line 100).

## Resolved Versions (pubspec.lock)

| Package                          | Resolved   |
| -------------------------------- | ---------- |
| `firebase_core`                  | 4.7.0      |
| `firebase_messaging`             | 16.2.0     |
| `firebase_crashlytics`           | 5.2.0     |
| `firebase_analytics`             | 12.3.0     |
| `pretty_qr_code`                 | 3.6.0      |
| `screenshot`                     | 3.0.0      |
| `image`                          | 4.5.4      |
| `csv`                            | 8.0.0      |
| `flutter_form_builder`           | 10.3.0+2   |
| `form_builder_validators`        | 11.3.0     |
| `flutter_local_notifications`    | 17.2.4     |

`firebase_core: 4.7.0` — confirmed unchanged from plan 03 baseline. `form_builder_validators: 11.3.0` resolved one minor higher than the plan's `^11.1.2` constraint floor (consistent with the caret semantic — `^11.1.2` admits up to `<12.0.0`); this is expected behavior, not a deviation.

## iOS Podfile.lock excerpt

```
- FirebaseAnalytics (12.12.0)
- FirebaseCrashlytics (12.12.1)
- FirebaseMessaging (12.12.0)
- firebase_analytics (12.3.0)
- firebase_crashlytics (5.2.0)
- firebase_messaging (16.2.0)
- flutter_local_notifications (0.0.1)
```

42 pods total (was 25 after plan 03; net +17 pods covering Firebase services, GoogleAppMeasurement, FirebaseRemoteConfigInterop, FirebaseSessions, FirebaseCoreExtension, GoogleAdsOnDeviceConversion, GoogleUserMessagingPlatform native binary brought in by google_mobile_ads, plus flutter_local_notifications). `grep -c "FirebaseMessaging" ios/Podfile.lock` → 4; `grep -c "FirebaseCrashlytics"` → 4; `grep -c "FirebaseAnalytics"` → 6.

## Task Commits

Each task was committed atomically on `feature/adds` (no `--no-verify`, hooks active):

1. **Task 1: Add 10 milestone packages to pubspec.yaml under labeled sections** — `1990bb6` (feat)

**Plan metadata commit:** to follow this SUMMARY.

## Files Created/Modified

- `pubspec.yaml` — added 7 new dep entries to `# Firebase` section + 3 new sections (`# Advanced QR Generation`, `# Forms`, `# Notifications`) totaling 10 new packages.
- `pubspec.lock` — regenerated; 20 dependencies changed (10 direct + 10 transitive — firebase service common deps, image codecs, validator transitives, timezone for flutter_local_notifications).
- `ios/Podfile.lock` — regenerated by `pod install`; 42 pods total (was 25); +Firebase service pods + companion Google SDKs.
- `android/app/build.gradle.kts` — `compileOptions { isCoreLibraryDesugaringEnabled = true; ... }` + new `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }` block. Required by `flutter_local_notifications` 17.x (Rule 3 deviation, see below).
- `macos/Flutter/GeneratedPluginRegistrant.swift` — auto-regenerated by `flutter pub get` to register the 4 new platform-channel-using plugins (firebase_analytics, firebase_crashlytics, firebase_messaging, flutter_local_notifications) for the macOS embedder. Mechanical generated plumbing.

## Decisions Made

- **Android core library desugaring enabled** (Rule 3 deviation, see below). Forced by `flutter_local_notifications` 17.x build requirement. Pattern documented for future deps that need Java 8+ stdlib APIs on minSdk < 26.
- **`firebase_core` stays at 4.7.0 (no bump).** Plan author's pub.dev API audit (2026-05-01) was correct: firebase_messaging 16.2.0, firebase_crashlytics 5.2.0, firebase_analytics 12.3.0 all declare `firebase_core: ^4.7.0` as their constraint, so the trio resolves into the existing 4.7.0 cohort with no version negotiation needed.
- **No separate UMP package installed.** Verified the plan's external-docs claim by inspecting the existing `google_mobile_ads: ^5.1.0` entry (pubspec.yaml line 100, added before plan 03). Plan 05 will import `ConsentInformation` and `ConsentForm` directly from `google_mobile_ads`.
- **Used `pod install` (no `--repo-update`) after CDN HTTP/2 framing error.** Plan 03 SUMMARY's "Deferred items" section documented this exact workaround for intermittent CocoaPods CDN issues. Local CDN cache had the new Firebase service podspecs already (because they share the firebase_core 4.7.0 cohort that plan 03 already cached). No data integrity concern.
- **Included `macos/Flutter/GeneratedPluginRegistrant.swift` regeneration in the task commit.** Flutter tooling auto-regenerated this file the moment `flutter pub get` ran. Excluding it would leave a dirty working tree on every fresh clone-then-pub-get; including it commits the necessary plugin registration plumbing. The file does NOT count as Dart "wiring" — D-01 is about app code under `lib/` (where the boundary check passed), not platform embedder generated plumbing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Enabled Android core library desugaring for flutter_local_notifications 17.x**

- **Found during:** Task 1 (post-`flutter pub get`, during `flutter build apk --debug`)
- **Issue:** Android Gradle build failed with: `Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app. See https://developer.android.com/studio/write/java8-support.html for more details.` The `flutter_local_notifications` 17.x source uses Java 8 stdlib APIs (e.g., `java.time.*`) which require backport via core library desugaring on Android minSdk < 26 (this project's minSdk is `flutter.minSdkVersion`, currently 21).
- **Fix:**
  1. In `android/app/build.gradle.kts` `compileOptions {}` block, added `isCoreLibraryDesugaringEnabled = true` (with comment explaining why).
  2. Added new `dependencies {}` block at end of file declaring `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` (the runtime that implements the desugared stdlib calls).
  Both changes follow the official `flutter_local_notifications` README and the AGP 8+ canonical pattern. No Dart code changes; no version bumps to other packages; no `minSdk` changes.
- **Why this is Rule 3, not Rule 4 (escalate):** The plan's own success criteria #3 mandates "Both platform debug builds succeed." Without core library desugaring, the apk build is impossible. The fix is a 5-line mechanical Gradle config change with a well-documented official pattern — directly parallel to plan 03's iOS deployment-target bump (also Rule 3 there). No alternate dependency path: `flutter_local_notifications` 17.x is the planner-pinned version, and even older versions of the package require desugaring. This is not an architectural decision; it is a standard build-config requirement for Java 8 backport on older Android minSdk.
- **Files modified:** `android/app/build.gradle.kts`
- **Verification:** Second `flutter build apk --debug` succeeded (`Built build/app/outputs/flutter-apk/app-debug.apk` in 34.2s). 3 obsolete-options warnings emitted (`source/target value 8 is obsolete`) — these are from `flutter_local_notifications` itself, not introduced by this fix; harmless and not present in `flutter analyze` output.
- **Committed in:** `1990bb6` (Task 1 commit)

**2. [Out-of-scope, included] Auto-regen of `macos/Flutter/GeneratedPluginRegistrant.swift`**

- **Found during:** Task 1 (post-`flutter pub get`)
- **Issue:** `flutter pub get` regenerated the macOS plugin registrant to register 4 new platform-channel plugins (firebase_analytics, firebase_crashlytics, firebase_messaging, flutter_local_notifications) for the macOS embedder. The file was modified by Flutter tooling, not by manual edit.
- **Fix:** Included in the Task 1 commit since the regen is mechanically inseparable from the dep install that triggered it. Excluding would leave a dirty working tree on every fresh clone-then-pub-get and would not survive any subsequent Flutter tooling run.
- **Why not deferred:** The diff is purely additive registration plumbing for the macOS embedder. It does NOT count as Dart wiring under D-01: D-01 is about app code in `lib/` (zero imports of the new packages confirmed via boundary grep), not about platform embedder generated files. macOS is not a target platform in this phase, so the registrant has no runtime effect on Phase 1 scope; it just preserves a clean checkout.
- **Files modified:** `macos/Flutter/GeneratedPluginRegistrant.swift`
- **Committed in:** `1990bb6` (Task 1 commit)

---

**Total deviations:** 2 (1 Rule 3 blocking, 1 incidental scope-adjacent file)
**Impact on plan:** Zero scope creep. Rule 3 deviation #1 was strictly necessary to satisfy the plan's own success criterion #3 ("Both platform debug builds succeed"). Deviation #2 is a Flutter-tool side effect of the dep install itself; excluding it would create a worse outcome (dirty working tree on every clone).

## Issues Encountered

- **Initial Android `flutter build apk --debug` failed** due to missing core library desugaring — resolved via Rule 3 deviation #1 above.
- **CocoaPods CDN HTTP/2 framing error during `pod install --repo-update`** — exact same intermittent issue plan 03 documented in its "Deferred items" section. Resolved by retrying with `pod install` (no `--repo-update`) since the local CDN cache was current. The plan 03 deferred-items workaround is now confirmed reliable across two consecutive pod-install runs.
- **CocoaPods warning about `Pods-Runner.profile.xcconfig` base configuration** — pre-existing (carried over from plan 03), not introduced by this plan. Already on the deferred queue for plan 01-07 verifier per plan 03 SUMMARY's "Deferred items" section.

## User Setup Required

None — no external service configuration, environment variable, or dashboard step required for this plan. The Firebase services are pure dependency installs (no activation per D-01); their dashboard activation is Phase 10/12 work. No new SDK keys needed (google_mobile_ads is already configured from earlier work; Firebase services use the same google-services.json + GoogleService-Info.plist plan 03 placed).

## Next Phase Readiness

- **Plan 01-05 (UMP consent + AdMob gating):** ✅ Ready. `google_mobile_ads ^5.1.0` is installed, exports `ConsentInformation`/`ConsentForm`/`ConsentRequestParameters`. Plan 05 will introduce `ump_*` Maestro selectors per `.maestro/CONVENTIONS.md` and extract AdMob init from `lib/main.dart:43` behind the UMP gate.
- **Plan 01-06 (forgot-password controller refactor):** ✅ Independent. No interactions.
- **Plan 01-07 (Maestro flows + controller tests):** ✅ Ready. None of the new packages affect existing test infrastructure (Maestro selectors are unchanged; `mockito`/`mocktail` already installed for unit tests).
- **Plan 01-08 (phase verification):** Note that the analyzer baseline is **still 0 issues** — this plan introduced zero analyzer warnings. iOS deployment target stays at 15.0 (no regression). Android now requires core library desugaring for `flutter_local_notifications` (verifier should record this in the final phase verification).
- **Phase 5 (QR-02..06):** ✅ Ready to use `pretty_qr_code` 3.6.0 + `screenshot` 3.0.0 + `image` 4.5.4 for advanced visual customization and PNG export.
- **Phase 7 (MKT catalog):** ✅ Ready to use `csv` 8.0.0 for catalog ingest.
- **Phase 9 (MKT-04 checkout):** ✅ Ready to use `flutter_form_builder` 10.3.0+2 + `form_builder_validators` 11.3.0.
- **Phase 10 (MKT-09 FCM):** ✅ Ready. `firebase_messaging` 16.2.0 + `flutter_local_notifications` 17.2.4 both installed; activation is Phase 10's responsibility.
- **Phase 12 (OPT-03 Crashlytics + Analytics):** ✅ Ready. `firebase_crashlytics` 5.2.0 + `firebase_analytics` 12.3.0 both installed; activation is Phase 12's responsibility.

### Deferred items

- The CocoaPods warning about `Pods-Runner.profile.xcconfig` base configuration is unchanged from plan 03; still on the deferred queue for plan 01-07 verifier.
- 3 obsolete-options Java warnings (`source value 8 is obsolete`, `target value 8 is obsolete`) emitted by the AGP compiler when building `flutter_local_notifications`'s own Java sources — they are from the upstream package, not from this project, and do not affect builds. Documented here so plan 01-07 verifier does not flag them as new noise.
- Carry-over from plan 01-01: `01-PATTERNS.md:498` snippet still says `sdk: ^3.29.0` (incorrect). Not touched by this plan (out of scope). Stays in the deferred queue for plan 01-07 or a one-line doc fix.

## Boundary Verification (D-01)

- `grep -rE 'FirebaseMessaging|FirebaseCrashlytics|FirebaseAnalytics|ConsentInformation|ConsentForm' lib/` → **0 matches** ✅ (boundary preserved — no Dart code in `lib/` imports the new packages).
- `grep -c '^\s*google_user_messaging_platform:' pubspec.yaml` → **0** ✅ (the nonexistent package was correctly NOT installed).
- `grep -c '^\s*user_messaging_platform:' pubspec.yaml` → **0** ✅ (the discontinued third-party package was correctly NOT installed).

## TDD Gate Compliance

N/A — plan declared `tdd="false"` (single config-only task; no behavior change). No test gates required. Service-activation tests for FCM/Crashlytics/Analytics/UMP are deliberately deferred to plans 05, 10, and 12 per D-01.

## Self-Check: PASSED

**Commit exists (verified via `git log --oneline -3`):**

```
1990bb6 feat(01-04): install 10 milestone packages
33fd58e docs(01-03): complete firebase-minimum-wiring plan
e46e506 feat(01-03): wire Firebase.initializeApp into main bootstrap before AdMob
```

**Files modified exist:**

- `pubspec.yaml` — present, contains all 10 new package literals (`grep -c '^\s*PACKAGE:'` = 1 each).
- `pubspec.lock` — present, contains entries for all 10 new packages with resolved versions (firebase_core: 4.7.0, others as listed in the Resolved Versions table).
- `ios/Podfile.lock` — present, 42 pods, contains FirebaseMessaging (4 mentions), FirebaseCrashlytics (4), FirebaseAnalytics (6).
- `android/app/build.gradle.kts` — present, contains `isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
- `macos/Flutter/GeneratedPluginRegistrant.swift` — present, contains `import firebase_messaging` and `FlutterLocalNotificationsPlugin.register(...)`.

**Acceptance criteria mapping:**

| Plan acceptance criterion | Status |
|---|---|
| `grep -c '^\s*pretty_qr_code:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*screenshot:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*csv:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*image:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*firebase_messaging:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*firebase_crashlytics:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*firebase_analytics:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*flutter_form_builder:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*form_builder_validators:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*flutter_local_notifications:' pubspec.yaml` returns 1 | ✅ Pass |
| `grep -c '^\s*google_user_messaging_platform:' pubspec.yaml` returns 0 | ✅ Pass |
| `grep -c '^\s*user_messaging_platform:' pubspec.yaml` returns 0 | ✅ Pass |
| `flutter pub get` exits 0 | ✅ Pass (Changed 20 dependencies, 0 conflicts) |
| `pubspec.lock` contains 10 new entries | ✅ Pass (10 matches via grep) |
| `pubspec.lock` shows firebase_core: 4.7.x | ✅ Pass (4.7.0 exact) |
| `flutter analyze --no-fatal-warnings` exits 0 with issue count <= plan 03 baseline | ✅ Pass (0 issues, baseline preserved) |
| `flutter build apk --debug` exits 0 | ✅ Pass (after Rule 3 desugaring fix) |
| `flutter build ios --debug --no-codesign` exits 0 | ✅ Pass |
| `grep -RE 'FirebaseMessaging\|FirebaseCrashlytics\|FirebaseAnalytics\|ConsentInformation\|ConsentForm' lib/` returns no matches | ✅ Pass (D-01 boundary) |
| `ios/Podfile.lock` contains FirebaseMessaging, FirebaseCrashlytics, FirebaseAnalytics (>= 1 each) | ✅ Pass (4, 4, 6 matches respectively) |

All 20 acceptance criteria satisfied. The Rule 3 deviation (Android core library desugaring) is the path through which "flutter build apk --debug exits 0" was achieved; no acceptance criterion was lowered or skipped.

---

*Phase: 01-foundation-hardening*
*Completed: 2026-05-01*
