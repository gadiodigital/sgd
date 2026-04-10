param(
    [int]$TempRestoreIterations = 1,
    [int]$StackReprovisionIterations = 1,
    [switch]$SkipCapacityChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-PowerShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ArgumentList = @()
    )

    & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo la ejecucion de '$ScriptPath'."
    }
}

$opsRoot = Split-Path -Parent $PSCommandPath
$verifyScript = Join-Path $opsRoot "verify_local_backup_restore.ps1"
$reprovisionScript = Join-Path $opsRoot "reprovision_stack_from_backup.ps1"
$capacityHeadroomScript = Join-Path $opsRoot "assert_capacity_headroom.ps1"
$capacityTrendScript = Join-Path $opsRoot "assert_capacity_trend.ps1"

for ($iteration = 1; $iteration -le $TempRestoreIterations; $iteration++) {
    Write-Host "Temp restore baseline sample $iteration/$TempRestoreIterations..." -ForegroundColor Cyan
    Invoke-PowerShellScript -ScriptPath $verifyScript -ArgumentList @(
        "-MetricsProfile", "preproduction-strict",
        "-MetricsScenario", "preproduction-smoke",
        "-RunSmokeAfterRestore",
        "-RunBusinessIntegrityChecks",
        "-EnsureBusinessFixture",
        "-RunEvidencePackageChecks"
    )
}

for ($iteration = 1; $iteration -le $StackReprovisionIterations; $iteration++) {
    Write-Host "Stack reprovision baseline sample $iteration/$StackReprovisionIterations..." -ForegroundColor Cyan
    Invoke-PowerShellScript -ScriptPath $reprovisionScript -ArgumentList @(
        "-MetricsProfile", "preproduction-strict",
        "-MetricsScenario", "preproduction-smoke",
        "-CreateFreshBackup",
        "-RunSmokeAfterRestore",
        "-RunBusinessIntegrityChecks",
        "-EnsureBusinessFixture",
        "-RunEvidencePackageChecks"
    )
}

if (-not $SkipCapacityChecks) {
    Write-Host "Refreshing capacity baseline for preproduction-strict / preproduction-smoke..." -ForegroundColor Cyan
    Invoke-PowerShellScript -ScriptPath $capacityHeadroomScript -ArgumentList @(
        "-Profile", "preproduction-strict",
        "-Scenario", "preproduction-smoke"
    )
    Invoke-PowerShellScript -ScriptPath $capacityTrendScript -ArgumentList @(
        "-Profile", "preproduction-strict",
        "-Scenario", "preproduction-smoke"
    )
}

Write-Host "Baseline preproduction-strict refrescada correctamente." -ForegroundColor Green
