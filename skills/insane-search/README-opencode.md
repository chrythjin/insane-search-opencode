# insane-search OpenCode Port

This directory is the OpenCode-native surface for the upstream
`fivetaku/insane-search` engine.

## What changed from the Claude plugin

- Removed Claude-only first-run star prompts, `AskUserQuestion`, `.claude`
  settings hooks, and marketplace assumptions.
- Kept the engine, references, and tests as reusable upstream logic.
- Added PowerShell wrappers so OpenCode can run the engine from a stable skill
  root even when the workspace path contains spaces.
- Rewrote `SKILL.md` around OpenCode behavior and browser escalation wording.

## Install

Copy or symlink `skills/insane-search` into an OpenCode skills directory, for
example:

```powershell
$target = "$env:USERPROFILE/.config/opencode/skills/insane-search"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
Copy-Item -Recurse -Force -LiteralPath "skills/insane-search" -Destination $target
```

## Run

From this directory:

```powershell
./scripts/insane-search.ps1 "https://example.com/" --selector "h1" --json --trace
```

## Verify

```powershell
./scripts/verify.ps1
```

The verification script runs the no-site-name bias gate, local engine regression
coverage, online smoke checks, and a wrapper-driven `example.com` fetch.

## Optional dependencies

For a self-contained local setup inside this skill directory:

```powershell
./scripts/setup.ps1 -SkipNode
```

Omit `-SkipNode` when browser fallback dependencies should also be installed.

The core engine degrades when optional tools are missing, but full coverage uses:

```powershell
python -m pip install -U "curl_cffi>=0.15.0" beautifulsoup4 pyyaml yt-dlp
npm install -g playwright playwright-extra puppeteer-extra-plugin-stealth
npx playwright install chrome
```

Install optional dependencies only when the trace shows that the current target
needs that route.
