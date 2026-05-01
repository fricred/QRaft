---
phase: 01-foundation-hardening
plan: 08
type: execute
wave: 6
depends_on:
  - 01
  - 02
  - 03
  - 04
  - 05
  - 06
  - 07
files_modified:
  - .planning/phases/01-foundation-hardening/01-VERIFICATION.md
  - .planning/STATE.md
  - .planning/ROADMAP.md
autonomous: false
requirements:
  - SCAN-01
must_haves:
  truths:
    - "Phase 1 D-11 success criteria are verified end-to-end on a clean checkout: pub upgrade dry-run clean, flutter analyze clean, flutter test 100% green, both debug builds succeed, both simulators run without crash, all 9 Maestro flows green on both simulators (D-11 #1-5)"
    - "ROADMAP success criterion #1 verified: `flutter run` on iOS simulator launches `mobile_scanner` 7.2.0 without dependency errors (proxy: scanner-tab-launch.yaml passing on iOS sim — D-12 explicitly defers physical device to Phase 3)"
    - "ROADMAP success criterion #2 verified: SDK ≥3.29 declared, `flutter pub upgrade --dry-run` reports zero conflicts, `firebase_core` resolves cleanly"
    - "ROADMAP success criterion #3 verified: ForgotPasswordDialog test suite is green (formerly the 5/13 issue, reconciled by plan 06 + rewritten by plan 07)"
    - "ROADMAP success criterion #4 verified: UMP consent SDK integrated; first-launch flow shows the consent gate before any ad request (proxy: ump-accept.yaml + ump-deny-npa.yaml passing on both sims)"
    - "ROADMAP success criterion #5 verified: 10 milestone packages + UMP package present in pubspec.yaml under labeled sections; `flutter pub get` resolves cleanly"
    - "Every D-XX decision from CONTEXT.md (D-01 through D-17) has at least one closing reference in `01-VERIFICATION.md` (decision ID → plan that satisfies it)"
    - "ROADMAP.md Phase 1 entry is checked off `[x]`"
    - "STATE.md Current Position is advanced: Phase 1 marked complete, Phase 2 marked NEXT, blockers refreshed (mobile_scanner iOS unblock confirmed, ForgotPasswordDialog tests green, AdMob UMP live)"
    - "STATE.md Active Todos: the three Phase 1 items are removed (Flutter SDK ≥3.29 verified, pub upgrade dry-run completed, pubspec.lock resolves both qr_flutter+pretty_qr_code)"
    - "Phase 1 progress bar in STATE.md updates from 0/12 to 1/12 (≈8%)"
  artifacts:
    - path: ".planning/phases/01-foundation-hardening/01-VERIFICATION.md"
      provides: "Verification report listing every D-XX decision + every ROADMAP success criterion + the artifact (test output, build log excerpt, Maestro report) that closes it"
      min_lines: 80
      contains: "D-17"
    - path: ".planning/STATE.md"
      provides: "STATE updated to reflect Phase 1 closure"
      contains: "1/12"
    - path: ".planning/ROADMAP.md"
      provides: "Phase 1 checked off"
      contains: "[x] **Phase 1: Foundation Hardening**"
  key_links:
    - from: "01-VERIFICATION.md decision table"
      to: "All preceding 01-NN-SUMMARY.md files"
      via: "Each D-XX row cites the plan + SUMMARY that closed it; reviewers can audit every decision"
      pattern: "D-(0[1-9]|1[0-7])"
    - from: "STATE.md Current Position"
      to: "ROADMAP.md Phase 2"
      via: "After Phase 1 closes, the canonical next command is `/gsd-plan-phase 2` (Phase 2 is parallel-eligible per ROADMAP)"
      pattern: "/gsd-plan-phase 2"
---

<objective>
Run the Phase 1 Definition of Done from D-11 against the integrated codebase: pub upgrade dry-run, analyze, full test suite, both debug builds, both simulator runs, and the 9 Maestro flows on both devices. Then update the canonical project docs (`.planning/STATE.md` and `.planning/ROADMAP.md`) to reflect Phase 1 closure, and produce a one-stop verification report at `01-VERIFICATION.md` that maps every D-XX decision and every ROADMAP success criterion to the artifact that closes it.

