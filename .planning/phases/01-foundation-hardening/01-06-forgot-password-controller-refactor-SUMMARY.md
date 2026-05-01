---
phase: 01-foundation-hardening
plan: 06
subsystem: auth
tags: [riverpod, state-notifier, forgot-password, supabase-auth, maestro, widget-keys, refactor]

# Dependency graph
requires:
  - phase: 01-foundation-hardening
    provides: ".maestro/CONVENTIONS.md (selector convention <feature>_<element>_<role>) — plan 02 deliverable"
provides:
  - "ForgotPasswordController (StateNotifier<ForgotPasswordState> with immutable state class) at lib/features/auth/presentation/controllers/forgot_password_controller.dart"
  - "forgotPasswordControllerProvider (StateNotifierProvider.autoDispose) wired into forgot_password_dialog.dart"
  - "ForgotPasswordState immutable state class (isLoading, emailSent, errorMessage) with copyWith / value-equality"
  - "20 stable Maestro Keys across 5 lib files (forgot_password_*, login_*, welcome_*, main_scaffold_*, qr_scanner_screen_root) — plan 07's selector inventory"
  - "MainScaffoldKeys class in main_scaffold.dart enumerating all 5 bottom-nav tab Keys (dashboard/generate/scanner/library/marketplace) for plan 07 reuse"
  - "Empirically corrected ForgotPasswordDialog test count documentation in CLAUDE.md + .planning/codebase/CONCERNS.md (6 tests, not 13; 0 failing pre-refactor, not 5/13)"
  - "Removed 4 stale references to the non-existent lib/features/auth/presentation/controllers/auth_controller.dart from CLAUDE.md (replaced with the actual SupabaseAuthProvider path + a forward-pointer to the new ForgotPasswordController)"
affects:
  - "01-07-maestro-flows-and-controller-tests (consumes the controller for unit tests + the 20 Maestro Keys for E2E flow selectors; rewrites the now-broken-by-design forgot_password_dialog_test.dart against the controller)"
  - "Future auth-adjacent plans (Phase 1 plan 08 verification, downstream phases) — pattern of StateNotifier + immutable state + constructor-injected SupabaseClient is now an in-codebase analog for new controllers"

# Tech tracking
tech-stack:
  added: []  # No new packages — forgot_password_controller built on flutter_riverpod (already in pubspec) + supabase_flutter
  patterns:
    - "StateNotifier + immutable state class for auth flow controllers (mirrors qr_customization_controller.dart precedent)"
    - "Constructor-injected SupabaseClient for testability (default falls back to SupabaseService.client)"
    - "Re-entrancy guard (`if (state.isLoading) return;`) inside submit() to absorb double-taps"
    - "StateNotifierProvider.autoDispose for short-lived flow controllers — auto-resets on widget unmount"
    - "Source-of-truth pattern for Maestro Keys: literal Key strings live in the feature scaffold (main_scaffold.dart MainScaffoldKeys class) and are passed as optional Key? props to the rendering widget (main_navigation.dart) — keeps the selector greppable from its semantic owner without scattering"

key-files:
  created:
    - "lib/features/auth/presentation/controllers/forgot_password_controller.dart (142 lines: ForgotPasswordState + ForgotPasswordController + forgotPasswordControllerProvider)"
  modified:
    - "lib/features/auth/presentation/widgets/forgot_password_dialog.dart (removed _emailSent local boolean + direct supabaseAuthProvider call; reads forgotPasswordControllerProvider; +5 Maestro Keys + 2 Semantics labels)"
    - "lib/features/auth/presentation/pages/login_screen.dart (+5 Maestro Keys; _buildTextField extended with optional Key? fieldKey)"
    - "lib/features/auth/presentation/pages/welcome_screen.dart (+3 Maestro Keys)"
    - "lib/features/main/main_scaffold.dart (+1 root Key + new MainScaffoldKeys class with 5 tab Keys)"
    - "lib/shared/widgets/main_navigation.dart (extended with Key? params for each tab; applied to GestureDetectors)"
    - "lib/features/qr_scanner/qr_scanner_screen.dart (+1 Scaffold root Key)"
    - "CLAUDE.md (test-count line corrected; 4 auth_controller references scrubbed)"
    - ".planning/codebase/CONCERNS.md (test-count line corrected in 2 places — Known Bugs + Test Coverage Gaps)"

