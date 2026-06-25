# Session: insane-search OpenCode port — Windows bias-check path fix

**Date:** 2026-06-25 21:22 KST
**Scope:** bug fix in `engine/bias_check.py` + `.gitignore` update
**Status:** committed (`8150cef`), pushed to `master`

## Context

The `insane-search` skill was ported from the upstream Claude Code plugin
(`clone/skills/insane-search/`) into OpenCode format. Initial verification
(`scripts/verify.ps1`) reported a clean bias-check on Linux but **6 false-positive
violations** on every Windows run:

```
insane-search\engine\phase0.py:63 — hardcoded host `reddit.com`
insane-search\engine\phase0.py:65 — hardcoded host `x.com`
insane-search\engine\phase0.py:67 — hardcoded host `youtube.com`
insane-search\engine\phase0.py:119 — hardcoded host `cdn.syndication.twimg.com`
insane-search\engine\phase0.py:130 — hardcoded host `publish.twitter.com`
insane-search\engine\phase0.py:145 — hardcoded host `syndication.twitter.com`
```

## Root cause

`bias_check.py` exempted `phase0.py` via `EXPLICIT_ALLOW_FILES`, but the lookup
used `str(rel)` where `rel = path.relative_to(root.parent)`. On Windows,
`Path.relative_to()` returns paths with **backslash** separators, while the
allow-list entries use **forward slashes**:

```python
# EXPLICIT_ALLOW_FILES
"insane-search/engine/phase0.py"   # forward slash

# Windows returns
"insane-search\\engine\\phase0.py" # backslash — never matches
```

So the exemption was silently skipped on Windows, and the Phase 0 platform-API
host names (`reddit.com`, `x.com`, etc. — sanctioned by SKILL.md R5) failed
the brand scan.

## Fix

Switch the comparison to `Path.as_posix()` so separators normalize
cross-platform:

```python
- if str(rel) in EXPLICIT_ALLOW_FILES:
+ # Path.as_posix() for forward-slash separator so EXPLICIT_ALLOW_FILES
+ # matches on both Windows (backslash) and POSIX (slash) filesystems.
+ if rel.as_posix() in EXPLICIT_ALLOW_FILES:
```

The fix was applied in **both** locations so `sync-from-clone.ps1` keeps them
in sync:

- `skills/insane-search/engine/bias_check.py` — ported skill (committed)
- `clone/skills/insane-search/engine/bias_check.py` — upstream vendored copy

## Verification

After the fix, `scripts/verify.ps1` reports clean across the full pipeline:

```
[bias-check] scanned 14 files
[bias-check] clean
[roundtrip_lookup] ✓
[wins_increment_same_route] ✓
[wins_reset_on_new_route] ✓
[transient_no_strike] ✓
[real_failure_strike_1] ✓
[evict_after_2_strikes] ✓
[success_resets_strikes] ✓
[classify_real_failures] ✓
[ttl_prunes_stale] ✓
[lru_cap] ✓
[key_scoping] ✓
[priority_moves_to_front] ✓
[winning_route_from_grid] ✓
[winning_route_skips_browser] ✓
[online smoke] ok=true, verdict=strong_ok
```

All three copies (port, clone, OpenCode install) hold identical SHA256 for
`engine/bias_check.py`: `3DFDB5A995481FA279099FE82418A85F798CC8407F0FCFD173C8D7FB619B9254`.

## Secondary changes

- `.gitignore`: added `.serena/` (MCP server cache directory was showing up
  in `git status` after an LSP session).
- No more `# NOTE-BIAS-OK` comments needed in `phase0.py` because
  `EXPLICIT_ALLOW_FILES` covers the whole file. Earlier adding the
  per-line comments was redundant defense — the real bug was the path
  separator comparison.

## Files touched

- `skills/insane-search/engine/bias_check.py` (1 line changed + 2 comment lines)
- `clone/skills/insane-search/engine/bias_check.py` (same, kept in sync)
- `.gitignore` (+1 line: `.serena/`)

## Not verified / out of scope

- Did not push the upstream fix to `fivetaku/insane-search` — clone is local-only.
- `phase0.py` `NOTE-BIAS-OK` comments that were wiped by sync are
  intentionally **not** re-added; the file-level exemption is the correct
  mechanism (and is now working on Windows).
- UTF-8 console encoding: PowerShell still shows `??` for Korean / emoji
  output from `sync-from-clone.ps1`. Cosmetic only — does not affect
  script behavior. Fix deferred (would require `chcp 65001` in the wrapper).