Purpose: D-11 enumerates 5 closure conditions; D-12 defines the boundary (no physical-device gates). This plan is the audit trail. After it: STATE.md should unambiguously say "Phase 1 complete, Phase 2 NEXT," and any reviewer can open `01-VERIFICATION.md` and trace each decision to its closing artifact.

Output: 1 new file (`01-VERIFICATION.md`) + 2 modified files (STATE.md, ROADMAP.md). No new code. No new tests. No new flows.

**This plan has a checkpoint** — the final hand-off to the developer (advance STATE, mark roadmap, congrats).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-foundation-hardening/01-CONTEXT.md
@.planning/phases/01-foundation-hardening/01-PATTERNS.md
@.planning/phases/01-foundation-hardening/01-01-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-02-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-03-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-04-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-05-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-06-SUMMARY.md
@.planning/phases/01-foundation-hardening/01-07-SUMMARY.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Run the D-11 closure suite and capture output</name>
  <files></files>
  <read_first>
    - .planning/phases/01-foundation-hardening/01-CONTEXT.md (D-11 the 5 conditions)
    - .planning/phases/01-foundation-hardening/01-07-SUMMARY.md (Maestro pass/fail summary captured by plan 07)
  </read_first>
  <action>
Execute the following commands sequentially on a clean working tree. Capture stdout/stderr for each — the next task will paste excerpts into `01-VERIFICATION.md`.

```bash
# D-11 #1: pub upgrade dry-run is clean
flutter pub upgrade --dry-run 2>&1 | tee /tmp/qraft-p1-pub-upgrade.log

# D-11 #2: flutter analyze is clean
flutter analyze 2>&1 | tee /tmp/qraft-p1-analyze.log

# D-11 #3: flutter test is 100% green
flutter test 2>&1 | tee /tmp/qraft-p1-test.log | tail -20

# D-11 #4: both debug builds succeed
flutter build apk --debug --target-platform android-arm64 2>&1 | tee /tmp/qraft-p1-android-build.log | tail -5
flutter build ios --debug --no-codesign 2>&1 | tee /tmp/qraft-p1-ios-build.log | tail -5

# D-11 #4b: launch on both simulators (manual smoke — plan 07 already ran the full suite)
# flutter run --dart-define-from-file=env.json -d "iPhone"
# flutter run --dart-define-from-file=env.json -d "emulator"

# D-11 #5: Maestro suite green on both simulators (re-run from plan 07 to confirm stability)
maestro list-devices 2>&1 | tee /tmp/qraft-p1-maestro-devices.log
maestro --device "<iOS sim id>" test .maestro/ 2>&1 | tee /tmp/qraft-p1-maestro-ios.log | tail -10
maestro --device "<Android emulator id>" test .maestro/ 2>&1 | tee /tmp/qraft-p1-maestro-android.log | tail -10
```

If ANY of these fails:
- Stop. Do not proceed to task 2.
- File a bug back to the most recent plan that touched the failing area (e.g. test failure → plan 06/07; build failure → plan 03/04; Maestro flow failure → plan 07).
- Fix in that plan's scope; re-run the failed step; only then continue.

