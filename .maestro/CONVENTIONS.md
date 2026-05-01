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
