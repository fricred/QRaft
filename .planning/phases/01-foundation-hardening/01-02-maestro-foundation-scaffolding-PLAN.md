---
phase: 01-foundation-hardening
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - .maestro/config.yaml
  - .maestro/CONVENTIONS.md
  - .maestro/.tool-versions
  - .maestro/helpers/dismiss-permissions.yaml
  - .maestro/helpers/login.yaml
autonomous: true
requirements: []
must_haves:
  truths:
    - "`.maestro/` directory exists at repo root with the substructure: config.yaml, CONVENTIONS.md, .tool-versions, helpers/ (D-14)"
    - "`.maestro/config.yaml` declares appId `io.gothcorp.qraft` (matches Android package name from `android/app/src/main/AndroidManifest.xml` and iOS bundle id)"
    - "`.maestro/.tool-versions` pins `maestro 2.4.0` (D-17 — already-installed version, locking team to ≥2.4.0)"
    - "`.maestro/CONVENTIONS.md` documents the selector naming convention `<feature>_<element>_<role>` (D-15, PATTERNS.md `Stable Keys for Maestro Targetability`)"
    - "Two helper flows exist as scaffolds: `helpers/dismiss-permissions.yaml` and `helpers/login.yaml` (D-15 #5 — reusable for Phases 2–12)"
    - "`mcp__maestro__check_flow_syntax` validates each helper flow file with no errors"
    - "Login helper is a scaffolded placeholder (commented `runFlow:` target) — actual login selectors are wired up in plan 06 once `auth_flow.dart` widgets get stable Keys; this plan establishes the file path so plan 06 and plan 07 can fill it in"
  artifacts:
    - path: ".maestro/config.yaml"
      provides: "Maestro project config with appId"
      contains: "appId: io.gothcorp.qraft"
    - path: ".maestro/CONVENTIONS.md"
      provides: "Selector + flow naming convention for Phases 1–12 reuse"
      min_lines: 30
    - path: ".maestro/.tool-versions"
      provides: "Pin Maestro 2.4.0 (asdf-style toolchain marker)"
      contains: "maestro 2.4.0"
    - path: ".maestro/helpers/dismiss-permissions.yaml"
      provides: "Reusable helper to dismiss iOS+Android system permission dialogs"
      contains: "appId: io.gothcorp.qraft"
    - path: ".maestro/helpers/login.yaml"
      provides: "Reusable helper to authenticate test user (scaffold; selectors filled by plan 06)"
      contains: "appId: io.gothcorp.qraft"
  key_links:
    - from: ".maestro/config.yaml appId"
      to: "android/app/build.gradle.kts applicationId + ios/Runner bundle id"
      via: "Maestro launches the app by id; mismatch → flows fail to launch"
      pattern: "appId:\\s*io\\.gothcorp\\.qraft"
    - from: ".maestro/CONVENTIONS.md selector convention"
      to: "Plan 06 ForgotPasswordDialog Key additions"
      via: "Plan 06 adds Keys following <feature>_<element>_<role> from this convention doc"
      pattern: "<feature>_<element>_<role>"
---

<objective>
Establish the `.maestro/` foundation: project config, convention doc, version pin, and two scaffolded helper flows. NO test flows authored yet (those land in plan 07 after the widgets they target have stable Keys added in plan 06). This plan creates the empty trellis that Phases 2–12 will hang test flows on.

Purpose: D-14 mandates a Maestro foundation in Phase 1 designed for reuse by Phases 2–12. D-17 confirms Maestro 2.4.0 is already installed (no install task) and the `mcp__maestro__check_flow_syntax` tool is available for validation. D-15 enumerates 9 flows to author later — those land in plan 07. This plan builds only the directory structure, config, conventions, and helper scaffolds that the later flows will reference via `runFlow:`.

Output: `.maestro/` directory with 5 files committed, all helpers passing `mcp__maestro__check_flow_syntax`.
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

<external_docs>
- Maestro project config: https://maestro.mobile.dev/cli/configuration
- Maestro flow YAML reference: https://maestro.mobile.dev/api-reference/commands
- Use `mcp__maestro__query_docs` if syntax questions arise during execution.
- Use `mcp__maestro__check_flow_syntax` after writing each YAML file to validate.
</external_docs>

