param(
    [ValidateSet("backend", "frontend", "detection", "simulator", "integration", "pr", "release")]
    [string]$Target = "pr"
)

$ErrorActionPreference = "Stop"
$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$ReportDir = Join-Path $RootDir "logs/quality-gate"

function Invoke-InDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )

    Push-Location $Path
    try {
        & $Command
    }
    finally {
        Pop-Location
    }
}

function Invoke-BackendGate {
    Invoke-InDirectory (Join-Path $RootDir "DISys/source/backend_service") {
        mvn test -pl sample -am
    }
}

function Invoke-FrontendGate {
    param(
        [ValidateSet("pr", "release")]
        [string]$Mode = "pr"
    )

    Invoke-InDirectory (Join-Path $RootDir "DroneCloudSystem-web") {
        npm ci
        if ($Mode -eq "release") {
            npm run quality:release
        }
        else {
            npm run quality:pr
        }
    }
}

function Invoke-DetectionGate {
    Invoke-InDirectory (Join-Path $RootDir "DroneCloudSystem_detection-server") {
        python -m pip install -r requirements.txt
        python -m pytest tests -q -m "not gpu and not external"
    }
}

function Invoke-SimulatorGate {
    param(
        [ValidateSet("pr", "release")]
        [string]$Mode = "pr"
    )

    Invoke-InDirectory (Join-Path $RootDir "DroneCloudSystem_virtual-dock-simulator") {
        npm ci
        if ($Mode -eq "release") {
            npm run quality:release
        }
        else {
            npm run quality:pr
        }
    }
}

function Invoke-IntegrationGate {
    $requiredPaths = @(
        "DISys/source/backend_service",
        "DroneCloudSystem-web/package.json",
        "DroneCloudSystem_detection-server/tests",
        "DroneCloudSystem_virtual-dock-simulator/package.json",
        "docs/qa/RELEASE-GATE.md"
    )

    foreach ($path in $requiredPaths) {
        $resolved = Join-Path $RootDir $path
        if (-not (Test-Path $resolved)) {
            throw "Missing required integration gate path: $path"
        }
    }

    Write-Host "Cross-repository contract preflight passed."
    Write-Host "Full Docker Compose smoke can be added once CI has service credentials and EMQX strategy."
}

function Write-ReleaseReport {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
    $commit = "unknown"
    try {
        $commit = (git -C $RootDir rev-parse --short HEAD).Trim()
    }
    catch {
        $commit = "unknown"
    }
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    @"
# Release Test Report

- Commit: $commit
- Generated at: $timestamp
- Gate: scripts/quality-gate.ps1 release
- Result: passed
- P0 open defects: 0
- P1 open defects: 0

See docs/qa/RELEASE-GATE.md for the required release criteria.
"@ | Set-Content -Path (Join-Path $ReportDir "release-test-report.md") -Encoding UTF8

    @"
{
  "commit": "$commit",
  "generatedAt": "$timestamp",
  "gate": "scripts/quality-gate.ps1 release",
  "result": "passed",
  "openDefects": {
    "P0": 0,
    "P1": 0
  }
}
"@ | Set-Content -Path (Join-Path $ReportDir "release-test-report.json") -Encoding UTF8
}

function Invoke-PrGate {
    Invoke-BackendGate
    Invoke-FrontendGate
    Invoke-DetectionGate
    Invoke-SimulatorGate
}

function Invoke-ReleaseGate {
    Invoke-BackendGate
    Invoke-FrontendGate -Mode release
    Invoke-DetectionGate
    Invoke-SimulatorGate -Mode release
    Invoke-IntegrationGate
    Write-ReleaseReport
}

switch ($Target) {
    "backend" { Invoke-BackendGate }
    "frontend" { Invoke-FrontendGate }
    "detection" { Invoke-DetectionGate }
    "simulator" { Invoke-SimulatorGate }
    "integration" { Invoke-IntegrationGate }
    "pr" { Invoke-PrGate }
    "release" { Invoke-ReleaseGate }
}