key-decisions:
  - "Controller pattern picked: StateNotifier<ForgotPasswordState> + immutable state class, mirroring lib/features/qr_generator/presentation/controllers/qr_customization_controller.dart. Reasoning documented inline in the controller's dartdoc — no AsyncNotifier example exists in the codebase, AsyncNotifier migration is out of Phase 1 scope per CONTEXT.md, and Phase 1 (foundation hardening) should not introduce one-off new patterns. Resolves D-09."
  - "Provider is StateNotifierProvider.autoDispose so closing/reopening the dialog auto-resets the controller's state — sidesteps the race-condition pitfall flagged in CONCERNS.md without requiring an explicit reset() call from the dialog. Resolves D-08."
  - "Constructor accepts `SupabaseClient? client` with default fallback to `SupabaseService.client` — testability seam for plan 07's MockSupabaseClient injection (per PATTERNS.md note 'controller MUST accept the client via constructor for testability'). Resolves D-08 testability blocker."
  - "Re-entrancy guard: `if (state.isLoading) return;` at the top of submit() so double-tapping the send button cannot fire two requests."
  - "Maestro Key naming `main_scaffold_<tab>_tab` for ALL 5 bottom-nav tabs (not just scanner) — even though plan 06 must_haves only requires scanner_tab, providing the full set front-loads plan 07's selector needs."
  - "Source-of-truth pattern for navigation Keys: keep the literal Key('main_scaffold_scanner_tab') string in main_scaffold.dart (so it's greppable from the file the plan claims owns it), pass via Key? prop to MainNavigation which actually renders the icon. The bottom nav widget stays a presentational widget."
  - "Empirical test count: 6 tests in forgot_password_dialog_test.dart (verified `grep -cE 'testWidgets\\(|^\\s*test\\(' = 6`); pre-refactor 0/6 failing (`flutter test ... = +6 -0 All tests passed!`). The 5/13 docs figure was stale. Resolves D-10."

patterns-established:
  - "StateNotifier + immutable state class = the auth-controller analog in this codebase. Future auth controllers (e.g., signup, profile-update) should mirror this same shape unless there is an explicit reason to deviate."
  - "Re-entrancy guard pattern for async submit() handlers (`if (state.isLoading) return;`) — applies to any form-submission controller."
  - "Maestro Key literal strings live in the feature-scaffold/owner file; rendering widgets accept Key? params and apply them. Greppable from the semantic owner, no scattering."

requirements-completed: []  # plan 06 has `requirements: []` in frontmatter — plumbing-only refactor, no v1 requirement IDs

# Metrics
duration: 11min
completed: 2026-05-01
---

# Phase 1 Plan 06: Forgot Password Controller Refactor Summary

**Extracted ForgotPasswordController (StateNotifier + immutable state) from forgot_password_dialog.dart, wired the dialog to consume forgotPasswordControllerProvider, dropped 20 stable Maestro Keys across 5 lib files, and reconciled the stale 5/13 dialog-test-count documentation in CLAUDE.md + CONCERNS.md.**

## Performance

- **Duration:** ~11 min (639 s)
- **Started:** 2026-05-01T23:03:26Z
- **Completed:** 2026-05-01T23:14:05Z
- **Tasks:** 3
- **Files created:** 1 (controller)
- **Files modified:** 8 (5 lib widgets + 1 nav helper + 2 docs)
- **Commits:** 3 (one per task)

## Accomplishments

