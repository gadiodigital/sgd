param(
    [string]$BackupBundlePath = "",
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$MetricsProfile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$MetricsScenario = "local-idle",
    [switch]$CreateFreshBackup,
    [switch]$RunSmokeAfterRestore,
    [switch]$RunBusinessIntegrityChecks,
    [switch]$EnsureBusinessFixture,
    [switch]$RunEvidencePackageChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-DefaultStorageRoot {
    param([string]$RepoRoot)

    $appSettingsPath = Join-Path $RepoRoot "server\src\Gdms.Api\appsettings.json"
    $appSettings = Get-Content -Path $appSettingsPath -Raw | ConvertFrom-Json
    $configuredPath = [string]$appSettings.Storage.LocalRootPath
    if ([string]::IsNullOrWhiteSpace($configuredPath)) {
        $configuredPath = "data/storage/documents"
    }

    $contentRoot = Join-Path $RepoRoot "server\src\Gdms.Api"
    if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        return [System.IO.Path]::GetFullPath($configuredPath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $contentRoot $configuredPath))
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

function Invoke-DockerComposeChecked {
    param([string[]]$ArgumentList)

    & docker compose @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose fallo: docker compose $($ArgumentList -join ' ')"
    }
}

function Wait-ApiHealthy {
    param(
        [string]$Url,
        [int]$RetryCount = 40,
        [int]$RetryDelaySeconds = 3
    )

    $httpClient = [System.Net.Http.HttpClient]::new()
    $httpClient.Timeout = [TimeSpan]::FromSeconds(10)
    try {
        for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
            try {
                $payload = $httpClient.GetStringAsync($Url).GetAwaiter().GetResult() | ConvertFrom-Json
                if ($payload.status -eq "Healthy") {
                    return
                }
            } catch {
            }

            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    } finally {
        $httpClient.Dispose()
    }

    throw "La API no quedo healthy en '$Url' dentro del tiempo esperado."
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

function Test-PostgresContainerRunning {
    $names = @(& docker ps --format "{{.Names}}")
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo consultar docker ps."
    }

    return ($names -contains "gdms-postgres")
}

function Test-PrimaryDatabaseReady {
    if (-not (Test-PostgresContainerRunning)) {
        return $false
    }

    $stdoutPath = Join-Path $env:TEMP ("gdms-primary-db-ready-{0}.stdout.txt" -f [guid]::NewGuid().ToString("N"))
    $stderrPath = Join-Path $env:TEMP ("gdms-primary-db-ready-{0}.stderr.txt" -f [guid]::NewGuid().ToString("N"))
    try {
        $process = Start-Process -FilePath "docker" -ArgumentList @("exec", "gdms-postgres", "psql", "-U", "gdms", "-d", "gdms", "-t", "-A", "-c", "SELECT 1") -Wait -NoNewWindow -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        return ($process.ExitCode -eq 0)
    } finally {
        if (Test-Path -LiteralPath $stdoutPath) {
            Remove-Item -LiteralPath $stdoutPath -Force
        }
        if (Test-Path -LiteralPath $stderrPath) {
            Remove-Item -LiteralPath $stderrPath -Force
        }
    }
}

function Get-ElapsedMilliseconds {
    param([datetimeoffset]$StartedAtUtc)

    return [math]::Round(([DateTimeOffset]::UtcNow - $StartedAtUtc).TotalMilliseconds, 0)
}

$repoRoot = Get-RepoRoot
$backupScript = Join-Path $PSScriptRoot "backup_local_stack.ps1"
$restoreScript = Join-Path $PSScriptRoot "restore_local_stack.ps1"
$smokeScript = Join-Path $PSScriptRoot "invoke_preproduction_smoke.ps1"
$businessIntegrityScript = Join-Path $PSScriptRoot "assert_restore_business_integrity.ps1"
$evidencePackageScript = Join-Path $PSScriptRoot "assert_evidence_package_export.ps1"
$seedFixtureScript = Join-Path $PSScriptRoot "seed_restore_business_fixture.ps1"
$metricsScript = Join-Path $PSScriptRoot "write_recovery_drill_metrics.ps1"
$runDockerScript = Join-Path $repoRoot "scripts\setup\windows\16-run-gdms-docker.ps1"
$backupOutputRoot = Join-Path $repoRoot "artifacts\ops\backups"
$primaryStorageRoot = Get-DefaultStorageRoot -RepoRoot $repoRoot
$drillStartedAtUtc = [DateTimeOffset]::UtcNow
$seedDurationMs = 0
$backupDurationMs = 0
$reprovisionDurationMs = 0
$restoreDurationMs = 0
$smokeDurationMs = 0
$integrityDurationMs = 0
$evidenceDurationMs = 0
$drillCompletedAtUtc = [DateTimeOffset]::UtcNow