<interfaces>
<!-- The Android package name and iOS bundle id that Maestro will launch. -->
<!-- Source: android/app/src/main/AndroidManifest.xml line 1 (package="io.gothcorp.qraft") and ios bundle id (CLAUDE.md line 354). -->

appId: io.gothcorp.qraft
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create .maestro/ directory with config.yaml, CONVENTIONS.md, and .tool-versions</name>
  <files>.maestro/config.yaml, .maestro/CONVENTIONS.md, .maestro/.tool-versions</files>
  <read_first>
    - .planning/phases/01-foundation-hardening/01-CONTEXT.md (D-14 — foundation requirements; D-17 — Maestro 2.4.0 pin)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md (lines 569–582 — config.yaml expected shape; lines 832–852 — Stable Keys naming convention)
    - android/app/src/main/AndroidManifest.xml (confirm package="io.gothcorp.qraft")
  </read_first>
  <action>
Create three new files at exact paths.

**File 1: `.maestro/config.yaml`** — Maestro project config. Content:
```yaml
# QRaft Maestro project config
# Pin: Maestro 2.4.0+ (verified installed at /opt/homebrew/bin/maestro per D-17)
# Phase 1 establishes this foundation; Phases 2–12 extend with feature-specific flows.
appId: io.gothcorp.qraft
```

**File 2: `.maestro/.tool-versions`** — asdf-style toolchain pin (per D-17). Content:
```
maestro 2.4.0
```

