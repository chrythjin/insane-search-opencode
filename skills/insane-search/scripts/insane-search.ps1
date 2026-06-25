[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $EngineArgs
)

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
    throw 'Python is required to run insane-search.'
}

Push-Location -LiteralPath $SkillRoot
try {
    & $pythonPath -m engine @EngineArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
