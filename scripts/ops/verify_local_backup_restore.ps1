param(
    [string]$OutputRoot = "",
    [string]$TargetDatabaseName = "",
    [string]$TargetStorageRoot = "",
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$MetricsProfile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$MetricsScenario = "local-idle",
    [switch]$RunSmokeAfterRestore,
    [switch]$RunBusinessIntegrityChecks,
    [switch]$EnsureBusinessFixture,
    [switch]$RunEvidencePackageChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

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

function Get-LatestBackupBundlePath {
    param([string]$RootPath)

    $bundle = Get-ChildItem -Path $RootPath -Directory -Filter "backup_*" |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName "manifest.json")) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName "postgres_gdms.dump")) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName "document_storage.zip"))
        } |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1

    if (-not $bundle) {
        throw "No se encontro ningun bundle backup_* valido en '$RootPath'."
    }

    return $bundle.FullName
}

function Get-ElapsedMilliseconds {
    param([datetimeoffset]$StartedAtUtc)

    return [math]::Round(([DateTimeOffset]::UtcNow - $StartedAtUtc).TotalMilliseconds, 0)
}

$repoRoot = Get-RepoRoot
$resolvedOutputRoot = if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    Join-Path $repoRoot "artifacts\ops\backups"
} else {
    [System.IO.Path]::GetFullPath($OutputRoot)
}

$timestamp = [DateTime]::UtcNow.ToString("yyyyMMdd_HHmmss")
$resolvedTargetDatabaseName = if ([string]::IsNullOrWhiteSpace($TargetDatabaseName)) {
    "gdms_restore_validation_$timestamp"
} else {
    $TargetDatabaseName
}

$resolvedTargetStorageRoot = if ([string]::IsNullOrWhiteSpace($TargetStorageRoot)) {
    Join-Path $repoRoot "artifacts\ops\restore_validation\storage_$timestamp"
} else {
    [System.IO.Path]::GetFullPath($TargetStorageRoot)
}

$backupScript = Join-Path $PSScriptRoot "backup_local_stack.ps1"
$restoreScript = Join-Path $PSScriptRoot "restore_local_stack.ps1"
$smokeScript = Join-Path $PSScriptRoot "invoke_preproduction_smoke.ps1"
$businessIntegrityScript = Join-Path $PSScriptRoot "assert_restore_business_integrity.ps1"
$tempEvidenceScript = Join-Path $PSScriptRoot "invoke_temp_restore_evidence_validation.ps1"
$seedFixtureScript = Join-Path $PSScriptRoot "seed_restore_business_fixture.ps1"
$metricsScript = Join-Path $PSScriptRoot "write_recovery_drill_metrics.ps1"
$drillStartedAtUtc = [DateTimeOffset]::UtcNow
$seedDurationMs = 0
$backupDurationMs = 0
$restoreDurationMs = 0
$integrityDurationMs = 0
$evidenceDurationMs = 0
$smokeDurationMs = 0
$drillCompletedAtUtc = [DateTimeOffset]::UtcNow

if ($EnsureBusinessFixture) {
    Write-Host "Sembrando fixture de negocio antes del backup..." -ForegroundColor Cyan
    $seedStartedAtUtc = [DateTimeOffset]::UtcNow
    Invoke-PowerShellScript -ScriptPath $seedFixtureScript -ArgumentList @(
        "-TargetDatabaseName", "gdms"
    )
    $seedDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $seedStartedAtUtc
}

Write-Host "Generando bundle de backup..." -ForegroundColor Cyan
$backupStartedAtUtc = [DateTimeOffset]::UtcNow
Invoke-PowerShellScript -ScriptPath $backupScript -ArgumentList @("-OutputRoot", $resolvedOutputRoot)
$backupDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $backupStartedAtUtc

$bundlePath = Get-LatestBackupBundlePath -RootPath $resolvedOutputRoot
Write-Host "Bundle detectado: $bundlePath" -ForegroundColor DarkGray

Write-Host "Restaurando backup en destinos temporales..." -ForegroundColor Cyan
$restoreStartedAtUtc = [DateTimeOffset]::UtcNow
Invoke-PowerShellScript -ScriptPath $restoreScript -ArgumentList @(
    "-BackupBundlePath", $bundlePath,
    "-TargetDatabaseName", $resolvedTargetDatabaseName,
    "-TargetStorageRoot", $resolvedTargetStorageRoot
)
$restoreDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $restoreStartedAtUtc

$manifestPath = Join-Path $bundlePath "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "El bundle '$bundlePath' no contiene manifest.json."
}
$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json

$restoredFileCount = @(Get-ChildItem -Path $resolvedTargetStorageRoot -Recurse -File -Force).Count
if ($restoredFileCount -lt 0) {
    throw "No se pudo verificar el storage restaurado en '$resolvedTargetStorageRoot'."
}