- **ForgotPasswordController extracted** at `lib/features/auth/presentation/controllers/forgot_password_controller.dart` (142 lines): immutable `ForgotPasswordState` (isLoading + emailSent + errorMessage with copyWith / value-equality) + `ForgotPasswordController` extends `StateNotifier<ForgotPasswordState>` with `submit(email)` mirroring the supabase_auth_provider error-handling shape exactly + `forgotPasswordControllerProvider` as `StateNotifierProvider.autoDispose`. SupabaseClient injected via constructor for testability. Re-entrancy guard absorbs double-taps.
- **Dialog refactor**: `forgot_password_dialog.dart` dropped its `_emailSent` local boolean and direct `supabaseAuthProvider` call; now reads state via `ref.watch(forgotPasswordControllerProvider)` and submits via `ref.read(forgotPasswordControllerProvider.notifier).submit(email)`. Form validation stays in the widget (UI concern); state machine moved out.
- **20 stable Maestro Keys** added across 5 lib files following `.maestro/CONVENTIONS.md` selector convention `<feature>_<element>_<role>`:
  - dialog: `forgot_password_dialog_root`, `forgot_password_email_field`, `forgot_password_cancel_button`, `forgot_password_send_button`, `forgot_password_success_state` (+ Semantics labels on action buttons)
  - login screen: `login_screen_root`, `login_email_field`, `login_password_field`, `login_forgot_password_link`, `login_submit_button`
  - welcome screen: `welcome_screen_root`, `welcome_signup_cta`, `welcome_login_cta`
  - main scaffold: `main_scaffold_root` + `MainScaffoldKeys` class enumerating `main_scaffold_dashboard_tab`, `main_scaffold_generate_tab`, `main_scaffold_scanner_tab`, `main_scaffold_library_tab`, `main_scaffold_marketplace_tab`
  - qr scanner: `qr_scanner_screen_root`
- **Doc reconciliation per D-10**: CLAUDE.md `Testing Implementation Status` line corrected from "🔄 ForgotPasswordDialog: 5/13 tests passing" → "6/6 tests passing pre-refactor (verified empirically 2026-05-01)". `.planning/codebase/CONCERNS.md` updated in 2 places (Known Bugs + Test Coverage Gaps) with the empirical count + a forward-pointer to plans 06+07.
- **auth_controller scrub per checker WARNING 4**: 4 stale references to the non-existent `lib/features/auth/presentation/controllers/auth_controller.dart` (and its matching `auth_controller_simple_test.dart`) scrubbed from CLAUDE.md (lines 66, 786, 828, 849). Replaced with the actual auth state holder path `test/features/auth/data/providers/supabase_auth_provider_test.dart` + a forward-pointer to the new ForgotPasswordController in plan 07.
- **Build + analyzer clean**: `flutter analyze` reports 0 issues across the project (baseline preserved); `flutter build apk --debug --target-platform android-arm64` and `flutter build ios --debug --no-codesign` both succeed.

## Task Commits

Each task was committed atomically (no `--no-verify`, sequential on `feature/adds`):

| # | Task | Commit | Type |
|---|---|---|---|
| 1 | Empirically count tests + reconcile CLAUDE.md (test count + auth_controller scrub) and CONCERNS.md | `47339ee` | docs |
| 2 | Create ForgotPasswordController + provider | `fda41b7` | feat |
| 3 | Refactor dialog to use controller + add Maestro Keys to dialog/login/welcome/scaffold/scanner | `217db0c` | refactor |

Plan metadata + STATE.md + ROADMAP.md commit follows this SUMMARY.

## Files Created/Modified

### Created

- `lib/features/auth/presentation/controllers/forgot_password_controller.dart` (142 lines) — `ForgotPasswordState` (immutable) + `ForgotPasswordController` (StateNotifier) + `forgotPasswordControllerProvider` (autoDispose). Mirrors `qr_customization_controller.dart` shape; mirrors `supabase_auth_provider.dart:145-165` error handling exactly.
- `.planning/phases/01-foundation-hardening/01-06-forgot-password-controller-refactor-SUMMARY.md` — this file.

### Modified