**File 3: `.maestro/CONVENTIONS.md`** — Convention doc the team follows when authoring flows (per D-15 #5 reusability mandate + PATTERNS.md "Stable Keys" section). Content:
```markdown
# Maestro Conventions for QRaft

## Directory Layout

- `.maestro/config.yaml` — project config (appId, defaults).
- `.maestro/.tool-versions` — Maestro version pin (asdf-style).
- `.maestro/helpers/` — reusable flows imported by feature flows via `runFlow:`.
- `.maestro/auth/` — auth flows (login-valid, login-invalid, logout, forgot-password, session-persistence).
- `.maestro/launch/` — app-launch flows (splash, ump-accept, ump-deny-npa).
- `.maestro/scanner/` — scanner-tab-launch and Phase 3+ scanner flows.
- Future phases extend with `.maestro/<feature>/` directories.

## Flow File Naming

`<feature>-<scenario>.yaml` (kebab-case). Example: `auth/login-valid.yaml`, `launch/ump-accept.yaml`.

## Selector Convention

Widgets that Maestro must locate get a stable `Key` named:

`<feature>_<element>_<role>`

Examples:
- `login_email_field`
- `login_password_field`
- `login_submit_button`
- `forgot_password_email_field`
- `forgot_password_send_button`
- `forgot_password_cancel_button`
- `forgot_password_success_state`
- `ump_consent_screen_root`
- `ump_continue_button`
- `ump_settings_link`
- `scanner_tab_button`
- `scanner_screen_root`
- `home_dashboard_root`

Use `id:` matchers in flows. When a system dialog or third-party UI (Google's UMP form) is involved, fall back to `text:` matchers on the localized button text.

## Helpers (reusable via `runFlow:`)

- `helpers/dismiss-permissions.yaml` — handle iOS+Android system permission dialogs.
- `helpers/login.yaml` — perform a known-good login (uses `MAESTRO_TEST_EMAIL` + `MAESTRO_TEST_PASSWORD` env vars).

## Environment Variables

Flows that need credentials read from environment:
- `MAESTRO_TEST_EMAIL` — valid test user email.
- `MAESTRO_TEST_PASSWORD` — valid test user password.

Set in shell or `.env` (gitignored) before running `maestro test`.

## Local Run

```bash
# All flows
maestro test .maestro/

# Single flow
maestro test .maestro/auth/login-valid.yaml

# Specific platform target via maestro env
MAESTRO_PLATFORM=ios maestro test .maestro/launch/ump-accept.yaml
```

## CI

CI integration is **deferred** (D-16). Phase 1 keeps Maestro local-only on developer machines. CI runner setup belongs in a later phase (likely Phase 12 OPT-03 observability or a dedicated infra phase).
```

This convention doc is the single source of truth for selector naming. Plan 06 (ForgotPasswordController refactor) MUST add Keys following this convention. Plan 07 (Maestro flows) MUST reference these selector ids in flow YAML.
  </action>
  <verify>
    <automated>test -f .maestro/config.yaml &amp;&amp; test -f .maestro/CONVENTIONS.md &amp;&amp; test -f .maestro/.tool-versions &amp;&amp; grep -q 'appId: io.gothcorp.qraft' .maestro/config.yaml &amp;&amp; grep -q 'maestro 2.4.0' .maestro/.tool-versions &amp;&amp; grep -q '&lt;feature&gt;_&lt;element&gt;_&lt;role&gt;' .maestro/CONVENTIONS.md</automated>
  </verify>
  <acceptance_criteria>
    - `.maestro/config.yaml` exists; `grep -c '^appId: io.gothcorp.qraft$' .maestro/config.yaml` returns `1`.
    - `.maestro/.tool-versions` exists; `cat .maestro/.tool-versions` outputs exactly `maestro 2.4.0` (one line).
    - `.maestro/CONVENTIONS.md` exists; `wc -l .maestro/CONVENTIONS.md` returns ≥30 lines; `grep -c '<feature>_<element>_<role>' .maestro/CONVENTIONS.md` returns ≥1.
    - `.maestro/CONVENTIONS.md` contains the literal lines `forgot_password_email_field`, `ump_consent_screen_root`, `scanner_tab_button` (executors of plans 06 and 07 will copy these names verbatim).
  </acceptance_criteria>
  <done>Three foundation files exist with correct content; Phase 2+ flows can reference these conventions. Per D-14, D-15, D-17.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create reusable helper flow scaffolds and validate syntax</name>
  <files>.maestro/helpers/dismiss-permissions.yaml, .maestro/helpers/login.yaml</files>
  <read_first>
    - .maestro/CONVENTIONS.md (created in Task 1 — selector naming + helper documentation)
    - .planning/phases/01-foundation-hardening/01-PATTERNS.md (lines 588–613 — Maestro flow YAML pattern; D-15 #5 reusability note)
  </read_first>
  <action>
Create two helper flow files. Both are intentional scaffolds — `dismiss-permissions.yaml` is fully executable on Day 1, `login.yaml` is a scaffold whose selectors get filled by plan 06 (which adds the Keys to `auth_flow.dart` widgets). Plan 07 will then expand `login.yaml` once Keys exist.

**File 1: `.maestro/helpers/dismiss-permissions.yaml`** — handles iOS + Android system permission dialogs (camera, location, contacts) that may appear on first launch. Content:
```yaml
# Helper: dismiss-permissions.yaml
# Purpose: tap "Allow" / "OK" on iOS+Android system permission dialogs that may appear on first launch.
# Used by: any flow that triggers permission requests (scanner tab, location QR, contacts).
# This handles the OS-level dialog, NOT the Flutter rationale UI.

appId: io.gothcorp.qraft
---
- runFlow:
    when:
      visible:
        text: "Allow"
    commands:
      - tapOn: "Allow"
- runFlow:
    when:
      visible:
        text: "While Using the App"
    commands:
      - tapOn: "While Using the App"
- runFlow:
    when:
      visible:
        text: "OK"
    commands:
      - tapOn: "OK"
- runFlow:
    when:
      visible:
        text: "Permitir"  # es-CO localized variant
    commands:
      - tapOn: "Permitir"
```

**File 2: `.maestro/helpers/login.yaml`** — scaffolded reusable login flow. Selector ids will be wired by plan 07 once plan 06 adds Keys to `auth_flow.dart` widgets. For Phase 1, write a working scaffold using `text:` matchers on existing labels so the flow is functional today and gets tightened (to `id:` matchers) in plan 07.

Content:
```yaml
# Helper: login.yaml
# Purpose: authenticate as a known test user. Reused by Phases 2–12 to land in authenticated state.
# Selectors: text-based today (existing labels); plan 07 tightens to id-based once plan 06 adds Keys.
# Env vars required: MAESTRO_TEST_EMAIL, MAESTRO_TEST_PASSWORD.

appId: io.gothcorp.qraft
---
# NOTE: this scaffold uses text matchers because Keys are added in plan 06.
# Plan 07 should switch the matchers below to:
#   - tapOn: { id: login_email_field }
#   - tapOn: { id: login_password_field }
#   - tapOn: { id: login_submit_button }
- tapOn:
    text: "Email"
- inputText: ${MAESTRO_TEST_EMAIL}
- tapOn:
    text: "Password"
- inputText: ${MAESTRO_TEST_PASSWORD}
- hideKeyboard
- tapOn:
    text: "Sign In"
```

After both files are written, validate each one using the Maestro MCP tool:
```
mcp__maestro__check_flow_syntax({ flow_path: ".maestro/helpers/dismiss-permissions.yaml" })
mcp__maestro__check_flow_syntax({ flow_path: ".maestro/helpers/login.yaml" })
```

Both calls MUST return success (no syntax errors). If either reports an error, fix before proceeding — do not commit invalid YAML.
  </action>
  <verify>
    <automated>test -f .maestro/helpers/dismiss-permissions.yaml &amp;&amp; test -f .maestro/helpers/login.yaml &amp;&amp; grep -q 'appId: io.gothcorp.qraft' .maestro/helpers/dismiss-permissions.yaml &amp;&amp; grep -q 'appId: io.gothcorp.qraft' .maestro/helpers/login.yaml &amp;&amp; grep -q 'MAESTRO_TEST_EMAIL' .maestro/helpers/login.yaml</automated>
  </verify>
  <acceptance_criteria>
    - `.maestro/helpers/dismiss-permissions.yaml` exists; `grep -c '^appId: io.gothcorp.qraft$' .maestro/helpers/dismiss-permissions.yaml` returns `1`.
    - `.maestro/helpers/login.yaml` exists; `grep -c '^appId: io.gothcorp.qraft$' .maestro/helpers/login.yaml` returns `1`.
    - `.maestro/helpers/login.yaml` references both `${MAESTRO_TEST_EMAIL}` and `${MAESTRO_TEST_PASSWORD}` (grep returns ≥1 for each).
    - `mcp__maestro__check_flow_syntax` returns success for `.maestro/helpers/dismiss-permissions.yaml`.
    - `mcp__maestro__check_flow_syntax` returns success for `.maestro/helpers/login.yaml`.
    - Neither file contains hard-coded credentials (grep returns 0 for `password.*=` and `@gmail`, `@qraft`, `@example` literals).
  </acceptance_criteria>
  <done>Both helpers exist, syntax-validated by `mcp__maestro__check_flow_syntax`, parameterized via env vars. Per D-15 #5 reusability mandate.</done>
</task>

</tasks>

<verification>
After both tasks:
- `find .maestro -type f | sort` lists exactly 5 files: `config.yaml`, `CONVENTIONS.md`, `.tool-versions`, `helpers/dismiss-permissions.yaml`, `helpers/login.yaml`.
- All YAML files pass `mcp__maestro__check_flow_syntax`.
- Convention doc enumerates selector ids that plans 06 and 07 will use verbatim.
</verification>

<success_criteria>
1. `.maestro/` foundation exists with config, conventions, version pin, and 2 helper scaffolds (D-14).
2. Maestro 2.4.0 pinned in `.tool-versions` (D-17).
3. Selector naming convention `<feature>_<element>_<role>` documented for cross-phase reuse (D-15 #5).
4. CI integration explicitly NOT in scope — documented as deferred in CONVENTIONS.md (D-16).
5. Both helper flows pass `mcp__maestro__check_flow_syntax`.
6. No new code dependencies introduced (this plan touches only `.maestro/` — pubspec.yaml is untouched, plans 03/04 own pubspec).
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-hardening/01-02-SUMMARY.md` capturing:
- The 5 files created (paths + brief role).
- Maestro version verified (`maestro --version` output).
- `mcp__maestro__check_flow_syntax` results for both helpers.
- Convention selector ids that downstream plans (06, 07) MUST use.
- Note: actual flow authoring deferred to plan 07 once plan 06 adds widget Keys.
</output>
