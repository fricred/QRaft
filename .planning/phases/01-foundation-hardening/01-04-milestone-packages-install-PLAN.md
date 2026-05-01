---
phase: 01-foundation-hardening
plan: 04
type: execute
wave: 3
depends_on:
  - 01
  - 03
files_modified:
  - pubspec.yaml
  - pubspec.lock
  - ios/Podfile.lock
autonomous: true
requirements: []
must_haves:
  truths:
    - "10 milestone packages declared in pubspec.yaml grouped by purpose with section comments (D-01 + ROADMAP success criterion #5)"
    - "NO standalone UMP package is installed — the modern UMP API is shipped INSIDE `google_mobile_ads ^5.1.0` (already in pubspec). Verified via Google's official AdMob privacy docs 2026-05-01: `ConsentInformation.instance.requestConsentInfoUpdate(...)` and `ConsentForm.loadAndShowConsentFormIfRequired(...)` are exported from `google_mobile_ads`. The third-party `user_messaging_platform` package on pub.dev is **discontinued** (last version 1.3.0); the Flutter ecosystem moved consent into google_mobile_ads itself. Plan 05 imports UMP types from `google_mobile_ads` — no separate dep needed."
    - "Firebase service packages pinned to versions that share `firebase_core ^4.7.0` (verified via pub.dev API 2026-05-01): `firebase_messaging: ^16.2.0`, `firebase_crashlytics: ^5.2.0`, `firebase_analytics: ^12.3.0`"
    - "All 10 new packages resolve via `flutter pub get` with no version conflicts (firebase_core ^4.7.0 was pinned in plan 03 specifically so this plan resolves on first try)"
    - "`pubspec.lock` shows resolved versions matching `^X.Y.Z` constraints"
    - "`flutter analyze --no-fatal-warnings` exits 0 with issue count unchanged from plan 03 baseline"
    - "`flutter build apk --debug` and `flutter build ios --debug --no-codesign` both succeed"
    - "No new code wires any of these packages into the app — packages are introduced as available but unused dependencies. Wiring is deferred: UMP/AdMob to plan 05; FCM/Crashlytics/Analytics activation to Phases 10+12"
  artifacts:
    - path: "pubspec.yaml"
      provides: "10 new package declarations under properly-labeled sections"
      contains: "pretty_qr_code"
    - path: "pubspec.yaml"
      provides: "Firebase service packages pinned to firebase_core ^4.7.0 compatible versions"
      contains: "firebase_messaging: ^16.2.0"
    - path: "pubspec.lock"
      provides: "Resolved versions for all 10 new packages"
      contains: "firebase_messaging"
    - path: "ios/Podfile.lock"
      provides: "iOS pods updated to include Firebase services"
      contains: "FirebaseMessaging"
  key_links:
    - from: "pubspec.yaml google_mobile_ads (existing)"
      to: "plan 05 UMP service implementation"
      via: "Modern UMP API ships inside google_mobile_ads ^5.1.0 — `ConsentInformation.instance` is the singleton plan 05 imports. No standalone UMP package install needed."
      pattern: "google_mobile_ads"
    - from: "pubspec.yaml firebase_messaging entry"
      to: "Phase 10 FCM activation (MKT-09)"
      via: "Phase 10 imports firebase_messaging from this declaration; Phase 1 only installs"
      pattern: "firebase_messaging"
    - from: "pubspec.yaml pretty_qr_code entry"
      to: "Phase 5 QR Customization (QR-02..06)"
      via: "Phase 5 uses pretty_qr_code for advanced visual customization; Phase 1 only installs"
      pattern: "pretty_qr_code"
---

<objective>
Install 10 milestone packages in `pubspec.yaml`, organized into clearly-labeled section blocks. Run `flutter pub get` and `pod install` to confirm clean resolution. NO code wires these packages — they are installed as available-but-unused dependencies. UMP gating (plan 05) uses `ConsentInformation.instance` from the already-installed `google_mobile_ads ^5.1.0` — no separate UMP package install required.

Purpose: ROADMAP success criterion #5 — "Milestone packages installed cleanly: `pretty_qr_code`, `screenshot`, `csv`, `image`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`, `flutter_form_builder`, `form_builder_validators`, `flutter_local_notifications`". D-04 prerequisite (consent flow) is satisfied by `google_mobile_ads` which is already installed at line 93 of pubspec.yaml.

**Why no separate UMP package?** Verified via WebFetch of https://developers.google.com/admob/flutter/privacy on 2026-05-01: Google's recommended path is `ConsentInformation.instance.requestConsentInfoUpdate(...)` and `ConsentForm.loadAndShowConsentFormIfRequired(...)` exported from `google_mobile_ads` itself. The standalone third-party package `user_messaging_platform` (latest 1.3.0) is discontinued and recommends migrating to `google_mobile_ads`. The package referenced in earlier drafts (`google_user_messaging_platform`) does NOT exist on pub.dev (verified by searching pub.dev/api/search?q=user_messaging_platform).