Per D-13, mobile_scanner regression is the special case: if `flutter pub upgrade --dry-run` cannot resolve `mobile_scanner ^7.2.0`, escalate to `/gsd-research-phase 1` rather than downgrading.
  </action>
  <verify>
    <automated>test -f /tmp/qraft-p1-pub-upgrade.log &amp;&amp; test -f /tmp/qraft-p1-test.log &amp;&amp; test -f /tmp/qraft-p1-android-build.log &amp;&amp; test -f /tmp/qraft-p1-ios-build.log &amp;&amp; test -f /tmp/qraft-p1-maestro-ios.log &amp;&amp; test -f /tmp/qraft-p1-maestro-android.log &amp;&amp; grep -q 'All tests passed' /tmp/qraft-p1-test.log &amp;&amp; grep -q 'Built' /tmp/qraft-p1-android-build.log &amp;&amp; grep -q 'Built' /tmp/qraft-p1-ios-build.log &amp;&amp; ! grep -q 'Flow Failed' /tmp/qraft-p1-maestro-ios.log &amp;&amp; ! grep -q 'Flow Failed' /tmp/qraft-p1-maestro-android.log</automated>
  </verify>
  <acceptance_criteria>
    - All seven log files exist under `/tmp/qraft-p1-*.log` (pub-upgrade, analyze, test, android-build, ios-build, maestro-ios, maestro-android)
    - `grep 'All tests passed' /tmp/qraft-p1-test.log` returns at least 1 match
    - `grep 'Built ' /tmp/qraft-p1-android-build.log` returns at least 1 match
    - `grep 'Built ' /tmp/qraft-p1-ios-build.log` returns at least 1 match
    - `grep -E 'incompatible|conflict' /tmp/qraft-p1-pub-upgrade.log` returns 0 matches
    - `grep -c 'Flow Failed' /tmp/qraft-p1-maestro-ios.log` returns `0` (programmatic Maestro pass gate — same gate used by plan 07 task 4 per checker WARNING 6)
    - `grep -c 'Flow Failed' /tmp/qraft-p1-maestro-android.log` returns `0` (programmatic Maestro pass gate)
  </acceptance_criteria>
  <done>All five D-11 conditions verified empirically, output captured to /tmp logs for paste into 01-VERIFICATION.md.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Author 01-VERIFICATION.md mapping every D-XX decision and ROADMAP criterion</name>
  <files>.planning/phases/01-foundation-hardening/01-VERIFICATION.md</files>
  <read_first>
    - .planning/phases/01-foundation-hardening/01-CONTEXT.md (every D-XX decision)
    - .planning/ROADMAP.md (Phase 1 success criteria 1-5)
    - .planning/REQUIREMENTS.md (SCAN-01)
    - All 7 SUMMARY files in this phase directory (01-01 through 01-07)
    - /tmp/qraft-p1-*.log files from task 1
  </read_first>
  <action>
Create `.planning/phases/01-foundation-hardening/01-VERIFICATION.md`. Use the template below — replace every `{paste ...}` placeholder with actual log excerpts (last 5-10 lines), and substitute `{ISO date today}` with today's ISO date.

The template:

