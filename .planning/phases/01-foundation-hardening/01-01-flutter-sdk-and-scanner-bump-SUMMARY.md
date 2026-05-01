---
phase: 01-foundation-hardening
plan: 01
subsystem: infra
tags: [pubspec, flutter-sdk, dart-sdk, mobile_scanner, dependency-management]

# Dependency graph
requires: []
provides:
  - "pubspec.yaml expresses Flutter SDK >=3.29 via correct pub syntax (sdk: ^3.7.0 + flutter: '>=3.29.0')"
  - "mobile_scanner pinned to ^7.2.0 (Vision API on iOS, foundation for SCAN-01 unblock)"
  - "pubspec.lock locked at mobile_scanner 7.2.0; qr_flutter 4.1.0 + mobile_scanner 7.2.0 co-resolve via shared transitive `qr` package without conflict"
  - "Analyzer baseline captured: 0 issues (No issues found!)"
affects:
  - "01-03-firebase-minimum-wiring (Firebase SDK installs need stable pub baseline)"
  - "01-04-milestone-packages-install (10 milestone packages install on top of this constraint)"
  - "01-07-phase-verification (analyzer baseline = 0 issues feeds final-gate regression check)"
  - "Phase 3 QR Scanner (SCAN-01 prerequisite — Vision API path now available)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Use both `sdk:` (Dart) and `flutter:` (Flutter) constraints in pubspec.yaml `environment` block when a Flutter SDK floor matters — never write the Flutter version in the `sdk:` field"

key-files:
  created: []
  modified:
    - "pubspec.yaml"
    - "pubspec.lock"

key-decisions:
  - "Express Flutter >=3.29 requirement via combined `sdk: ^3.7.0` + `flutter: '>=3.29.0'` (not `sdk: ^3.29.0` which is uninstantiable: Dart 3.29 does not exist)"
  - "mobile_scanner pinned at ^7.2.0 exactly per D-13 (no downgrade fallback)"

patterns-established:
  - "Dart vs Flutter SDK constraint distinction in pubspec.yaml environment block (per https://dart.dev/tools/pub/pubspec)"
  - "Lockfile delta minimization: when bumping a single dependency, verify `git diff pubspec.lock` touches only that dependency's lines"

requirements-completed: []  # SCAN-01 unblock prerequisite satisfied (Vision API path available); requirement itself completes in Phase 3 with physical-device verification

# Metrics
duration: 3m
completed: 2026-05-01
---

# Phase 1 Plan 01: Flutter SDK and Scanner Bump Summary

**Bumped `mobile_scanner` 7.1.4 -> 7.2.0 (iOS Vision API path) and corrected the Flutter SDK constraint in `pubspec.yaml` to use proper pub syntax (`sdk: ^3.7.0` + `flutter: '>=3.29.0'`), unblocking the SCAN-01 dependency block.**

## Performance

- **Duration:** ~3 min (219 s)
- **Started:** 2026-05-01T20:21:30Z
- **Completed:** 2026-05-01T20:25:09Z
- **Tasks:** 2
- **Files modified:** 2 (`pubspec.yaml`, `pubspec.lock`)

## Accomplishments

- pubspec.yaml now declares Flutter SDK >=3.29 in the only pub-valid way: combined Dart SDK floor (`sdk: ^3.7.0`) + Flutter SDK floor (`flutter: '>=3.29.0'`)
- mobile_scanner upgraded from 7.0.0 (constraint) / 7.1.4 (lockfile) to ^7.2.0 (constraint) / 7.2.0 (lockfile)
- Verified `qr_flutter 4.1.0` and `mobile_scanner 7.2.0` co-resolve cleanly — the shared transitive `qr` package resolves to a single version (3.0.2) with no conflict
- Captured analyzer baseline of **0 issues** for plan 01-07 final-gate regression detection
- pubspec.lock diff is minimal (2 insertions + 2 deletions, only the mobile_scanner sha256 + version lines changed) — no other dependencies drifted unexpectedly

## Task Commits

Each task was committed atomically (no `--no-verify`, on the main working tree of `feature/adds`):

1. **Task 1: Bump Flutter SDK constraint and mobile_scanner pin in pubspec.yaml** — `55b4710` (feat)
2. **Task 2: Correct SDK constraint syntax and lock mobile_scanner 7.2.0** — `3ca9881` (fix — see Deviations section)

Plan metadata + STATE.md + ROADMAP.md update commit will follow this SUMMARY.

## Files Created/Modified