Plan 03 already installed `firebase_core ^4.7.0` (the version line that matches the firebase_messaging 16.x / firebase_crashlytics 5.x / firebase_analytics 12.x current line). This plan layers the 3 Firebase service packages on top with versions that all declare `firebase_core: ^4.7.0` as their dependency — verified via pub.dev API 2026-05-01. No bump-and-retry needed.

Output: All 10 packages declared, pubspec.lock resolved cleanly, both platform builds succeed.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/phases/01-foundation-hardening/01-CONTEXT.md
@.planning/phases/01-foundation-hardening/01-PATTERNS.md
@.planning/research/STACK.md
@.planning/phases/01-foundation-hardening/01-03-SUMMARY.md
@pubspec.yaml

<external_docs>
- pretty_qr_code 3.6.0: https://pub.dev/packages/pretty_qr_code
- screenshot 3.0.0: https://pub.dev/packages/screenshot
- csv 8.0.0: https://pub.dev/packages/csv
- image 4.x: https://pub.dev/packages/image
- firebase_messaging 16.2.0: https://pub.dev/packages/firebase_messaging (declares firebase_core ^4.7.0)
- firebase_crashlytics 5.2.0: https://pub.dev/packages/firebase_crashlytics (declares firebase_core ^4.7.0)
- firebase_analytics 12.3.0: https://pub.dev/packages/firebase_analytics (declares firebase_core ^4.7.0)
- flutter_form_builder 10.x: https://pub.dev/packages/flutter_form_builder
- form_builder_validators 11.x: https://pub.dev/packages/form_builder_validators
- flutter_local_notifications 17.x: https://pub.dev/packages/flutter_local_notifications
- AdMob UMP via google_mobile_ads (the modern path): https://developers.google.com/admob/flutter/privacy
</external_docs>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Add 10 milestone packages to pubspec.yaml under labeled sections</name>
  <files>pubspec.yaml, pubspec.lock</files>
  <read_first>
    - pubspec.yaml (current state — post plan 01 + plan 03)
    - .planning/research/STACK.md (lines 30-162 — exact version recommendations per package)
    - .planning/research/STACK.md (lines 252-266 — version compatibility table)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md (lines 469-509 — pubspec section grouping pattern)
    - .planning/phases/01-foundation-hardening/01-CONTEXT.md (D-01 — package list)
    - .planning/phases/01-foundation-hardening/01-03-SUMMARY.md (firebase_core version pinned in plan 03)
  </read_first>
  <action>
Edit `pubspec.yaml` to add 10 new dependency entries grouped into 4 new sections.

**Step A — Extend the existing `# Firebase` section** (added by plan 03 — currently contains only `firebase_core: ^4.7.0`). Add the 3 service packages immediately under the existing entry, keeping the existing comment header:

```yaml
  # Firebase (Phase 1: minimum wiring only — services activated in Phases 10 + 12 per D-01)
  # Versions verified via pub.dev API 2026-05-01: each declares firebase_core ^4.7.0 as its dep,
  # so the trio resolves cleanly with the firebase_core ^4.7.0 pin from plan 03.
  firebase_core: ^4.7.0
  firebase_messaging: ^16.2.0
  firebase_crashlytics: ^5.2.0
  firebase_analytics: ^12.3.0
```

These specific versions (verified via `curl https://pub.dev/api/packages/firebase_messaging` etc on 2026-05-01) are the current `latest` on pub.dev and ALL declare `firebase_core: ^4.7.0` as their dependency. There is no version-conflict path on a clean checkout — this is deterministic, no fallback branch needed.

**Step B — Insert these new sections** AFTER the `# Firebase` section and BEFORE the `# QR Functionality` section:

```yaml

  # Advanced QR Generation (Phase 5: QR-02..06)
  pretty_qr_code: ^3.6.0
  screenshot: ^3.0.0
  image: ^4.5.4
  csv: ^8.0.0

  # Forms (Phase 9: MKT-04 checkout)
  flutter_form_builder: ^10.3.0
  form_builder_validators: ^11.1.2

  # Notifications (Phase 10: MKT-09 + companion to firebase_messaging)
  flutter_local_notifications: ^17.2.4
```

**NOTE — UMP package intentionally NOT installed:**
The modern Google-recommended UMP API for Flutter ships INSIDE `google_mobile_ads` (already at line 93, `google_mobile_ads: ^5.1.0`). Plan 05 imports `ConsentInformation`, `ConsentForm`, and `ConsentRequestParameters` from `google_mobile_ads` directly. Verified via:
- https://developers.google.com/admob/flutter/privacy (Google's official AdMob privacy docs)
- pub.dev search 2026-05-01: standalone `user_messaging_platform` package is **discontinued** (last version 1.3.0), recommends migrating to google_mobile_ads
- The hypothetical `google_user_messaging_platform` package referenced in earlier drafts does NOT exist on pub.dev

Do NOT add any UMP package to pubspec — it would be a dead dep at best and a name conflict at worst.

**Step C — Run resolution + build chain:**
```bash
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter analyze --no-fatal-warnings
flutter build apk --debug
flutter build ios --debug --no-codesign
```

