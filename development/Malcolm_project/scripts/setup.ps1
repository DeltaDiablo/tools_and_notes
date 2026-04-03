<#
.SYNOPSIS
    Malcolm setup script for Windows (Docker Desktop + WSL2 backend).

.DESCRIPTION
    Prepares the Docker Desktop / WSL2 environment to run Malcolm.
    Run this once before the first "docker compose up".

    Actions performed:
      1. Verifies Docker Desktop is running
      2. Sets vm.max_map_count=262144 in WSL2 (required by Elasticsearch)
      3. Persists the vm.max_map_count setting across WSL2 restarts
      4. Reminds you to change default passwords in .env
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Malcolm Setup - Windows / Docker Desktop + WSL2" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# -- 1. Verify Docker is running ----------------------------------------------
Write-Host "[1/4] Checking Docker..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker returned exit code $LASTEXITCODE"
    }
    Write-Host "      Docker is running." -ForegroundColor Green
} catch {
    Write-Error "Docker does not appear to be running. Start Docker Desktop and try again."
    exit 1
}

# -- 2. Set vm.max_map_count in active WSL2 instance --------------------------
Write-Host "[2/5] Setting vm.max_map_count=262144 in WSL2 (Elasticsearch requirement)..." -ForegroundColor Yellow
try {
    wsl -e sysctl -w vm.max_map_count=262144 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      vm.max_map_count set successfully." -ForegroundColor Green
    } else {
        Write-Warning "Could not set vm.max_map_count via WSL. Run manually: wsl -e sudo sysctl -w vm.max_map_count=262144"
    }
} catch {
    Write-Warning "WSL command failed. If using Hyper-V backend instead of WSL2, this step can be skipped."
}

# -- 3. Persist vm.max_map_count across WSL2 restarts -------------------------
Write-Host "[3/5] Persisting vm.max_map_count in /etc/sysctl.d/99-malcolm.conf..." -ForegroundColor Yellow
try {
    $sysctlConf = "/etc/sysctl.d/99-malcolm.conf"
    $checkCmd   = "grep -q vm.max_map_count $sysctlConf 2>/dev/null && echo found || echo notfound"
    $result     = wsl -e bash -c $checkCmd 2>&1

    if ($result -match "notfound") {
        wsl -e bash -c "echo vm.max_map_count=262144 | sudo tee $sysctlConf > /dev/null"
        Write-Host "      Persisted to $sysctlConf" -ForegroundColor Green
    } else {
        Write-Host "      Already configured in $sysctlConf" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not persist sysctl setting. Re-run after WSL2 restarts."
}

# -- 4. GitHub Container Registry login (required for Malcolm images) ----------
Write-Host "[4/5] Logging in to ghcr.io for Malcolm images..." -ForegroundColor Yellow
Write-Host "      Malcolm images (Arkime, Zeek, Suricata, etc.) are hosted on"
Write-Host "      ghcr.io/idaholab/malcolm and require a GitHub login."
Write-Host ""
Write-Host "      You need a GitHub Personal Access Token with 'read:packages' scope."
Write-Host "      Create one at: https://github.com/settings/tokens/new"
Write-Host ""
$ghUser = Read-Host "      GitHub username (leave blank to skip)"
if ($ghUser -ne "") {
    $ghToken = Read-Host "      GitHub PAT" -AsSecureString
    $ghTokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ghToken)
    )
    $ghTokenPlain | docker login ghcr.io -u $ghUser --password-stdin 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Logged in to ghcr.io successfully." -ForegroundColor Green
    } else {
        Write-Warning "ghcr.io login failed. Check your username and PAT, then run:"
        Write-Warning "  docker login ghcr.io -u <username>"
    }
} else {
    Write-Warning "Skipped ghcr.io login. Run 'docker login ghcr.io' before pulling images."
}

# -- 5. Check .env passwords --------------------------------------------------
Write-Host "[5/5] Checking .env for default passwords..." -ForegroundColor Yellow
$envFile = Join-Path (Join-Path $PSScriptRoot "..") ".env"
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "changeme") {
        Write-Host ""
        Write-Host "  !! WARNING: .env still contains changeme passwords." -ForegroundColor Red
        Write-Host "  !! Edit .env and replace all changeme values before running: docker compose up" -ForegroundColor Red
        Write-Host ""
    } else {
        Write-Host "      No default passwords detected in .env." -ForegroundColor Green
    }
} else {
    Write-Warning ".env file not found at $envFile - confirm you are running this from the Malcolm_project directory."
}

# -- Done ---------------------------------------------------------------------
Write-Host ""
Write-Host "Setup complete. Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit .env and change all changeme passwords"
Write-Host "  2. Run: docker login ghcr.io -u <github_username>  (if you skipped login above)"
Write-Host "  3. cd Malcolm_project"
Write-Host "  4. docker compose pull"
Write-Host "  5. docker compose up -d"
Write-Host "  6. Open http://localhost after ~5 minutes"
Write-Host ""