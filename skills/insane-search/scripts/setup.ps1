[CmdletBinding()]
param(
    [switch] $SkipNode
)

$ErrorActionPreference = 'Stop'
$SkillRoot = Split-Path -Parent $PSScriptRoot

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw 'Python is required to set up insane-search.'
}

$venvPath = Join-Path $SkillRoot '.venv'
if (-not (Test-Path -LiteralPath $venvPath)) {
    & $python.Source -m venv $venvPath
}

$venvPython = Join-Path $venvPath 'Scripts/python.exe'
& $venvPython -m pip install -U pip
& $venvPython -m pip install -U 'curl_cffi>=0.15.0' beautifulsoup4 pyyaml yt-dlp

if (-not $SkipNode) {
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if ($npm) {
        & $npm.Source install -g playwright playwright-extra puppeteer-extra-plugin-stealth
        $npx = Get-Command npx -ErrorAction SilentlyContinue
        if ($npx) {
            & $npx.Source playwright install chrome
        }
    }
}

$verifyScript = Join-Path $PSScriptRoot 'verify.ps1'
& $verifyScript
