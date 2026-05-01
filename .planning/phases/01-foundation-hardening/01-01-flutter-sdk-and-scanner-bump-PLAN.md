---
phase: 01-foundation-hardening
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - pubspec.yaml
autonomous: true
requirements:
  - SCAN-01
must_haves:
  truths:
    - "pubspec.yaml declares Flutter SDK constraint ^3.29.0 (per research SUMMARY.md and STACK.md compatibility table)"
    - "pubspec.yaml declares mobile_scanner ^7.2.0 (D-13: never downgrade; addresses SCAN-01)"
    - "`flutter pub upgrade --dry-run` reports zero version conflicts (D-11 #1)"
    - "`flutter pub get` succeeds; pubspec.lock resolves with both qr_flutter ^4.1.0 and mobile_scanner ^7.2.0 alongside their shared `qr` transitive dep"
  artifacts:
    - path: "pubspec.yaml"
      provides: "Flutter SDK ≥3.29 constraint and mobile_scanner ^7.2.0 pin"
      contains: "sdk: ^3.29"
    - path: "pubspec.yaml"
      provides: "mobile_scanner version bump"
      contains: "mobile_scanner: ^7.2.0"
    - path: "pubspec.lock"
      provides: "Lockfile reflecting upgraded constraints"
      contains: "mobile_scanner"
  key_links:
    - from: "pubspec.yaml SDK constraint"
      to: "mobile_scanner 7.x runtime requirement"
      via: "Flutter SDK ≥3.29 enables mobile_scanner 7.x APIs (Vision API on iOS)"
      pattern: "sdk:\\s*\\^3\\.29"
    - from: "pubspec.yaml mobile_scanner pin"
      to: "iOS scanner unblock (SCAN-01)"
      via: "7.2.0 uses Apple Vision API instead of MLKit (research SUMMARY.md)"
      pattern: "mobile_scanner:\\s*\\^7\\.2\\.0"
---

<objective>
Bump Flutter SDK constraint to ^3.29.0 and `mobile_scanner` to ^7.2.0 in `pubspec.yaml`, then verify the upgrade path is clean via `flutter pub upgrade --dry-run` and `flutter pub get`.

Purpose: Unblock SCAN-01 (research SUMMARY.md identified 7.2.0 as the version that adopts iOS Vision API instead of MLKit, eliminating the iOS dependency block flagged in `.planning/codebase/CONCERNS.md`). Establishes a stable pubspec foundation for all downstream Wave 2 work (Firebase reintroduction and milestone package installs in plans 03 and 04).

Output: Updated `pubspec.yaml` + regenerated `pubspec.lock` with no conflicts.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/01-foundation-hardening/01-CONTEXT.md
@.planning/phases/01-foundation-hardening/01-PATTERNS.md
@.planning/research/SUMMARY.md
@.planning/research/STACK.md
@.planning/codebase/STACK.md
@.planning/codebase/CONCERNS.md
@pubspec.yaml
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Bump Flutter SDK constraint and mobile_scanner pin in pubspec.yaml</name>
  <files>pubspec.yaml</files>
  <read_first>
    - pubspec.yaml (current state — line 22 SDK constraint, line 51 mobile_scanner)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md (lines 469–509 — pubspec edit pattern + version targets)
    - .planning/research/STACK.md (lines 252–266 — version compatibility matrix)
    - .planning/research/SUMMARY.md (line 33 — mobile_scanner 7.2.0 + Flutter 3.29 requirement)
  </read_first>
  <action>
Edit `pubspec.yaml` with two single-line changes — preserve all other content, comments, formatting, and ordering exactly as-is.

1. Line 22 currently reads:
```yaml
  sdk: ^3.6.2
```
Change to:
```yaml
  sdk: ^3.29.0
```
(per `.planning/research/STACK.md:255` — "mobile_scanner: ^7.2.0 requires Flutter 3.29.0+, iOS 13+, Android API 21+"; per CONTEXT.md D-01 implicit prerequisite for milestone packages.)

2. Line 51 currently reads:
```yaml
  mobile_scanner: ^7.0.0
```
Change to:
```yaml
  mobile_scanner: ^7.2.0
```
(per CONTEXT.md D-13 — "the specific bet from research SUMMARY.md"; SCAN-01 in REQUIREMENTS.md line 29; D-13 explicitly forbids downgrading to 6.x — that re-introduces the MLKit iOS bug.)