- `lib/features/auth/presentation/widgets/forgot_password_dialog.dart` — dropped `_emailSent` boolean, dropped direct `supabaseAuthProvider` import + read; now reads `ref.watch(forgotPasswordControllerProvider)`; submit uses `ref.read(forgotPasswordControllerProvider.notifier).submit(email)`; +5 Maestro Keys; +2 Semantics labels.
- `lib/features/auth/presentation/pages/login_screen.dart` — extended `_buildTextField` with optional `Key? fieldKey` parameter; +5 Maestro Keys (root, email, password, forgot, submit).
- `lib/features/auth/presentation/pages/welcome_screen.dart` — +3 Maestro Keys (root, signup CTA, login CTA).
- `lib/features/main/main_scaffold.dart` — +1 root Key; +new `MainScaffoldKeys` class enumerating all 5 tab Keys (dashboard/generate/scanner/library/marketplace) so the literal `main_scaffold_scanner_tab` string is greppable from this file while the actual placement lives in `main_navigation.dart`.
- `lib/shared/widgets/main_navigation.dart` — extended with optional `Key?` params per tab (`dashboardTabKey`, `generateTabKey`, `scannerTabKey`, `libraryTabKey`, `marketplaceTabKey`); applied to `GestureDetector` in `_buildNavItem` and `_buildCenterButton`.
- `lib/features/qr_scanner/qr_scanner_screen.dart` — +1 `Scaffold key: const Key('qr_scanner_screen_root')`.
- `CLAUDE.md` — test-count line corrected; 4 auth_controller(_simple_test).dart references scrubbed and replaced with `supabase_auth_provider_test.dart` + forward-pointer to `ForgotPasswordController` (Phase 1 plan 06).
- `.planning/codebase/CONCERNS.md` — test-count corrected in `Known Bugs > ForgotPasswordDialog Test Failures` (line 47) and `Test Coverage Gaps > ForgotPasswordDialog Incomplete Coverage` (line 322).

## Decisions Made

(See key-decisions in frontmatter for the canonical list. Highlights:)

- **Pattern (D-09):** StateNotifier + immutable state class. Reasoning: no `AsyncNotifier` example in the codebase, AsyncNotifier migration explicitly deferred per CONTEXT.md, Phase 1 = foundation hardening (not the place to introduce one-off patterns). Direct mirror of `qr_customization_controller.dart`.
- **Race-condition mitigation (D-08):** `StateNotifierProvider.autoDispose` so re-entry into the dialog auto-resets state; plus a re-entrancy guard inside `submit()` for double-tap absorption.
- **Testability seam (D-08):** `SupabaseClient? client` constructor parameter with default fallback to `SupabaseService.client`. Plan 07 will inject `MockSupabaseClient` (mocktail) — same pattern as `supabase_auth_provider_test.dart`.
- **Source of truth for Maestro Keys** spanning multiple files: literal Key strings live in the feature scaffold (`main_scaffold.dart` `MainScaffoldKeys`); the rendering widget (`main_navigation.dart`) accepts them as `Key?` props. Solves the "where does the literal string live so grep finds it where the plan expects?" question without forcing the rendering widget to import scaffold-level concerns.
- **Empirical test counts (D-10):** 6 tests, 0 failing pre-refactor (full pass) — the 5/13 documentation was stale. Recorded in commit message of task 1 and in both reconciled docs.

## Deviations from Plan

None. Plan 01-06 executed exactly as written. All 3 tasks completed in order, all acceptance criteria met, all must_haves.truths satisfied.

The 5 unplanned tabs receiving extra Keys (instead of just `scanner_tab`) is explicitly invited by the plan ("Add equivalent keys for the other tabs while you are there ... so plan 07 has a full set of selectors"); not a deviation.

The literal Key('main_scaffold_scanner_tab') string lives in main_scaffold.dart per the plan's grep verification, even though the actual `Key()` placement on the GestureDetector lives in main_navigation.dart. This is the cleanest way to satisfy both the structural spec (scaffold owns navigation semantics) and the grep verification (string in expected file). Documented inline as a key decision.

## Issues Encountered

**Test breakage from contract change (planned, expected):**
The 6 tests in `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` now fail because they still override the obsolete `supabaseAuthProvider`. The dialog now consumes `forgotPasswordControllerProvider`, and the new controller's default constructor calls `SupabaseService.client` — which throws "Supabase has not been initialized" in the test environment (no MockSupabaseClient injection yet). Failure mode is runtime (build-time + analyze still clean), not compile.

This is **explicitly documented as expected** by the plan: "the existing test file may now fail because the dialog state shape changed. **That is expected.** Plan 07 rewrites the test suite. For this plan: fix any non-test compile errors only. Test breakage from contract changes is allowed; compile errors in `lib/` are not."

**Whole-suite delta confirms no collateral damage:**

