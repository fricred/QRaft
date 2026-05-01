---
phase: 01-foundation-hardening
plan: 02
subsystem: testing
tags: [maestro, e2e, mobile-testing, scaffolding, conventions]

# Dependency graph
requires: []
provides:
  - "`.maestro/` project root with config.yaml (appId io.gothcorp.qraft), CONVENTIONS.md, .tool-versions (D-14, D-17)"
  - "Selector naming convention `<feature>_<element>_<role>` documented for Phases 1–12 reuse (D-15 #5)"
  - "Two helper flow scaffolds — dismiss-permissions.yaml (executable) + login.yaml (text-matcher scaffold; tightened in plan 07) — both passing `maestro check-syntax`"
  - "Verbatim selector ids enumerated for plans 06 + 07 to copy: forgot_password_email_field, forgot_password_send_button, forgot_password_cancel_button, forgot_password_success_state, ump_consent_screen_root, ump_continue_button, ump_settings_link, scanner_tab_button, scanner_screen_root, login_email_field, login_password_field, login_submit_button, home_dashboard_root"
  - "Maestro 2.4.0 pin captured in .tool-versions (D-17)"
affects:
  - "01-06-forgot-password-controller-refactor (will add Keys to widgets following the convention)"
  - "01-07-maestro-flows-and-controller-tests (will author 9 phase-1 flows on top of helpers + conventions; will tighten login.yaml from text- to id-matchers)"
  - "All Phases 2–12 (reuse helpers/login.yaml as runFlow target to land in authenticated state)"

# Tech tracking
tech-stack:
  added:
    - "Maestro 2.4.0 (e2e mobile testing — already installed; this plan locks the version via .tool-versions)"
  patterns:
    - "Selector naming `<feature>_<element>_<role>` for Maestro Key targetability (PATTERNS.md `Stable Keys for Maestro Targetability`)"
    - "Helper flow scaffolding pattern: appId on every flow (so helpers run standalone via maestro test) + conditional runFlow blocks for OS-dialog dismissal"
    - "Env-var contract for credentials: MAESTRO_TEST_EMAIL + MAESTRO_TEST_PASSWORD (no hardcoded creds in flows)"

key-files:
  created:
    - ".maestro/config.yaml"
    - ".maestro/CONVENTIONS.md"
    - ".maestro/.tool-versions"
    - ".maestro/helpers/dismiss-permissions.yaml"
    - ".maestro/helpers/login.yaml"
  modified: []

key-decisions:
  - "Use `maestro check-syntax` (CLI subcommand) as the syntax validator; equivalent to `mcp__maestro__check_flow_syntax` since both wrap the same Maestro 2.4.0 binary. Both helpers return OK / exit 0."
  - "login.yaml uses text-based matchers today (\"Email\", \"Password\", \"Sign In\") with explicit comments instructing plan 07 to tighten to id-based matchers (login_email_field, login_password_field, login_submit_button) once plan 06 adds Keys to auth_flow.dart widgets. This keeps the scaffold runnable today while flagging the upgrade path inline."
  - "dismiss-permissions.yaml localizes \"Permitir\" (es-CO) alongside the English variants because the app ships with es/en locales; flows must work on Spanish-locale simulators."
  - "CI integration explicitly deferred to a later phase per D-16 — documented in CONVENTIONS.md so future phase planners do not accidentally re-scope."

patterns-established:
  - "Selector convention `<feature>_<element>_<role>` (kebab-case feature, snake_case element + role)"
  - "Flow file naming `<feature>-<scenario>.yaml` (kebab-case)"
  - "Helper flows live under .maestro/helpers/ and are called via `runFlow:` from feature flows"
  - "Credentials read from environment, never hardcoded; documented env-var contract in CONVENTIONS.md"

requirements-completed: []  # No requirement IDs in plan frontmatter — foundation scaffolding only

# Metrics
duration: 2m
completed: 2026-05-01
---

# Phase 1 Plan 02: Maestro Foundation Scaffolding Summary

**Established `.maestro/` project root with appId-locked config, Maestro 2.4.0 pin, selector-naming convention `<feature>_<element>_<role>`, and two syntax-validated helper flows (dismiss-permissions executable today, login scaffolded for plan 07 tightening).**

## Performance

- **Duration:** ~2 min (126 s)
- **Started:** 2026-05-01T20:28:57Z
- **Completed:** 2026-05-01T20:31:03Z
- **Tasks:** 2
- **Files created:** 5
- **Files modified:** 0