```markdown
# Phase 1: Foundation Hardening — Verification

**Verified:** {ISO date today}
**Verifier:** Plan 08 (final phase verification)
**Result:** PASS — Phase 1 closes; Phase 2 unblocked.

## Requirement Coverage

| Requirement | Phase | Closing Plan | Evidence |
|-------------|-------|--------------|----------|
| SCAN-01 (mobile_scanner iOS unblock — bump to 7.2.0, Flutter SDK ≥3.29) | 1 | 01 + 07 (E2E) | pubspec.yaml `mobile_scanner: ^7.2.0`; `flutter pub get` resolved; `.maestro/scanner/scanner-tab-launch.yaml` PASS on iOS sim |

## ROADMAP Success Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | flutter run on iOS launches mobile_scanner 7.2.0 without dependency errors | PASS | `flutter build ios --debug --no-codesign` succeeded (`/tmp/qraft-p1-ios-build.log`); scanner-tab-launch.yaml PASS on iOS sim (D-12: physical-device deferred to Phase 3) |
| 2 | Flutter SDK ≥3.29 verified, firebase_core upgrade path tested via flutter pub upgrade --dry-run | PASS | pubspec.yaml `sdk: ^3.29.0`; `/tmp/qraft-p1-pub-upgrade.log` shows no conflicts |
| 3 | ForgotPasswordDialog test suite is fully green | PASS | `flutter test test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` passes; controller suite passes; legacy 5/13 figure reconciled in plan 06 |
| 4 | AdMob UMP integrated; consent form shows on first launch before any ad request | PASS | `lib/features/consent/` module live; `lib/main.dart` defers MobileAds.instance.initialize() until UMP resolves; `.maestro/launch/ump-accept.yaml` + `ump-deny-npa.yaml` PASS on both sims |
| 5 | 10 milestone packages + UMP installed cleanly | PASS | pubspec.yaml lists pretty_qr_code, screenshot, csv, image, firebase_messaging, firebase_crashlytics, firebase_analytics, flutter_form_builder, form_builder_validators, flutter_local_notifications; `flutter pub get` resolved; UMP via existing google_mobile_ads ^5.1.0 (no separate UMP package — see plan 04) |

## Decision Closure (D-01 through D-17)

| Decision | Closing Plan | Verification |
|----------|--------------|--------------|
| D-01 Firebase minimum-wiring scope | 03 + 04 | firebase_core in pubspec; FCM/Crashlytics/Analytics installed but NOT activated |
| D-02 Reuse `qraft-e8a1d` Firebase project | 03 | google-services.json + GoogleService-Info.plist for project `qraft-e8a1d` committed |
| D-03 Firebase historical context (was removed) | 03 | Plan 03 SUMMARY notes the migration history |
| D-04 UMP timing — after splash, before AdMob init | 05 | `lib/main.dart` no longer calls `MobileAds.instance.initialize()` from `initializeApp()`; `UmpGate` runs after splash |
| D-05 UMP scope global (auto-detect GDPR) | 05 | `UmpService` does not maintain a region list; relies on `ConsentInformation.requestConsentInfoUpdate()` |
| D-06 Denial → npa=1 | 05 | `consentGrantedProvider` drives `AdRequest(nonPersonalizedAds: !granted)` in `BannerAdWidget` |
| D-07 UMP is AdMob-only (LGL-03 separate) | 05 | `lib/features/consent/` module has no Habeas Data UI; LGL-03 deferred to Phase 9 per ROADMAP |
| D-08 Refactor + tests for ForgotPasswordDialog | 06 + 07 | `ForgotPasswordController` extracted; tests written in plan 07 |
| D-09 Controller pattern (planner picks) | 06 | StateNotifier + immutable state — rationale documented in plan 06 SUMMARY |
| D-10 Test count reconciliation | 06 | CLAUDE.md and CONCERNS.md updated; empirical count captured |
| D-11 Verification depth (5 conditions) | 08 (this plan) | Task 1 ran all 5 — see /tmp/qraft-p1-*.log |
| D-12 No physical-device gates | 08 | Sim/emulator coverage was the bar; `01-VERIFICATION.md` does not require device runs |
| D-13 mobile_scanner fallback (no downgrade) | 01 | mobile_scanner 7.2.0 resolved cleanly; no downgrade triggered |
| D-14 Maestro foundation in Phase 1 | 02 | `.maestro/` directory committed with config, conventions, helpers |
| D-15 Phase 1 flows (9 enumerated) | 07 | All 9 flows authored and PASS on both devices |
| D-16 CI integration deferred | 07 | `.maestro/CONVENTIONS.md` carries the deferral note |
| D-17 Maestro version pin (2.4.0+) | 02 | `.maestro/.tool-versions` pins `maestro 2.4.0` |

## Build & Test Logs (Excerpts)

### flutter pub upgrade --dry-run
{paste last 10 lines of /tmp/qraft-p1-pub-upgrade.log here}

### flutter analyze
{paste last 5 lines of /tmp/qraft-p1-analyze.log here}

### flutter test
{paste last 10 lines of /tmp/qraft-p1-test.log here — must include "All tests passed!"}

### flutter build apk --debug --target-platform android-arm64
{paste last 5 lines of /tmp/qraft-p1-android-build.log here — must include "Built"}

### flutter build ios --debug --no-codesign
{paste last 5 lines of /tmp/qraft-p1-ios-build.log here — must include "Built"}

### Maestro — iOS simulator
{paste flow-by-flow PASS table from /tmp/qraft-p1-maestro-ios.log}

### Maestro — Android emulator
{paste flow-by-flow PASS table from /tmp/qraft-p1-maestro-android.log}

## Out-of-Scope Items (correctly NOT in Phase 1)

These are explicitly deferred per CONTEXT.md `<deferred>` and `<domain>`:
- Functional scanner verification on physical iOS device → Phase 3 (SCAN-02)
- FCM end-to-end activation → Phase 10 (MKT-09)
- Crashlytics dSYM upload + smoke crash test → Phase 12 (OPT-03)
- Analytics first event + dashboard wiring → Phase 12 (OPT-03)
- Habeas Data Ley 1581 consent UI (LGL-03) → Phase 9
- Maestro CI integration → Phase 12 or dedicated infra phase
- Reconciling QR encoding strategy revision → flagged in STATE.md "Decisions to Revisit"; resolve before `/gsd-discuss-phase 2`

## Phase 2 Readiness

- [x] Build environment clean
- [x] Test infrastructure (controller pattern, Maestro foundation) ready for reuse
- [x] No new blockers introduced
- [x] STATE.md updated to mark Phase 2 NEXT

**Next command:** `/gsd-discuss-phase 2` (resolve QR encoding strategy revision per STATE.md "Decisions to Revisit") then `/gsd-plan-phase 2`.

---
*Phase 1 verification: {ISO date}*
*Closes: SCAN-01, ROADMAP success criteria 1-5, decisions D-01..D-17*
```

