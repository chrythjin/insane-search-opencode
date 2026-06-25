[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$CloneRoot = $null,

    [Parameter(Mandatory=$false)]
    [switch]$SkipDeploy,

    [Parameter(Mandatory=$false)]
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

# 프로젝트 루트를 scripts/ 하위가 아닌 한 단계 위로 지정
# (BAT/PS1 직접 실행 시 MyInvocation.MyCommand.Path = 스크립트 경로)
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# ── 기본 경로 ──────────────────────────────────────────────
if (-not $CloneRoot) {
    $CloneRoot = Join-Path $ScriptDir "clone\skills\insane-search"
}

$PortedRoot = Join-Path $ScriptDir "skills\insane-search"
$OpenCodeSkills = Join-Path $env:USERPROFILE ".config\opencode\skills\insane-search"

# ── 동기화 대상 ──────────────────────────────────────────────
$SyncItems = @(
    "engine",
    "references",
    "PLATFORMS.md",
    "LICENSE.upstream"
)

# clone/source/engine/ 안에는 engine/ (Python 패키지), templates/, tests/ 가 이미 포함되어 있어
# Recurse 복사 시 함께 딸려 온다. 따라서 SyncExtraDirs 로 별도 복사하면 중첩이 발생한다.
# 결론: $SyncItems = @("engine","references") 만으로 충분하다.

function Write-Step {
    param([string]$Msg)
    Write-Host "[sync] $Msg" -ForegroundColor Cyan
}

function Write-Done {
    param([string]$Msg)
    Write-Host "[done] $Msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "[warn] $Msg" -ForegroundColor Yellow
}

# ── 사전 검사 ────────────────────────────────────────────────
Write-Step "원본: $CloneRoot"
if (-not (Test-Path $CloneRoot)) {
    Write-Warn "원본 디렉토리가 없습니다. '$CloneRoot'"
    Write-Warn "CloneRoot 파라미터로 경로를 지정하거나 clone/ 디렉토리에 원본을 배치하세요."
    exit 1
}

Write-Step "포트: $PortedRoot"
if (-not (Test-Path $PortedRoot)) {
    Write-Warn "포트 디렉토리가 없습니다: $PortedRoot"
    exit 1
}

Write-Step "OpenCode 스킬: $OpenCodeSkills"
if (-not (Test-Path $OpenCodeSkills) -and -not $SkipDeploy) {
    Write-Warn "OpenCode 스킬 디렉토리가 없습니다. --SkipDeploy를 사용하면 건너뜁니다."
}

# ── 1. Clone → Ported 동기화 ────────────────────────────────
Write-Step "=== Clone → Ported 동기화 시작 ==="

foreach ($item in $SyncItems) {
    $src = Join-Path $CloneRoot $item
    $dst = Join-Path $PortedRoot $item

    if (Test-Path $src) {
        if (Test-Path $dst) {
            # 파일이면 내용 비교 후 교체, 디렉토리면 그대로 덮어쓰기
            $srcItem = Get-Item $src
            if ($srcItem.PSIsContainer) {
                Copy-Item -Recurse -Force -LiteralPath $src -Destination $dst
                Write-Done "디렉토리 교체: $item"
            } else {
                $hashSrc = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
                $hashDst = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
                if ($hashSrc -ne $hashDst) {
                    Copy-Item -Force -LiteralPath $src -Destination $dst
                    Write-Done "파일 교체: $item"
                } else {
                    Write-Done "동일 (패스): $item"
                }
            }
        } else {
            # 포트 디렉토리에 없으면 새로 복사
            Copy-Item -Recurse -Force -LiteralPath $src -Destination $dst
            Write-Done "신규 추가: $item"
        }
    } else {
        Write-Warn "원본에 없음 (패스): $item"
    }
}

# engine/, references/ は再帰コピー済므로 서브디렉토리 추가 복사가 불필요
# (clone/skills/insane-search/engine/ 안에는 engine/ 패키지, templates/, tests/ 가 이미 포함)

# ── 2. Ported → OpenCode 배포 ───────────────────────────────
if (-not $SkipDeploy) {
    Write-Step "=== Ported → OpenCode 배포 시작 ==="

    if (-not (Test-Path $OpenCodeSkills)) {
        Write-Warn "OpenCode 스킬 디렉토리가 없습니다. 생성합니다."
        New-Item -ItemType Directory -Path $OpenCodeSkills -Force | Out-Null
    }

    foreach ($item in $SyncItems) {
        $src = Join-Path $PortedRoot $item
        $dst = Join-Path $OpenCodeSkills $item

        if (Test-Path $src) {
            if (Test-Path $dst) {
                $srcItem = Get-Item $src
                if ($srcItem.PSIsContainer) {
                    Copy-Item -Recurse -Force -LiteralPath $src -Destination $dst
                } else {
                    $hashSrc = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
                    $hashDst = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
                    if ($hashSrc -ne $hashDst) {
                        Copy-Item -Force -LiteralPath $src -Destination $dst
                    }
                }
            } else {
                Copy-Item -Recurse -Force -LiteralPath $src -Destination $dst
            }
            Write-Done "배포 완료: $item"
        }
    }

} else {
    Write-Step "배포 단계 건너뜀 (--SkipDeploy)"
}

# ── 3. 검증 ──────────────────────────────────────────────────
if (-not $SkipVerify) {
    Write-Step "=== 검증 시작 ==="
    & "$PortedRoot\scripts\verify.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "검증 실패 (exit code: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
    Write-Done "검증 통과"
} else {
    Write-Step "검증 단계 건너뜀 (--SkipVerify)"
}

Write-Done "업데이트 완료"