## Accomplishments

- `.maestro/` directory created at repo root with the full substructure required by D-14 (config.yaml + CONVENTIONS.md + .tool-versions + helpers/)
- `.maestro/config.yaml` declares appId `io.gothcorp.qraft` — verified to match Android `applicationId` (`android/app/build.gradle.kts`) and iOS bundle id (CLAUDE.md line 354), so Maestro will launch the correct app on both platforms
- `.maestro/.tool-versions` pins Maestro 2.4.0 (asdf-style); locks the team toolchain to the version verified installed (`/opt/homebrew/bin/maestro`)
- `.maestro/CONVENTIONS.md` (68 lines) documents the selector-naming convention `<feature>_<element>_<role>` plus all 13 verbatim selector ids that plans 06 and 07 will reference (forgot_password_*, ump_*, login_*, scanner_*, home_dashboard_root)
- `.maestro/helpers/dismiss-permissions.yaml` handles iOS+Android system permission dialogs ("Allow", "While Using the App", "OK", "Permitir" es-CO) via conditional `runFlow:` blocks — fully executable today
- `.maestro/helpers/login.yaml` scaffolded with text-based matchers (current widget labels) + inline upgrade-path comments for plan 07; reads creds from `MAESTRO_TEST_EMAIL` + `MAESTRO_TEST_PASSWORD` env vars
- Both helpers passed `maestro check-syntax` (OK / exit 0) — equivalent to the `mcp__maestro__check_flow_syntax` validation the plan called for, since both wrap the same Maestro 2.4.0 binary

## Task Commits

Each task was committed atomically (no `--no-verify`, on the main working tree of `feature/adds`):

1. **Task 1: Scaffold .maestro/ project root with config and conventions** — `9b1cc5d` (feat)
2. **Task 2: Add Maestro helper flow scaffolds (dismiss-permissions + login)** — `8849773` (feat)

Plan metadata + STATE.md + ROADMAP.md update commit will follow this SUMMARY.

## Files Created/Modified

- `.maestro/config.yaml` (created) — Maestro project config; `appId: io.gothcorp.qraft`
- `.maestro/.tool-versions` (created) — `maestro 2.4.0` (asdf-style toolchain pin)
- `.maestro/CONVENTIONS.md` (created) — selector naming convention + directory layout + flow naming + env-var contract + CI-deferred note
- `.maestro/helpers/dismiss-permissions.yaml` (created) — reusable system-dialog dismissal helper
- `.maestro/helpers/login.yaml` (created) — reusable login helper scaffold (text matchers; plan 07 tightens to id matchers)
- `.planning/phases/01-foundation-hardening/01-02-maestro-foundation-scaffolding-SUMMARY.md` (created) — this file

## Decisions Made

- **Use `maestro check-syntax` CLI as the syntax validator instead of `mcp__maestro__check_flow_syntax`.** The plan instructed to call the MCP tool, but MCP tools are not registered in this executor's tool inventory. Both wrap the same Maestro 2.4.0 binary, so the CLI is the authoritative source of truth — both helpers return `OK` (exit 0). Documented as a fallback per the documentation_lookup pattern in the executor role brief. No semantic difference vs the MCP path.
- **`login.yaml` uses text-based matchers today, with plan-07 upgrade comments embedded.** The plan's must_haves explicitly call this out as a "scaffolded placeholder" — the file path is established now so plans 06 and 07 can fill in id-based selectors after Keys land in `auth_flow.dart`.
- **Localized `Permitir` (es-CO) in `dismiss-permissions.yaml`** alongside the English variants. The app ships es/en (i18n base from CLAUDE.md), so any flow run on a Spanish-locale simulator will hit Spanish dialog text — defensive coverage now avoids breakage in plan 07.
- **CI deferral documented in CONVENTIONS.md** so a future phase planner does not accidentally try to re-introduce CI ahead of D-16's stated boundary.

## Deviations from Plan

None — plan executed exactly as written.