Replace `{paste ...}` placeholders with the actual last-N-lines of each captured log. Strip ANSI color codes if present. The goal is auditability, not log archival.
  </action>
  <verify>
    <automated>test -f .planning/phases/01-foundation-hardening/01-VERIFICATION.md &amp;&amp; grep -cE 'D-(0[1-9]|1[0-7])' .planning/phases/01-foundation-hardening/01-VERIFICATION.md | xargs -I {} test {} -ge 17 &amp;&amp; grep -q 'SCAN-01' .planning/phases/01-foundation-hardening/01-VERIFICATION.md</automated>
  </verify>
  <acceptance_criteria>
    - File `.planning/phases/01-foundation-hardening/01-VERIFICATION.md` exists
    - Contains all 17 decision IDs `D-01` through `D-17` (verified via `grep -cE 'D-(0[1-9]|1[0-7])'` returns at least 17)
    - Contains the requirement ID `SCAN-01`
    - Contains all 5 ROADMAP success criteria as PASS rows
    - Each log-excerpt section has at least one line of captured stdout (not the literal placeholder text `{paste ...}`)
    - File ends with `Phase 2 Readiness` checklist all checked
  </acceptance_criteria>
  <done>01-VERIFICATION.md exists, mapping every D-XX decision and every ROADMAP success criterion to its closing artifact, with log excerpts pasted in.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Checkpoint — review 01-VERIFICATION.md before mutating canonical state</name>
  <what-built>Plan 08 task 1 ran the full D-11 closure suite and captured logs; task 2 produced 01-VERIFICATION.md mapping every decision and success criterion to its closing artifact. Now: human review before mutating canonical project state files.</what-built>
  <how-to-verify>
1. Open `.planning/phases/01-foundation-hardening/01-VERIFICATION.md` and read it end-to-end. Confirm:
   - Every D-01..D-17 row cites a closing plan
   - All 5 ROADMAP success criteria are PASS
   - Log excerpts contain actual command output (not the `{paste ...}` placeholders)
   - Maestro tables show 9/9 PASS on iOS sim AND on Android emulator

2. Spot-check the codebase:
   ```bash
   git status                              # clean from plans 01-07
   flutter analyze                         # zero errors
   flutter test 2>&1 | tail -3             # "All tests passed!"
   grep 'mobile_scanner: \^7\.2' pubspec.yaml
   grep 'firebase_core' pubspec.yaml
   # UMP is provided by google_mobile_ads ^5.1.0, NOT a separate package
   test "$(grep -c 'google_user_messaging_platform' /Users/ianmoone/Development/Personal/qraft/pubspec.yaml)" -eq 0  # must be absent
   grep 'google_mobile_ads' /Users/ianmoone/Development/Personal/qraft/pubspec.yaml  # must be present
   ls .maestro/auth/ .maestro/launch/ .maestro/scanner/ .maestro/helpers/
   grep 'Firebase.initializeApp' lib/main.dart
   grep 'UmpGate' lib/main.dart
   grep 'ForgotPasswordController' lib/features/auth/presentation/controllers/forgot_password_controller.dart
   ```

3. If everything looks clean, reply "approved" and the next task will mutate STATE.md + ROADMAP.md.

4. If anything fails, reply with what's wrong — it goes back to the responsible plan (e.g., test failure → plan 06/07; missing flow → plan 07; missing UMP wiring → plan 05).
  </how-to-verify>
  <resume-signal>Reply "approved" to proceed with STATE.md + ROADMAP.md updates. Reply with details if something fails the audit.</resume-signal>
</task>