- `pubspec.yaml` — environment block now `sdk: ^3.7.0` + `flutter: '>=3.29.0'`; `mobile_scanner: ^7.2.0`
- `pubspec.lock` — `mobile_scanner` resolved to `7.2.0` (sha256 `c92c26bf...`)
- `.planning/phases/01-foundation-hardening/01-01-flutter-sdk-and-scanner-bump-SUMMARY.md` — this file

## Decisions Made

- **Express Flutter >=3.29 with combined `sdk` + `flutter` constraints, not `sdk: ^3.29.0`.** The plan author wrote `sdk: ^3.29.0` intending "Flutter SDK >=3.29", but pub interprets the `environment.sdk` field as the Dart SDK constraint. Dart 3.29 does not exist (Flutter 3.29 ships with Dart 3.7; the locally installed Flutter 3.38.5 ships with Dart 3.10.4). The pub docs (https://dart.dev/tools/pub/pubspec) explicitly call out the combined-constraint pattern for this case. Applied as Rule 3 (auto-fix blocking issue) — see Deviations section for full rationale. The intent of D-13 / research SUMMARY.md is preserved exactly: "require Flutter 3.29 or newer for mobile_scanner 7.x runtime" is now correctly expressed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected `environment.sdk` constraint syntax**

- **Found during:** Task 2 (running `flutter pub upgrade --dry-run`)
- **Issue:** Task 1's literal instruction to set `sdk: ^3.29.0` produced an unsatisfiable constraint. Pub treats `environment.sdk` as the **Dart** SDK constraint, not Flutter. Dart 3.29 does not exist — current Dart is 3.10.4 (shipped with Flutter 3.38.5 stable). The plan/research conflated the Flutter SDK version with the Dart SDK constraint.
- **Symptom:** `flutter pub upgrade --dry-run` failed with:
  ```
  Because qraft requires SDK version ^3.29.0, version solving failed.
  ```
- **Fix:** Replaced `sdk: ^3.29.0` with the pub-canonical pattern for "require Flutter X+":
  ```yaml
  environment:
    sdk: ^3.7.0          # Dart that ships with Flutter 3.29
    flutter: '>=3.29.0'  # explicit Flutter floor (mobile_scanner 7.x req.)
  ```
  - `sdk: ^3.7.0` is the Dart version that ships with Flutter 3.29.0 (Feb 2025 release).
  - `flutter: '>=3.29.0'` is the explicit, machine-checkable Flutter floor that pub now enforces when running inside the `flutter` tool (per https://dart.dev/tools/pub/pubspec — "A Flutter SDK constraint is only satisfied if pub is executed within the `flutter` tool and the Flutter SDK's `version` file meets the specified lower bound").
- **Why this is Rule 3, not Rule 4 (escalate):** The plan's intent is unambiguous — it cites research/STACK.md line 255 ("mobile_scanner: ^7.2.0 requires Flutter 3.29.0+") which explicitly says **Flutter** SDK. The error is a literal misuse of the pubspec field, with a mechanical fix that exactly preserves the stated intent. D-13 ("if mobile_scanner 7.2.0 fails to resolve, escalate") was authored for the case where 7.2.0 itself is unresolvable; here 7.2.0 was never tested because resolution stopped at the Dart SDK constraint check. Once the constraint is corrected, 7.2.0 resolves cleanly on the first attempt.
- **Files modified:** `pubspec.yaml` (env block: 1 line replaced with 2 lines), `pubspec.lock` (mobile_scanner 7.1.4 -> 7.2.0)
- **Verification:**
  - `flutter pub upgrade --dry-run` -> exit 0, no `version solving failed` / `because qraft depends on` strings
  - `flutter pub get` -> exit 0, "Got dependencies!"
  - `flutter analyze --no-fatal-warnings` -> exit 0, "No issues found!"
  - `grep -E '^\s*mobile_scanner:' pubspec.lock` followed by `version: "7.2.0"`
  - `qr_flutter 4.1.0` and `mobile_scanner 7.2.0` both resolve via shared transitive `qr 3.0.2` — no conflict
- **Committed in:** `3ca9881` (Task 2 commit — combined the SDK fix with the lockfile regeneration that Task 2 was already responsible for, per the GSD principle of one logical change per commit; the fix is the *means* by which Task 2's verification gate passes, so they are inseparable)

---

**Total deviations:** 1 auto-fixed (1 blocking issue — pub-syntax error in plan)
**Impact on plan:** Zero scope creep. The deviation corrects a literal authoring mistake in the plan to make `flutter pub upgrade --dry-run` actually executable. The Flutter >=3.29 intent (D-13, research SUMMARY.md) is fully preserved, now in pub-canonical syntax. Recommended follow-up: update `.planning/research/STACK.md` line 255 wording (it's correct — says "Flutter 3.29.0+") and the literal `sdk: ^3.29.0` snippet in `01-PATTERNS.md` line 498 (incorrect — should be `sdk: ^3.7.0` + `flutter: '>=3.29.0'`) to prevent the same misreading in future plans within Phase 1. Logging this in deferred-items per the GSD scope-boundary rule rather than auto-editing planning docs from this executor.

## Issues Encountered

- **Initial `--dry-run` failure on Dart 3.29 constraint** — resolved via Rule 3 deviation above. No other issues during execution.

## User Setup Required

None — `pubspec.yaml` and `pubspec.lock` are the only artifacts; no external services need configuration for this plan. Firebase reintroduction is plan 01-03's scope.

## Next Phase Readiness

- **Plan 01-02 (Maestro foundation):** Ready. Independent of pub baseline.
- **Plan 01-03 (Firebase minimum wiring):** Ready. Needs `firebase_core` install, which now sits on a stable pub baseline. The "Confirm `firebase_core` upgrade path for messaging + crashlytics doesn't break existing firebase_auth" todo from STATE.md (line 90) becomes plan 01-03's first verification step — its dry-run will run cleanly because this plan validated the pub resolver is healthy under Flutter 3.38.5.
- **Plan 01-04 (Milestone packages install):** Ready. The shared transitive `qr` package check (qr_flutter ^4.1.0 + future pretty_qr_code ^3.6.0 from plan 01-04) is half-validated here — qr_flutter currently resolves cleanly, and STACK.md confirms pretty_qr_code 3.6.0 declares no upper-bound conflict.
- **Phase 3 (QR Scanner):** Vision API path on iOS is now available. Physical-device verification deferred to Phase 3 per D-12.

### Deferred items

- Update `.planning/phases/01-foundation-hardening/01-PATTERNS.md:498` (incorrect snippet `sdk: ^3.29.0` → should be `sdk: ^3.7.0` + `flutter: '>=3.29.0'`). Logged for Phase 1 plan 01-07 verification step or as a one-line doc fix in any subsequent plan touching that file.

## TDD Gate Compliance

N/A — plan declared `tdd="false"` on all tasks (config-only changes). No test gates required.

## Self-Check: PASSED

**Commits exist:**

```
$ git log --oneline -3
3ca9881 fix(01-01): correct SDK constraint syntax and lock mobile_scanner 7.2.0
55b4710 feat(01-01): bump Flutter SDK to ^3.29.0 and mobile_scanner to ^7.2.0
2f05497 docs(01): create phase 1 plan (foundation hardening)
```

**Files modified exist:**

- `pubspec.yaml` — present, contains `sdk: ^3.7.0`, `flutter: '>=3.29.0'`, `mobile_scanner: ^7.2.0`
- `pubspec.lock` — present, `mobile_scanner` block shows `version: "7.2.0"`

**Acceptance criteria mapping:**

| Plan acceptance criterion | Status |
|---|---|
| `grep -E '^\s*sdk:\s*\^3\.29' pubspec.yaml` returns the line | ⚠️ Adjusted via deviation: now `sdk: ^3.7.0` + `flutter: '>=3.29.0'` (semantically equivalent and pub-valid) |
| `grep -E '^\s*mobile_scanner:\s*\^7\.2\.0' pubspec.yaml` returns the line | ✅ Pass (line 52: `  mobile_scanner: ^7.2.0`) |
| `grep -c '^\s*mobile_scanner:' pubspec.yaml` returns `1` | ✅ Pass |
| `flutter pub upgrade --dry-run` exits 0 | ✅ Pass |
| `flutter pub upgrade --dry-run` stdout NOT contains `version solving failed` / `because qraft depends on` | ✅ Pass |
| `flutter pub get` exits 0 | ✅ Pass |
| `pubspec.lock` shows `mobile_scanner` `version: "7.2.x"` | ✅ Pass (7.2.0) |
| `flutter analyze --no-fatal-warnings` clean baseline | ✅ Pass (0 issues) |

The first row deviates from the literal grep but **fully preserves the plan's intent** (require Flutter SDK >=3.29). Documented in Deviations.

---

*Phase: 01-foundation-hardening*
*Completed: 2026-05-01*
