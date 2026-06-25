# insane-search OpenCode Port Session

Date: 2026-06-25

## Summary

Ported the cloned `fivetaku/insane-search` Claude Code plugin into an
OpenCode-native skill surface under `skills/insane-search`.

## Changes

- Copied reusable upstream engine, references, tests, platform summary, and
  license into `skills/insane-search`.
- Replaced the Claude-specific `SKILL.md` behavior with OpenCode-oriented usage,
  escalation rules, and verification instructions.
- Added PowerShell wrappers:
  - `scripts/insane-search.ps1`: runs `python -m engine` from the skill root,
    prefers the local `.venv`, and forces UTF-8 output on Windows.
  - `scripts/setup.ps1`: creates a local `.venv`, installs Python dependencies,
    optionally installs Node/Playwright dependencies, then verifies.
  - `scripts/verify.ps1`: runs the bias gate, local regression tests, online
    smoke tests, and wrapper-driven `example.com` fetch.
- Added `README-opencode.md` with install, run, verify, and optional dependency
  instructions.
- Fixed `engine/bias_check.py` Phase 0 allowlist matching so it still works when
  the skill is installed at a different path.

## Verification

Ran `./skills/insane-search/scripts/verify.ps1` successfully:

- `engine/bias_check.py`: clean, scanned 14 files.
- `python -m engine.tests.test_u5`: 14 passed, 0 failed.
- `python engine/tests/test_smoke.py`: 8 passed, 0 failed.
- Wrapper manual QA: `./scripts/insane-search.ps1 https://example.com/ --selector h1 --json --trace --timeout 15 --max-attempts 3 --no-playwright` returned `ok=true`, `verdict=strong_ok`, status 200 through `curl_cffi`.
- Wrapper help surface: `./scripts/insane-search.ps1 --help` rendered engine CLI help.

## Notes

- PowerShell LSP diagnostics could not run because no `.ps1` LSP server is
  configured in this OpenCode environment. Script behavior was verified by
  execution instead.
- Node/Playwright dependencies were not installed because setup was run with
  `-SkipNode`; browser fallback remains documented and optional.

## Global Installation

Installed the completed skill into the user OpenCode skills directory:

`C:\Users\U-N-00658\.config\opencode\skills\insane-search`

After restart verification, the same skill was also installed into the Roaming
OpenCode skills directory to cover both observed Windows skill roots:

`C:\Users\U-N-00658\AppData\Roaming\opencode\skills\insane-search`

Post-install verification from the global path:

- `scripts/insane-search.ps1 --help` rendered the engine CLI help.
- `scripts/insane-search.ps1 https://example.com/ --selector h1 --json --trace --timeout 15 --max-attempts 3 --no-playwright` returned `ok=true`, `verdict=strong_ok`, status 200 through `curl_cffi`.
- Both global copies were verified with `--help` and the `example.com` wrapper
  smoke command. The current session's `triage` MCP still did not match
  `insane-search`, which appears to be a stale skill-router index because the
  installed folder layout matches existing user skills and direct execution
  succeeds from both global roots.