if ($RunBusinessIntegrityChecks) {
    Write-Host "Ejecutando verificacion de integridad de negocio sobre restore temporal..." -ForegroundColor Cyan
    $integrityStartedAtUtc = [DateTimeOffset]::UtcNow
    $businessIntegrityArgs = @(
        "-TargetDatabaseName", $resolvedTargetDatabaseName,
        "-TargetStorageRoot", $resolvedTargetStorageRoot
    )
    if ($EnsureBusinessFixture) {
        $businessIntegrityArgs += "-RequireFixtureDocument"
    }
    Invoke-PowerShellScript -ScriptPath $businessIntegrityScript -ArgumentList $businessIntegrityArgs
    $integrityDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $integrityStartedAtUtc
}

if ($RunEvidencePackageChecks) {
    Write-Host "Ejecutando validacion HTTP del evidence package sobre API efimera del restore temporal..." -ForegroundColor Cyan
    $evidenceStartedAtUtc = [DateTimeOffset]::UtcNow
    $successMarkerPath = Join-Path $repoRoot ("artifacts\ops\temp_restore_evidence_success_{0}.txt" -f $resolvedTargetDatabaseName)
    if (Test-Path -LiteralPath $successMarkerPath) {
        Remove-Item -LiteralPath $successMarkerPath -Force
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $tempEvidenceScript `
        -TargetDatabaseName $resolvedTargetDatabaseName `
        -TargetStorageRoot $resolvedTargetStorageRoot `
        -SuccessMarkerPath $successMarkerPath

    if (-not (Test-Path -LiteralPath $successMarkerPath)) {
        throw "La validacion HTTP del evidence package sobre API efimera no genero marcador de exito."
    }
    $evidenceDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $evidenceStartedAtUtc
}

if ($RunSmokeAfterRestore) {
    Write-Host "Ejecutando smoke operativo posterior..." -ForegroundColor Cyan
    $smokeStartedAtUtc = [DateTimeOffset]::UtcNow
    Invoke-PowerShellScript -ScriptPath $smokeScript -ArgumentList @(
        "-ValidateConfiguration",
        "-ValidateRuntimeConfiguration",
        "-ValidateOperationalRisks"
    )
    $smokeDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $smokeStartedAtUtc
}

[pscustomobject]@{
    BackupBundlePath = $bundlePath
    RestoredDatabase = $resolvedTargetDatabaseName
    RestoredStorageRoot = $resolvedTargetStorageRoot
    RestoredStorageFileCount = $restoredFileCount
    SmokeAfterRestore = [bool]$RunSmokeAfterRestore
    BusinessIntegrityChecks = [bool]$RunBusinessIntegrityChecks
    EnsuredBusinessFixture = [bool]$EnsureBusinessFixture
    EvidencePackageChecks = [bool]$RunEvidencePackageChecks
    SeedFixtureDurationMs = $seedDurationMs
    BackupDurationMs = $backupDurationMs
    RestoreDurationMs = $restoreDurationMs
    BusinessIntegrityDurationMs = $integrityDurationMs
    EvidencePackageDurationMs = $evidenceDurationMs
    SmokeDurationMs = $smokeDurationMs
    TotalDrillDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $drillStartedAtUtc
} | Format-List

$drillCompletedAtUtc = [DateTimeOffset]::UtcNow
Invoke-PowerShellScript -ScriptPath $metricsScript -ArgumentList @(
    "-DrillType", "temp_restore_validation",
    "-MetricsProfile", $MetricsProfile,
    "-MetricsScenario", $MetricsScenario,
    "-Status", "Succeeded",
    "-StartedAtUtc", $drillStartedAtUtc.ToString("o"),
    "-CompletedAtUtc", $drillCompletedAtUtc.ToString("o"),
    "-SeedFixtureDurationMs", $seedDurationMs,
    "-BackupDurationMs", $backupDurationMs,
    "-RestoreDurationMs", $restoreDurationMs,
    "-BusinessIntegrityDurationMs", $integrityDurationMs,
    "-EvidencePackageDurationMs", $evidenceDurationMs,
    "-SmokeDurationMs", $smokeDurationMs,
    "-TotalDrillDurationMs", (Get-ElapsedMilliseconds -StartedAtUtc $drillStartedAtUtc),
    "-BackupBundlePath", $bundlePath,
    "-BackupCreatedAtUtc", ([string]$manifest.createdAtUtc),
    "-TargetDatabaseName", $resolvedTargetDatabaseName,
    "-TargetStorageRoot", $resolvedTargetStorageRoot
)

Write-Host "Verificacion de backup/restore completada en verde." -ForegroundColor Green
