---
name: insane-search
description: >
  Use when a web page, social post, media page, Korean community, marketplace,
  or WAF-protected URL is blocked, returns 402/403/429, renders only a bot
  challenge, or needs extraction through public APIs, Jina Reader, yt-dlp,
  curl_cffi TLS impersonation, or Playwright escalation. Korean triggers include
  트위터/X 못 열어, 레딧 안 읽혀, 유튜브 자막, 깃헙 검색, 사이트 차단됨,
  네이버 블로그, 디시인사이드, 에펨코리아, 요즘IT, 클리앙, 쿠팡, 링크드인.
  Do not trigger for simple web searches that the normal web search tool can
  answer directly.
---

# Insane Search for OpenCode

Blocked pages are not a signal to improvise with one-off headers. They are a
signal to run the engine and follow its exhaustion gates.

## Entry point

Always run the engine from this skill directory:

```powershell
./scripts/insane-search.ps1 "<URL>" --json --trace
```

Equivalent direct form when already in this directory:

```powershell
python -m engine "<URL>" --json --trace
```

Use `--selector "<CSS>"` when the user gave a target element or when a known
content selector is needed as positive proof. Use `--device auto|desktop|mobile`
only when the page itself requires that context.

## Rules

### R1: Do not bypass the engine for blocked URLs

For a normal web URL that is blocked, challenged, empty, or returns 402/403/429:

1. Do not hand-roll curl headers or declare failure from `webfetch` alone.
2. Run `./scripts/insane-search.ps1 "<URL>" --json --trace`.
3. Judge the result from the engine JSON plus trace, not from HTTP status alone.
4. Retry with `--selector`, `--device`, or a runtime hint only when the trace
   shows why the first route failed.

### R2: HTTP 200 is only the start condition

A `200` response is not success. Success requires the engine validator to return
`strong_ok` or `weak_ok`. Challenge pages, script stubs, tiny bodies, and bot
walls can all be HTTP 200.

### R3: Keep the engine generic

Do not add site domains, brand-specific selectors, or platform branches to
`engine/**` or `engine/waf_profiles.yaml`. Run the bias gate after edits:

```powershell
python engine/bias_check.py
```

The sanctioned exception is `engine/phase0.py`, where public official endpoints
are indexed before the generic WAF grid.

### R4: Site-specific facts are runtime-only

Selectors, preferred referers, internal API URLs, and pagination parameters found
during a session may be passed to a command or used in that live run. Do not
persist them in engine code.

### R5: Phase 0 public APIs first

The engine already checks public routes before the generic grid: Reddit RSS,
X/Twitter syndication and oEmbed, YouTube via `yt-dlp`, Hacker News, arXiv,
GitHub, package registries, and other documented public APIs.

### R6: Failure requires full exhaustion

When the engine returns `ok=false`, inspect these fields before declaring the
page inaccessible:

- `grid_exhausted` must be `true`.
- `untried_routes` must be empty.
- `must_invoke_playwright_mcp` must be `false`, or the agent must run a
  browser/Playwright investigation from the OpenCode session first.
- `stop_reason` must be terminal, such as auth required, not found, or paywall.
  A 429/rate-limit is not terminal.

If `must_invoke_playwright_mcp=true`, use the available OpenCode browser surface:

1. Load the `playwright` or browser QA skill when browser tooling is needed.
2. Navigate to the page in a real browser.
3. Inspect rendered text and network requests.
4. If an internal `/api`, `/graphql`, or `.json` endpoint is found, re-run the
   engine against that endpoint.
5. If no reusable endpoint exists, use the browser-rendered snapshot/content as
   the final evidence.

### R7: For list/collection requests, start API reconnaissance early

When the first attempts show a known WAF challenge and the user asks for a list,
collection, pagination, crawling, or “전부”, do not wait for the full HTML grid
before looking for internal APIs. Keep the engine path running when practical,
but use the browser/network route to find JSON endpoints sooner.

## References

- `references/public-api.md`: public API routes.
- `references/json-api.md`: JSON/RSS route patterns.
- `references/media.md`: `yt-dlp` media and subtitle extraction.
- `references/tls-impersonate.md`: curl_cffi TLS impersonation.
- `references/playwright.md`: browser escalation details.
- `PLATFORMS.md`: platform coverage summary.

## Verification

For first setup inside the skill directory:

```powershell
./scripts/setup.ps1 -SkipNode
```

After changing this skill or engine, run:

```powershell
./scripts/verify.ps1
```

Completion means the bias gate passes, unit-style engine tests pass, and a real
`https://example.com/` engine invocation returns `ok=true` through the wrapper.