<task type="auto" tdd="false">
  <name>Task 4: Update STATE.md + ROADMAP.md to mark Phase 1 complete and Phase 2 NEXT</name>
  <files>.planning/STATE.md, .planning/ROADMAP.md</files>
  <read_first>
    - .planning/STATE.md (current Current Position, Active Todos, Progress bar)
    - .planning/ROADMAP.md (Phase 1 entry — currently `- [ ] **Phase 1: Foundation Hardening**`)
    - .planning/phases/01-foundation-hardening/01-VERIFICATION.md (completed in task 2)
  </read_first>
  <action>
**Edit 1: `.planning/ROADMAP.md`**

Change the line:
```
- [ ] **Phase 1: Foundation Hardening** — Resolve brownfield concerns ...
```
To:
```
- [x] **Phase 1: Foundation Hardening** — Resolve brownfield concerns (mobile_scanner iOS, ForgotPasswordDialog tests, AdMob UMP consent), align Flutter SDK ≥3.29, install milestone packages
```

In the `## Progress Table` near the bottom, update the Phase 1 row from:
```
| 1. Foundation Hardening | 0/? | Not started | - |
```
To:
```
| 1. Foundation Hardening | 8/8 | Complete | {ISO date today} |
```

**Edit 2: `.planning/STATE.md`**

a) Update `**Last updated:**` line to today's ISO date.

b) Update `## Current Position` block:
- `**Phase:** 1 of 12 — Foundation Hardening` → `**Phase:** 2 of 12 — QR Generation Core (NEXT)`
- `**Plan:** Not started` → `**Plan:** Not started — pending /gsd-discuss-phase 2`
- `**Status:** Phase 1 context gathered ...` → `**Status:** Phase 1 complete (verified .planning/phases/01-foundation-hardening/01-VERIFICATION.md); Phase 2 awaiting /gsd-discuss-phase 2 to resolve QR encoding strategy revision (see Decisions to Revisit below)`
- `**Last session:** 2026-05-01 ...` → `**Last session:** {ISO date today} — Phase 1 closed; advance to Phase 2 discuss`

c) Update Progress bar from:
```
**Progress:** [▱▱▱▱▱▱▱▱▱▱▱▱] 0/12 phases complete (0%)
```
To:
```
**Progress:** [▰▱▱▱▱▱▱▱▱▱▱▱] 1/12 phases complete (≈8%)
```

d) Update the phase art block (lines 28-41 in current STATE.md):
- `Phase 1:  ▱ Foundation Hardening              ← NEXT` → `Phase 1:  ▰ Foundation Hardening              ✅`
- `Phase 2:  ▱ QR Generation Core                (parallel-eligible after P1)` → `Phase 2:  ▱ QR Generation Core                ← NEXT (parallel-eligible)`

e) In `## Accumulated Context` → `### Active Todos`, REMOVE these three Phase 1 lines:
```
- [ ] Verify Flutter SDK ≥ 3.29 (mobile_scanner 7.x requirement) — Phase 1
- [ ] Run `flutter pub upgrade --dry-run` to confirm `firebase_core` upgrade path | Phase 1
- [ ] Confirm `pubspec.lock` resolves `pretty_qr_code` alongside `qr_flutter` (both depend on `qr` package) — Phase 1
```
Leave the other todos (Phase 4 domain registration, Phase 7 photography, Phase 9 lawyer + Wompi keys) untouched.

f) In `### Blockers`, replace `None currently. All identified blockers ...` with:
```
None currently. Phase 1 closure removed: mobile_scanner iOS block (resolved via 7.2.0 bump), ForgotPasswordDialog test fragility (resolved via controller extraction), AdMob UMP gap (resolved via ConsentInformation/ConsentForm from google_mobile_ads ^5.1.0).
```