| Metric | Pre-Task-3 (post-Task-2 baseline) | Post-Task-3 (current) | Delta |
|---|---|---|---|
| Passing | +89 | +83 | -6 |
| Skipped | ~1 | ~1 | 0 |
| Failing | -85 | -91 | +6 |

The +6 failures are **exactly the 6 dialog tests** flipped by the contract change. No tests outside the planned-broken set regressed. The pre-existing 85 failures are out of scope (not introduced by this plan).

Plan 07 task 1 will rewrite `forgot_password_dialog_test.dart` against the controller (overriding `forgotPasswordControllerProvider` with a controller built from `MockSupabaseClient`), and add a new `forgot_password_controller_test.dart` that exercises the state machine in isolation.

## User Setup Required

None — all changes are local code edits + documentation reconciliation. No external services or credentials need configuration.

## Next Phase Readiness

- **Plan 01-05 (UMP consent + AdMob gating):** Independent of this plan; ready. Will introduce `ump_consent_screen_root` / `ump_continue_button` / `ump_settings_link` widgets — the convention in `.maestro/CONVENTIONS.md` is the spec they must follow.
- **Plan 01-07 (Maestro flows + controller tests):** READY. Has every selector it needs:
  - 5 forgot_password_* selectors on the dialog
  - 5 login_* selectors on the login screen
  - 3 welcome_* selectors on the welcome screen
  - 6 main_scaffold_* selectors (root + 5 tabs)
  - 1 qr_scanner_screen_root selector on the scanner
  Plus the controller is ready to be unit-tested via constructor-injected MockSupabaseClient. Plan 07 task 1 will:
  1. Author `test/features/auth/presentation/controllers/forgot_password_controller_test.dart` (state-machine unit tests)
  2. Rewrite `test/features/auth/presentation/widgets/forgot_password_dialog_test.dart` against the controller (override `forgotPasswordControllerProvider`, drop the obsolete `supabaseAuthProvider` mock setup)
  3. Tighten `.maestro/helpers/login.yaml` from text-matchers to id-matchers using the 5 login_* Keys this plan added
  4. Author 9 phase-1 Maestro flows on top of helpers + conventions
- **Plan 01-08 (phase verification):** READY when 05 + 07 land.

### Deferred items

None new in this plan. Carry-over deferred items from prior plans remain untouched (PATTERNS.md:498 SDK-snippet wording fix, CocoaPods Pods-Runner.profile.xcconfig warning) — both are logged in STATE.md "Active Todos" for plan 01-07 verification.

## TDD Gate Compliance