Set-Location $repoRoot

$resolvedBackupBundlePath = ""
if ($CreateFreshBackup -or [string]::IsNullOrWhiteSpace($BackupBundlePath)) {
    if (-not (Test-PostgresContainerRunning)) {
        Write-Host "No hay stack operativo para respaldar. Levantando stack base..." -ForegroundColor Yellow
        Invoke-PowerShellScript -ScriptPath $runDockerScript
        Wait-ApiHealthy -Url "http://127.0.0.1:8080/api/health"
    }

    if ($EnsureBusinessFixture) {
        Write-Host "Sembrando fixture de negocio antes del backup..." -ForegroundColor Cyan
        $seedStartedAtUtc = [DateTimeOffset]::UtcNow
        Invoke-PowerShellScript -ScriptPath $seedFixtureScript -ArgumentList @(
            "-TargetDatabaseName", "gdms",
            "-TargetStorageRoot", $primaryStorageRoot
        )
        $seedDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $seedStartedAtUtc
    }

    if (Test-PrimaryDatabaseReady) {
        Write-Host "Generando backup previo a la reprovision..." -ForegroundColor Cyan
        $backupStartedAtUtc = [DateTimeOffset]::UtcNow
        Invoke-PowerShellScript -ScriptPath $backupScript -ArgumentList @("-OutputRoot", $backupOutputRoot)
        $backupDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $backupStartedAtUtc
        $resolvedBackupBundlePath = Get-LatestBackupBundlePath -RootPath $backupOutputRoot
    } else {
        Write-Warning "La base principal actual no esta en estado respaldable. Se usara el ultimo bundle existente."
        $resolvedBackupBundlePath = Get-LatestBackupBundlePath -RootPath $backupOutputRoot
    }
} else {
    $resolvedBackupBundlePath = [System.IO.Path]::GetFullPath($BackupBundlePath)
}

if (-not (Test-Path -LiteralPath $resolvedBackupBundlePath)) {
    throw "No se encontro el bundle de backup '$resolvedBackupBundlePath'."
}
$manifestPath = Join-Path $resolvedBackupBundlePath "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "No se encontro manifest.json en '$resolvedBackupBundlePath'."
}
$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json

Write-Host "Reprovisionando stack Docker desde cero..." -ForegroundColor Cyan
$reprovisionStartedAtUtc = [DateTimeOffset]::UtcNow
Invoke-DockerComposeChecked -ArgumentList @("down", "-v")
Invoke-PowerShellScript -ScriptPath $runDockerScript -ArgumentList @("-SkipBuild")

Write-Host "Esperando estabilidad del stack reprovisionado..." -ForegroundColor Cyan
Wait-ApiHealthy -Url "http://127.0.0.1:8080/api/health"
$reprovisionDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $reprovisionStartedAtUtc

Write-Host "Deteniendo API para restaurar el estado principal..." -ForegroundColor Cyan
Invoke-DockerComposeChecked -ArgumentList @("stop", "api")

Write-Host "Restaurando backup sobre la base y storage principales..." -ForegroundColor Cyan
$restoreStartedAtUtc = [DateTimeOffset]::UtcNow
Invoke-PowerShellScript -ScriptPath $restoreScript -ArgumentList @(
    "-BackupBundlePath", $resolvedBackupBundlePath,
    "-TargetDatabaseName", "gdms",
    "-AllowPrimaryDatabaseRestore",
    "-TargetStorageRoot", $primaryStorageRoot,
    "-AllowPrimaryStorageRestore"
)
$restoreDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $restoreStartedAtUtc

Write-Host "Levantando API restaurada..." -ForegroundColor Cyan
Invoke-DockerComposeChecked -ArgumentList @("start", "api")