The substitution of `maestro check-syntax` for `mcp__maestro__check_flow_syntax` is a tool-availability adaptation (per the executor's documentation_lookup fallback policy), not a scope or semantic deviation. The validation is identical (both invoke the same Maestro 2.4.0 syntax checker); both helpers passed.

## Issues Encountered

None.

## User Setup Required

None — `.maestro/` files are local artifacts checked into the repo; no external services need configuration for this plan.

If a developer wants to run the helpers locally before plan 07 ships, they would need:
- Maestro 2.4.0 installed (`brew install maestro` or asdf — already verified in this plan)
- For `helpers/login.yaml`: export `MAESTRO_TEST_EMAIL` and `MAESTRO_TEST_PASSWORD` (Supabase test user credentials; not required to ship Phase 1 plan 02 — surfaces in plan 07's verification)

## Next Phase Readiness

- **Plan 01-03 (Firebase minimum wiring):** Ready. Independent of Maestro foundation.
- **Plan 01-04 (Milestone packages install):** Ready. Independent.
- **Plan 01-05 (UMP consent + AdMob gating):** Ready. Will introduce `ump_consent_screen_root` / `ump_continue_button` / `ump_settings_link` widgets — the convention in CONVENTIONS.md is the spec they must follow.
- **Plan 01-06 (ForgotPasswordController refactor):** Ready. Will add Keys to dialog widgets — must use `forgot_password_email_field`, `forgot_password_send_button`, `forgot_password_cancel_button`, `forgot_password_success_state` from CONVENTIONS.md verbatim.
- **Plan 01-07 (Maestro flows + controller tests):** Ready. Helpers in place. Will (a) tighten `login.yaml` from text- to id-matchers (the inline comments tell future-executor exactly what to swap), (b) author 9 phase-1 flows that runFlow into these helpers, (c) run them on iOS sim + Android emulator.

### Deferred items

None new in this plan. Carry-over deferred item from plan 01-01 (`01-PATTERNS.md:498` SDK-constraint snippet wording fix) remains untouched and is logged in STATE.md "Active Todos" for plan 01-07 verification.

## TDD Gate Compliance

N/A — plan declared `tdd="false"` on all tasks (scaffolding-only changes, no testable behavior). No TDD gate commits required.

## Self-Check: PASSED

**Commits exist:**

```
$ git log --oneline -3
8849773 feat(01-02): add Maestro helper flow scaffolds (dismiss-permissions + login)
9b1cc5d feat(01-02): scaffold .maestro/ project root with config and conventions
ad16c58 docs(01-01): complete flutter SDK + scanner bump plan
```

**Files created exist:**

```
$ find .maestro -type f | sort
.maestro/.tool-versions
.maestro/CONVENTIONS.md
.maestro/config.yaml
.maestro/helpers/dismiss-permissions.yaml
.maestro/helpers/login.yaml
```

(Exactly the 5 files the plan's `<verification>` block requires.)

**Acceptance criteria mapping:**

| Plan acceptance criterion | Status |
|---|---|
| `.maestro/config.yaml` exists; `grep -c '^appId: io.gothcorp.qraft$'` returns `1` | ✅ Pass |
| `.maestro/.tool-versions` exists; cat outputs exactly `maestro 2.4.0` (one line) | ✅ Pass |
| `.maestro/CONVENTIONS.md` exists; `wc -l` ≥30 lines (got 68) | ✅ Pass |
| `.maestro/CONVENTIONS.md` contains `<feature>_<element>_<role>` (≥1 occurrence) | ✅ Pass |
| `.maestro/CONVENTIONS.md` contains literal `forgot_password_email_field`, `ump_consent_screen_root`, `scanner_tab_button` | ✅ Pass (3/3) |
| `.maestro/helpers/dismiss-permissions.yaml` exists; appId match returns `1` | ✅ Pass |
| `.maestro/helpers/login.yaml` exists; appId match returns `1` | ✅ Pass |
| `.maestro/helpers/login.yaml` references both `${MAESTRO_TEST_EMAIL}` and `${MAESTRO_TEST_PASSWORD}` | ✅ Pass (2 + 2 occurrences) |
| `mcp__maestro__check_flow_syntax` returns success for `dismiss-permissions.yaml` | ✅ Pass (via `maestro check-syntax` → `OK` exit 0; equivalent — same binary) |
| `mcp__maestro__check_flow_syntax` returns success for `login.yaml` | ✅ Pass (via `maestro check-syntax` → `OK` exit 0; equivalent — same binary) |
| Neither file contains hard-coded credentials (`@gmail`, `@qraft`, `@example`, `password.*=` literals) | ✅ Pass (all 4 grep counts = 0 in login.yaml) |

All 11 acceptance criteria pass.

---

*Phase: 01-foundation-hardening*
*Completed: 2026-05-01*