N/A — plan declared `tdd="false"` on all 3 tasks (refactor + Keys + doc reconciliation; no testable behavior introduced; controller-level tests are explicitly assigned to plan 07 per the plan's own scope statement). No TDD gate commits required.

## Self-Check: PASSED

**Commits exist:**

```
$ git log --oneline -3
217db0c refactor(01-06): wire forgot-password dialog to controller + add Maestro Keys
fda41b7 feat(01-06): add ForgotPasswordController with StateNotifier + immutable state
47339ee docs(01-06): reconcile ForgotPasswordDialog test count + scrub auth_controller refs
```

**Files created exist:**

```
$ ls lib/features/auth/presentation/controllers/forgot_password_controller.dart
lib/features/auth/presentation/controllers/forgot_password_controller.dart

$ wc -l lib/features/auth/presentation/controllers/forgot_password_controller.dart
142 lib/features/auth/presentation/controllers/forgot_password_controller.dart
```

**Acceptance criteria mapping (from plan `<verification>` block):**

| Plan verification step | Expected | Actual | Status |
|---|---|---|---|
| 1. Doc reconciliation visible (`verified empirically` / `pre-refactor` greppable in CONCERNS.md + CLAUDE.md) | ≥1 each | 2+1 hits | PASS |
| 2. `grep -c 'auth_controller' CLAUDE.md` returns 0 | 0 | 0 | PASS |
| 3. Controller exists and structured: `class ForgotPasswordController` + `class ForgotPasswordState` + `forgotPasswordControllerProvider` | all 3 | all 3 found | PASS |
| 4. Dialog uses controller: `forgotPasswordControllerProvider` greppable in dialog file | ≥1 | 2 | PASS |
| 5. All Maestro selectors present: `Key('(forgot_password\|login\|welcome\|main_scaffold\|qr_scanner)_*')` count across lib/ | many | 20 | PASS |
| 6a. `flutter analyze` | 0 errors | 0 errors | PASS |
| 6b. `flutter build apk --debug --target-platform android-arm64` | Built | Built (`✓ Built build/app/outputs/flutter-apk/app-debug.apk`) | PASS |
| 6c. `flutter build ios --debug --no-codesign` | Built | Built (`✓ Built build/ios/iphoneos/Runner.app`) | PASS |

**Plan acceptance per task:**

| Task | Acceptance criteria | Status |
|---|---|---|
| 1 | `verified empirically 2026-05-01` ≥1 in CONCERNS.md; `5 out of 13` = 0; `5/13 tests passing` = 0 in CLAUDE.md; `pre-refactor` ≥1 in CLAUDE.md; `auth_controller_simple_test.dart` = 0; `auth_controller.dart` = 0; `supabase_auth_provider_test.dart` ≥2; `ForgotPasswordController` ≥1 | All 8 grep gates pass |
| 2 | controller file exists; `class ForgotPasswordController extends StateNotifier` = 1; `class ForgotPasswordState` = 1; `on AuthException` ≥1 (got 2: dartdoc + catch); `forgotPasswordControllerProvider` = 1; `SupabaseClient? client` = 1; analyzer 0 errors on controllers/ | All 7 gates pass |
| 3 | `_emailSent` count = 0 in dialog; `forgotPasswordControllerProvider` ≥2 in dialog (got 2); 5 dialog Keys (got 5); 5 login Keys (got 5); 3 welcome Keys (got 3); `main_scaffold_scanner_tab` ≥1 in main_scaffold.dart (got 1); `qr_scanner_screen_root` ≥1 in qr_scanner_screen.dart (got 1); `flutter analyze lib/` = 0 errors; debug builds pass | All 9 gates pass |

**Must_haves.truths from frontmatter (12 truths):**

| # | Truth | Status |
|---|---|---|
| 1 | ForgotPasswordController exists at the prescribed path | PASS |
| 2 | Pattern decision documented (StateNotifier + immutable state, qr_customization_controller analog, no AsyncNotifier in repo) | PASS — captured in controller dartdoc + this SUMMARY frontmatter key-decisions |
| 3 | `forgot_password_dialog.dart` no longer holds async state; `_emailSent` gone; UI reads `ref.watch(forgotPasswordControllerProvider)`; submission via `ref.read(forgotPasswordControllerProvider.notifier).submit(email)` | PASS |
| 4 | Stable Maestro Keys on dialog (4 specified + dialog_root) | PASS — 5 Keys |
| 5 | Login + welcome screens carry stable Keys for Maestro auth flows | PASS — 5 login + 3 welcome |
| 6 | Main scaffold scanner tab is targetable: `main_scaffold_scanner_tab` | PASS |
| 7 | Scanner screen root is targetable: `qr_scanner_screen_root` | PASS |
| 8 | ForgotPasswordController accepts SupabaseClient via constructor (no static SupabaseService.client coupling for tests) | PASS — `ForgotPasswordController({SupabaseClient? client}) : _client = client ?? SupabaseService.client` |
| 9 | Empirical test count of `forgot_password_dialog_test.dart` BEFORE refactor recorded as 6 tests | PASS — `grep -cE 'testWidgets\(...\|^\s*test\(' = 6` and `flutter test = +6 -0` captured in commit `47339ee` + this SUMMARY |
| 10 | CONCERNS.md line 47 corrected | PASS |
| 11 | CLAUDE.md `Testing Implementation Status` 5/13 line corrected | PASS |
| 12 | All references to non-existent `lib/features/auth/presentation/controllers/auth_controller.dart` scrubbed from CLAUDE.md | PASS — `grep -c 'auth_controller' CLAUDE.md = 0` |
| 13 | `flutter analyze` zero errors AND `flutter build apk --debug` + `flutter build ios --debug --no-codesign` both succeed | PASS |

**13/13 must_haves truths verified.**

---

*Phase: 01-foundation-hardening*
*Plan: 06*
*Completed: 2026-05-01*