if ($RunSmokeAfterRestore) {
    Write-Host "Ejecutando smoke posterior a la reprovision..." -ForegroundColor Cyan
    $smokeStartedAtUtc = [DateTimeOffset]::UtcNow
    Invoke-PowerShellScript -ScriptPath $smokeScript -ArgumentList @(
        "-ValidateConfiguration",
        "-ValidateRuntimeConfiguration",
        "-ValidateOperationalRisks",
        "-ValidateCapacityHeadroom"
    )
    $smokeDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $smokeStartedAtUtc
}

if ($RunBusinessIntegrityChecks) {
    Write-Host "Ejecutando verificacion de integridad de negocio sobre el estado reprovisionado..." -ForegroundColor Cyan
    $integrityStartedAtUtc = [DateTimeOffset]::UtcNow
    $businessIntegrityArgs = @(
        "-TargetDatabaseName", "gdms",
        "-TargetStorageRoot", $primaryStorageRoot
    )
    if ($EnsureBusinessFixture) {
        $businessIntegrityArgs += "-RequireFixtureDocument"
    }
    Invoke-PowerShellScript -ScriptPath $businessIntegrityScript -ArgumentList $businessIntegrityArgs
    $integrityDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $integrityStartedAtUtc
}

if ($RunEvidencePackageChecks) {
    Write-Host "Ejecutando validacion HTTP del evidence package sobre el estado reprovisionado..." -ForegroundColor Cyan
    $evidenceStartedAtUtc = [DateTimeOffset]::UtcNow
    Invoke-PowerShellScript -ScriptPath $evidencePackageScript
    $evidenceDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $evidenceStartedAtUtc
}

[pscustomobject]@{
    BackupBundlePath = $resolvedBackupBundlePath
    ReprovisionedDatabase = "gdms"
    ReprovisionedStorageRoot = $primaryStorageRoot
    SmokeAfterRestore = [bool]$RunSmokeAfterRestore
    BusinessIntegrityChecks = [bool]$RunBusinessIntegrityChecks
    EnsuredBusinessFixture = [bool]$EnsureBusinessFixture
    EvidencePackageChecks = [bool]$RunEvidencePackageChecks
    SeedFixtureDurationMs = $seedDurationMs
    BackupDurationMs = $backupDurationMs
    ReprovisionDurationMs = $reprovisionDurationMs
    RestoreDurationMs = $restoreDurationMs
    SmokeDurationMs = $smokeDurationMs
    BusinessIntegrityDurationMs = $integrityDurationMs
    EvidencePackageDurationMs = $evidenceDurationMs
    TotalDrillDurationMs = Get-ElapsedMilliseconds -StartedAtUtc $drillStartedAtUtc
} | Format-List

$drillCompletedAtUtc = [DateTimeOffset]::UtcNow
Invoke-PowerShellScript -ScriptPath $metricsScript -ArgumentList @(
    "-DrillType", "stack_reprovision",
    "-MetricsProfile", $MetricsProfile,
    "-MetricsScenario", $MetricsScenario,
    "-Status", "Succeeded",
    "-StartedAtUtc", $drillStartedAtUtc.ToString("o"),
    "-CompletedAtUtc", $drillCompletedAtUtc.ToString("o"),
    "-SeedFixtureDurationMs", $seedDurationMs,
    "-BackupDurationMs", $backupDurationMs,
    "-ReprovisionDurationMs", $reprovisionDurationMs,
    "-RestoreDurationMs", $restoreDurationMs,
    "-BusinessIntegrityDurationMs", $integrityDurationMs,
    "-EvidencePackageDurationMs", $evidenceDurationMs,
    "-SmokeDurationMs", $smokeDurationMs,
    "-TotalDrillDurationMs", (Get-ElapsedMilliseconds -StartedAtUtc $drillStartedAtUtc),
    "-BackupBundlePath", $resolvedBackupBundlePath,
    "-BackupCreatedAtUtc", ([string]$manifest.createdAtUtc),
    "-TargetDatabaseName", "gdms",
    "-TargetStorageRoot", $primaryStorageRoot
)

Write-Host "Reprovision completa desde backup validada en verde." -ForegroundColor Green