g) Update `## Session Continuity` — replace `**Files written this session:**` block with:
```
**Files written this session:**
- `.planning/phases/01-foundation-hardening/01-01..08-PLAN.md` and corresponding SUMMARYs
- `.planning/phases/01-foundation-hardening/01-VERIFICATION.md` (Phase 1 audit)
- `lib/features/consent/...` (new module: data/domain/presentation)
- `lib/features/auth/presentation/controllers/forgot_password_controller.dart` (new)
- `.maestro/...` (new test foundation; 9 phase-1 flows green on both sims)

**Next command:** `/gsd-discuss-phase 2` — REQUIRED before `/gsd-plan-phase 2` because the QR encoding strategy decision in `Decisions to Revisit` (line ~85) MUST be resolved (parametrizable per-QR-type, marketplace URL-only restriction, hybrid heterogeneous, or strategy abandonment).
```

Do NOT touch the `### Decisions to Revisit` section — the QR encoding strategy line stays as-is until Phase 2 discussion resolves it. Do NOT touch `### Decisions Locked` (those carry forward as project-level invariants).
  </action>
  <verify>
    <automated>grep -q '\[x\] \*\*Phase 1: Foundation Hardening\*\*' .planning/ROADMAP.md &amp;&amp; grep -q '1/12 phases complete' .planning/STATE.md &amp;&amp; ! grep -q 'Verify Flutter SDK ≥ 3.29' .planning/STATE.md &amp;&amp; grep -q '/gsd-discuss-phase 2' .planning/STATE.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c '\[x\] \*\*Phase 1: Foundation Hardening\*\*' .planning/ROADMAP.md` returns at least 1
    - `grep -c '8/8 | Complete' .planning/ROADMAP.md` returns at least 1 (progress table updated)
    - `grep -c '1/12 phases complete' .planning/STATE.md` returns at least 1
    - `grep -c 'Verify Flutter SDK ≥ 3.29' .planning/STATE.md` returns 0 (Phase 1 todo removed)
    - `grep -c 'flutter pub upgrade --dry-run' .planning/STATE.md` returns 0 (Phase 1 todo removed)
    - `grep -c '/gsd-discuss-phase 2' .planning/STATE.md` returns at least 1 (Next command updated)
    - `grep -c 'Phase 2 of 12' .planning/STATE.md` returns at least 1 (Current Position advanced)
    - `grep -c 'Decisions to Revisit' .planning/STATE.md` returns at least 1 (section preserved)
  </acceptance_criteria>
  <done>ROADMAP.md Phase 1 entry checked off and progress row updated; STATE.md Current Position advanced to Phase 2 NEXT with progress bar at 1/12, Phase 1 todos removed, blockers refreshed, and Next command pointing to `/gsd-discuss-phase 2`. Phase 1 is now formally closed.</done>
</task>

</tasks>

<verification>
After all 4 tasks complete:

```bash
# 1. The verification report is the audit anchor
test -f .planning/phases/01-foundation-hardening/01-VERIFICATION.md
grep -cE 'D-(0[1-9]|1[0-7])' .planning/phases/01-foundation-hardening/01-VERIFICATION.md  # >= 17

# 2. ROADMAP reflects closure
grep '\[x\] \*\*Phase 1' .planning/ROADMAP.md
grep '8/8 | Complete' .planning/ROADMAP.md

# 3. STATE points to Phase 2
grep '1/12 phases complete' .planning/STATE.md
grep '/gsd-discuss-phase 2' .planning/STATE.md

# 4. Codebase is still healthy
flutter analyze
flutter test 2>&1 | tail -3
```
</verification>

<success_criteria>
- D-11 (#1-5) all five conditions verified empirically with captured logs
- D-12 satisfied: simulator/emulator was the bar; no physical-device gates
- All 17 decisions D-01..D-17 closed in 01-VERIFICATION.md
- All 5 ROADMAP success criteria PASS
- SCAN-01 (the only formal v1 requirement bound to Phase 1) closed
- ROADMAP.md and STATE.md reflect Phase 1 closure and Phase 2 readiness
- Developer has a clear single document (`01-VERIFICATION.md`) to share or audit
- Next command `/gsd-discuss-phase 2` is signposted and the QR encoding strategy revision is preserved as the precondition
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-hardening/01-08-SUMMARY.md` documenting:
- Final pass/fail breakdown of the D-11 suite
- Confirmation that 01-VERIFICATION.md is committed and complete
- The Phase 1 → Phase 2 transition (STATE.md before/after diff summary)
- Any deferred items still tracked (link back to STATE.md "Decisions to Revisit")
- Phase 1 closure declaration
</output>
