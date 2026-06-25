[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$SkillRoot = Split-Path -Parent $PSScriptRoot
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONUTF8 = '1'

$venvPython = Join-Path $SkillRoot '.venv/Scripts/python.exe'
if (Test-Path -LiteralPath $venvPython) {
    $pythonPath = (Get-Item -LiteralPath $venvPython).FullName
}
else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) { $pythonPath = $python.Source }
}
if (-not $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if ($python) { $pythonPath = $python.Source }
}
if (-not $pythonPath) {
    throw 'Python is required to verify insane-search.'
}

Push-Location -LiteralPath $SkillRoot
try {
    & $pythonPath engine/bias_check.py
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $pythonPath -m engine.tests.test_u5
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $pythonPath engine/tests/test_smoke.py
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $wrapper = Join-Path $PSScriptRoot 'insane-search.ps1'
    & $wrapper 'https://example.com/' --selector 'h1' --json --trace --timeout 15 --max-attempts 3 --no-playwright
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