Do NOT modify any other lines in pubspec.yaml. Do NOT add new dependencies in this task — milestone packages are introduced in plan 04 (`01-04-milestone-packages-install-PLAN.md`). Do NOT add Firebase deps — they belong in plan 03 (`01-03-firebase-minimum-wiring-PLAN.md`).
  </action>
  <verify>
    <automated>grep -E '^\s*sdk:\s*\^3\.29' pubspec.yaml &amp;&amp; grep -E '^\s*mobile_scanner:\s*\^7\.2\.0' pubspec.yaml</automated>
  </verify>
  <acceptance_criteria>
    - `grep -E '^\s*sdk:\s*\^3\.29' pubspec.yaml` returns the line `  sdk: ^3.29.0` (exit 0).
    - `grep -E '^\s*mobile_scanner:\s*\^7\.2\.0' pubspec.yaml` returns the line `  mobile_scanner: ^7.2.0` (exit 0).
    - `grep -c '^\s*mobile_scanner:' pubspec.yaml` returns `1` (no duplicate entries).
    - `git diff pubspec.yaml` shows exactly 2 changed lines (SDK constraint + mobile_scanner) — no other modifications.
    - `pubspec.yaml` line count is unchanged (no insertions/deletions besides the two edits).
  </acceptance_criteria>
  <done>pubspec.yaml line 22 reads `  sdk: ^3.29.0` and the mobile_scanner entry reads `  mobile_scanner: ^7.2.0`. No other lines modified. Per D-13.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Verify upgrade path with `flutter pub upgrade --dry-run` and regenerate `pubspec.lock`</name>
  <files>pubspec.lock</files>
  <read_first>
    - pubspec.yaml (post-Task 1 state)
    - pubspec.lock (current state — to compare deltas)
    - .planning/phases/01-foundation-hardening/01-CONTEXT.md (D-11 #1: "flutter pub upgrade --dry-run reports no conflicts")
    - .planning/research/STACK.md (lines 262–266 — pre-merge checklist)
  </read_first>
  <action>
Run `flutter pub upgrade --dry-run` from the repo root. Expected behavior:
- Output must include `mobile_scanner 7.2.x` (or higher matching ^7.2.0) and `qr_flutter 4.1.0` (unchanged) — both must resolve.
- Output must NOT contain `Because qraft depends on ... version solving failed` or `incompatible` errors.
- Output must NOT contain conflicts on the transitive `qr` package (per STATE.md active todo line 91 — "Confirm `pubspec.lock` resolves `pretty_qr_code` alongside `qr_flutter` (both depend on `qr` package)" — pretty_qr_code is added later in plan 04, but verify NOW that mobile_scanner 7.2.0 + qr_flutter 4.1.0 still co-resolve cleanly).

If `--dry-run` reports any version-solving failure: STOP. Per CONTEXT.md D-13, do not downgrade. Surface the failure and escalate to the user (recommend `/gsd-research-phase 1` rerun).

If `--dry-run` succeeds: run `flutter pub get` to update `pubspec.lock`. Confirm:
- `pubspec.lock` is regenerated.
- Diff shows `mobile_scanner: 7.2.x` (matching ^7.2.0).

Then run `flutter analyze --no-fatal-warnings` to confirm the project still type-checks under the new SDK constraint. Existing warnings are acceptable; net-new errors are not. Capture the analyzer baseline (count of issues) for plan 07's final-gate comparison.
  </action>
  <verify>
    <automated>flutter pub upgrade --dry-run 2>&amp;1 | grep -E 'mobile_scanner.*7\.2' &amp;&amp; flutter pub get &amp;&amp; grep -E '^\s*mobile_scanner:' pubspec.lock | head -1</automated>
  </verify>
  <acceptance_criteria>
    - `flutter pub upgrade --dry-run` exits 0.
    - `flutter pub upgrade --dry-run` stdout contains a line matching `mobile_scanner.*7\.2\.[0-9]+` (or higher within ^7.2.0).
    - `flutter pub upgrade --dry-run` stdout does NOT contain the strings `version solving failed`, `incompatible`, or `because qraft depends on`.
    - `flutter pub get` exits 0.
    - `pubspec.lock` exists and `grep -A1 '^\s*mobile_scanner:' pubspec.lock` shows `version: "7.2.x"` for some x ≥ 0.
    - `flutter analyze --no-fatal-warnings` exits 0 OR shows the same issue count as before this plan (record the count in SUMMARY.md so plan 07 can compare).
  </acceptance_criteria>
  <done>`--dry-run` clean, `flutter pub get` succeeds, `pubspec.lock` shows mobile_scanner 7.2.x, `flutter analyze` baseline captured. Per D-11 #1.</done>
</task>

</tasks>

<verification>
After both tasks:
- `cat pubspec.yaml | grep -E '^\s*(sdk:|mobile_scanner:)'` shows exactly the two new lines.
- `flutter pub get` exits 0.
- `flutter pub upgrade --dry-run` exits 0 with no `version solving failed`.
- Analyzer issue count documented in SUMMARY.md for downstream comparison.

If `--dry-run` fails: do NOT proceed. Per D-13, escalate by spawning `/gsd-research-phase 1` and pausing Phase 1.
</verification>

<success_criteria>
1. pubspec.yaml line 22 reads `  sdk: ^3.29.0`.
2. pubspec.yaml mobile_scanner entry reads `  mobile_scanner: ^7.2.0`.
3. `flutter pub upgrade --dry-run` reports no conflicts (D-11 #1, ROADMAP success criterion #2).
4. `pubspec.lock` updated to reflect mobile_scanner 7.2.x.
5. `flutter analyze` issue count captured for downstream regression detection.
6. SCAN-01 unblock prerequisite satisfied (Vision API path available; physical-device verification deferred to Phase 3 per D-12).
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-hardening/01-01-SUMMARY.md` capturing:
- Old vs new SDK constraint and mobile_scanner pin.
- `flutter pub upgrade --dry-run` final exit code and any noteworthy resolution lines.
- Final mobile_scanner version selected by resolver (e.g., 7.2.4).
- Analyzer baseline issue count.
- Confirmation that no other dependency changed unexpectedly (diff pubspec.lock summary).
</output>