All steps must exit 0. If `flutter pub get` reports a version conflict, capture the exact error and stop — do NOT widen ranges silently. Report the conflict (most likely cause: a transitive dep of one of these packages clashes with an existing dep) and surface for review.

**Boundary check (D-01):** after edits, `grep -RE 'FirebaseMessaging|FirebaseCrashlytics|FirebaseAnalytics' lib/` MUST return zero matches. The packages are installed but no Dart code yet imports them. Plan 05 imports `ConsentInformation` from `google_mobile_ads`; Phases 10/12 import the Firebase services.

**Boundary check (UMP):** `grep -R 'ConsentInformation\|ConsentForm' lib/` should also return zero matches in this plan — plan 05 does the actual import.
  </action>
  <verify>
    <automated>grep -c '^\s*pretty_qr_code:' pubspec.yaml; grep -c '^\s*screenshot:' pubspec.yaml; grep -c '^\s*csv:' pubspec.yaml; grep -c '^\s*image:' pubspec.yaml; grep -c '^\s*firebase_messaging:' pubspec.yaml; grep -c '^\s*firebase_crashlytics:' pubspec.yaml; grep -c '^\s*firebase_analytics:' pubspec.yaml; grep -c '^\s*flutter_form_builder:' pubspec.yaml; grep -c '^\s*form_builder_validators:' pubspec.yaml; grep -c '^\s*flutter_local_notifications:' pubspec.yaml; flutter pub get; flutter analyze --no-fatal-warnings</automated>
  </verify>
  <acceptance_criteria>
    - For each package literal listed below, `grep -c '^\s*PACKAGE:' pubspec.yaml` returns exactly `1`:
      `pretty_qr_code`, `screenshot`, `csv`, `image`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`, `flutter_form_builder`, `form_builder_validators`, `flutter_local_notifications`.
    - `grep -c '^\s*google_user_messaging_platform:' pubspec.yaml` returns `0` (no separate UMP package — modern API is in google_mobile_ads).
    - `grep -c '^\s*user_messaging_platform:' pubspec.yaml` returns `0` (discontinued third-party package; do not install).
    - `flutter pub get` exits 0.
    - `pubspec.lock` contains entries for each of the 10 new packages (verified via `grep -E '^\s*(pretty_qr_code|screenshot|csv|image|firebase_messaging|firebase_crashlytics|firebase_analytics|flutter_form_builder|form_builder_validators|flutter_local_notifications):' pubspec.lock | wc -l` returns >= 10).
    - `pubspec.lock` shows `firebase_core: version: "4.7.x"` (matched the constraint from plan 03; no bump occurred).
    - `flutter analyze --no-fatal-warnings` exits 0 with issue count <= plan 03 baseline (record exact count in SUMMARY).
    - `flutter build apk --debug` exits 0.
    - `flutter build ios --debug --no-codesign` exits 0.
    - `grep -RE 'FirebaseMessaging|FirebaseCrashlytics|FirebaseAnalytics|ConsentInformation|ConsentForm' lib/` returns no matches (boundary check — plans 05 and Phases 10/12 own the import-and-use phase).
    - `ios/Podfile.lock` contains `FirebaseMessaging`, `FirebaseCrashlytics`, `FirebaseAnalytics` (grep returns >= 1 each).
  </acceptance_criteria>
  <done>10 packages declared; both platform builds succeed; analyzer baseline preserved; no Dart code yet imports them; no separate UMP package installed (modern API ships in google_mobile_ads). Per D-01, ROADMAP success criterion #5.</done>
</task>

</tasks>

<verification>
- `pubspec.yaml` declares all 10 milestone packages under labeled sections.
- `flutter pub upgrade --dry-run` clean.
- `flutter analyze --no-fatal-warnings` issue count unchanged from plan 03 baseline.
- Both platform debug builds succeed.
- No Dart code imports the new packages (boundary check passes).
- No standalone UMP package installed (modern API is in google_mobile_ads).
- firebase_core stays at the ^4.7.0 line from plan 03 (no bump triggered).
</verification>

<success_criteria>
1. 10 milestone packages declared (D-01).
2. `pubspec.lock` resolved cleanly with no version conflicts.
3. Both platforms build (apk + ios --no-codesign).
4. Analyzer baseline preserved.
5. No package wired into Dart code yet — boundary preserved for plans 05+ and Phases 10+12.
6. UMP gating prerequisite satisfied via existing `google_mobile_ads ^5.1.0` (D-04 — modern path; no separate package).
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-hardening/01-04-SUMMARY.md` capturing:
- Final resolved versions for all 10 packages.
- Confirmation that firebase_core stayed at ^4.7.0 (no bump from plan 03's pin).
- Note that no separate UMP package was installed — google_mobile_ads ^5.1.0 already in pubspec carries the consent API plan 05 uses.
- iOS Podfile.lock excerpt showing FirebaseMessaging, FirebaseCrashlytics, FirebaseAnalytics pods installed.
- Confirmation: `grep -RE 'FirebaseMessaging|FirebaseCrashlytics|FirebaseAnalytics|ConsentInformation' lib/` returns 0 matches.
- Analyzer issue count for downstream comparison.
</output>
</content>
</invoke>