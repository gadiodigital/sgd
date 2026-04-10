param(
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$Profile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$Scenario = "local-idle",
    [double]$HostDriveWarnGb = 5,
    [double]$HostDriveFailGb = 2,
    [double]$PostgresDatabaseWarnMb = 512,
    [double]$PostgresDatabaseFailMb = 1024,
    [double]$DocumentStorageWarnMb = 512,
    [double]$DocumentStorageFailMb = 1024
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-CheckResult {
    param(
        [System.Collections.Generic.List[object]]$Results,
        [string]$Name,
        [string]$Status,
        [string]$Detail
    )

    $Results.Add([pscustomobject]@{
        Check = $Name
        Status = $Status
        Detail = $Detail
    })
}

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
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

function Resolve-ContainerName {
    param(
        [string]$PreferredContainerName,
        [string]$ServiceName
    )

    $runningNames = @(& docker ps --format "{{.Names}}")
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo consultar docker ps."
    }

    if ($runningNames -contains $PreferredContainerName) {
        return $PreferredContainerName
    }

    $serviceContainerId = (& docker compose ps -q $ServiceName 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$serviceContainerId")) {
        $resolvedName = (& docker ps --filter "id=$serviceContainerId" --format "{{.Names}}")
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$resolvedName")) {
            return "$resolvedName".Trim()
        }
    }

    throw "No se encontro un contenedor para el servicio '$ServiceName'."
}

function Get-DirectorySizeBytes {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0L
    }

    $files = @(Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) {
        return 0L
    }

    $measure = $files | Measure-Object -Property Length -Sum
    return [int64]$measure.Sum
}

function Get-HostFreeSpaceGb {
    param([string]$Path)

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $rootPath = [System.IO.Path]::GetPathRoot($resolvedPath)
    $drive = Get-PSDrive -Name $rootPath.TrimEnd('\').TrimEnd(':')
    return [Math]::Round($drive.Free / 1GB, 2)
}

function Get-PostgresDatabaseSizeMb {
    param(
        [string]$ContainerName,
        [string]$DatabaseUser,
        [string]$DatabaseName
    )

    $query = "SELECT pg_database_size('$DatabaseName');"
    $bytes = & docker exec $ContainerName psql -U $DatabaseUser -d postgres -t -A -c $query
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo consultar pg_database_size($DatabaseName)."
    }

    return [Math]::Round(([double]("$bytes".Trim()) / 1MB), 2)
}

$profileOverrides = @{
    "local-light" = @{
        HostDriveWarnGb = 5
        HostDriveFailGb = 2
        PostgresDatabaseWarnMb = 512
        PostgresDatabaseFailMb = 1024
        DocumentStorageWarnMb = 512
        DocumentStorageFailMb = 1024
    }
    "preproduction-strict" = @{
        HostDriveWarnGb = 12
        HostDriveFailGb = 6
        PostgresDatabaseWarnMb = 128
        PostgresDatabaseFailMb = 512
        DocumentStorageWarnMb = 128
        DocumentStorageFailMb = 512
    }
}

$selectedProfile = $profileOverrides[$Profile]
$HostDriveWarnGb = $selectedProfile.HostDriveWarnGb
$HostDriveFailGb = $selectedProfile.HostDriveFailGb
$PostgresDatabaseWarnMb = $selectedProfile.PostgresDatabaseWarnMb
$PostgresDatabaseFailMb = $selectedProfile.PostgresDatabaseFailMb
$DocumentStorageWarnMb = $selectedProfile.DocumentStorageWarnMb
$DocumentStorageFailMb = $selectedProfile.DocumentStorageFailMb

$repoRoot = Get-RepoRoot
$capacityMetricsRoot = Join-Path $repoRoot "artifacts\ops\capacity_metrics"
Ensure-Directory -Path $capacityMetricsRoot
$historyPath = Join-Path $capacityMetricsRoot "history.jsonl"
$artifactSuffix = "$Profile.$Scenario"
$summaryJsonPath = Join-Path $capacityMetricsRoot "latest.$artifactSuffix.json"
$summaryMarkdownPath = Join-Path $capacityMetricsRoot "latest.$artifactSuffix.md"
$storageRoot = Get-DefaultStorageRoot -RepoRoot $repoRoot
$postgresContainer = Resolve-ContainerName -PreferredContainerName "gdms-postgres" -ServiceName "postgres"
$results = [System.Collections.Generic.List[object]]::new()

$repoDriveFreeGb = Get-HostFreeSpaceGb -Path $repoRoot
if ($repoDriveFreeGb -lt $HostDriveFailGb) {
    Add-CheckResult -Results $results -Name "Host drive free space" -Status "FAIL" -Detail "Espacio libre insuficiente en drive del repo: $repoDriveFreeGb GB."
} elseif ($repoDriveFreeGb -lt $HostDriveWarnGb) {
    Add-CheckResult -Results $results -Name "Host drive free space" -Status "WARN" -Detail "Espacio libre bajo en drive del repo: $repoDriveFreeGb GB."
} else {
    Add-CheckResult -Results $results -Name "Host drive free space" -Status "OK" -Detail "Espacio libre suficiente en drive del repo: $repoDriveFreeGb GB."
}

$storageSizeMb = [Math]::Round((Get-DirectorySizeBytes -Path $storageRoot) / 1MB, 2)
if (-not (Test-Path -LiteralPath $storageRoot)) {
    Add-CheckResult -Results $results -Name "Document storage root" -Status "WARN" -Detail "El storage documental '$storageRoot' todavia no existe."
} elseif ($storageSizeMb -ge $DocumentStorageFailMb) {
    Add-CheckResult -Results $results -Name "Document storage size" -Status "FAIL" -Detail "Storage documental en $storageSizeMb MB, por encima del umbral de fallo."
} elseif ($storageSizeMb -ge $DocumentStorageWarnMb) {
    Add-CheckResult -Results $results -Name "Document storage size" -Status "WARN" -Detail "Storage documental en $storageSizeMb MB, revisar limpieza/rotacion."
} else {
    Add-CheckResult -Results $results -Name "Document storage size" -Status "OK" -Detail "Storage documental en $storageSizeMb MB."
}

$storageDriveFreeGb = Get-HostFreeSpaceGb -Path $storageRoot
if ($storageDriveFreeGb -lt $HostDriveFailGb) {
    Add-CheckResult -Results $results -Name "Document storage drive free space" -Status "FAIL" -Detail "Espacio libre insuficiente en drive de storage: $storageDriveFreeGb GB."
} elseif ($storageDriveFreeGb -lt $HostDriveWarnGb) {
    Add-CheckResult -Results $results -Name "Document storage drive free space" -Status "WARN" -Detail "Espacio libre bajo en drive de storage: $storageDriveFreeGb GB."
} else {
    Add-CheckResult -Results $results -Name "Document storage drive free space" -Status "OK" -Detail "Espacio libre suficiente en drive de storage: $storageDriveFreeGb GB."
}

$postgresDatabaseSizeMb = Get-PostgresDatabaseSizeMb -ContainerName $postgresContainer -DatabaseUser "gdms" -DatabaseName "gdms"
if ($postgresDatabaseSizeMb -ge $PostgresDatabaseFailMb) {
    Add-CheckResult -Results $results -Name "PostgreSQL main database size" -Status "FAIL" -Detail "Base principal en $postgresDatabaseSizeMb MB, por encima del umbral de fallo."
} elseif ($postgresDatabaseSizeMb -ge $PostgresDatabaseWarnMb) {
    Add-CheckResult -Results $results -Name "PostgreSQL main database size" -Status "WARN" -Detail "Base principal en $postgresDatabaseSizeMb MB, revisar vacuum/retencion."
} else {
    Add-CheckResult -Results $results -Name "PostgreSQL main database size" -Status "OK" -Detail "Base principal en $postgresDatabaseSizeMb MB."
}

$dockerDf = & docker system df 2>&1
if ($LASTEXITCODE -ne 0) {
    Add-CheckResult -Results $results -Name "Docker system df" -Status "WARN" -Detail "No se pudo consultar docker system df."
} else {
    $summaryLine = ($dockerDf | Select-String -Pattern '^Local Volumes space usage:' -Context 0,1 | Select-Object -First 1)
    if ($summaryLine) {
        $detail = ($summaryLine.Context.PostContext + $summaryLine.Line) -join ' '
        Add-CheckResult -Results $results -Name "Docker volume usage visibility" -Status "OK" -Detail ($detail.Trim())
    } else {
        Add-CheckResult -Results $results -Name "Docker volume usage visibility" -Status "OK" -Detail "docker system df disponible."
    }
}

$summary = [ordered]@{
    GeneratedAtUtc = [DateTimeOffset]::UtcNow.ToString("o")
    Profile = $Profile
    Scenario = $Scenario
    RepoRoot = $repoRoot
    StorageRoot = $storageRoot
    Thresholds = [ordered]@{
        HostDriveWarnGb = $HostDriveWarnGb
        HostDriveFailGb = $HostDriveFailGb
        PostgresDatabaseWarnMb = $PostgresDatabaseWarnMb
        PostgresDatabaseFailMb = $PostgresDatabaseFailMb
        DocumentStorageWarnMb = $DocumentStorageWarnMb
        DocumentStorageFailMb = $DocumentStorageFailMb
    }
    Measurements = [ordered]@{
        HostDriveFreeGb = $repoDriveFreeGb
        DocumentStorageSizeMb = $storageSizeMb
        DocumentStorageDriveFreeGb = $storageDriveFreeGb
        PostgresDatabaseSizeMb = $postgresDatabaseSizeMb
    }
    Results = @($results)
}

$historyEntry = [ordered]@{
    GeneratedAtUtc = $summary.GeneratedAtUtc
    Profile = $summary.Profile
    Scenario = $summary.Scenario
    Measurements = $summary.Measurements
    Thresholds = $summary.Thresholds
    ResultCounts = [ordered]@{
        Ok = @($results | Where-Object Status -eq "OK").Count
        Warn = @($results | Where-Object Status -eq "WARN").Count
        Fail = @($results | Where-Object Status -eq "FAIL").Count
    }
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryJsonPath -Encoding utf8
$historyEntry | ConvertTo-Json -Compress | Add-Content -Path $historyPath -Encoding utf8

$mdTick = [char]96
$summaryMarkdown = @(
    "# Capacity Headroom Summary"
    ""
    "- GeneratedAtUtc: $mdTick$($summary.GeneratedAtUtc)$mdTick"
    "- Profile: $mdTick$($summary.Profile)$mdTick"
    "- Scenario: $mdTick$($summary.Scenario)$mdTick"
    "- RepoRoot: $mdTick$($summary.RepoRoot)$mdTick"
    "- StorageRoot: $mdTick$($summary.StorageRoot)$mdTick"
    ""
    "## Thresholds"
    ""
    "- HostDriveWarnGb: $mdTick$($summary.Thresholds.HostDriveWarnGb)$mdTick"
    "- HostDriveFailGb: $mdTick$($summary.Thresholds.HostDriveFailGb)$mdTick"
    "- PostgresDatabaseWarnMb: $mdTick$($summary.Thresholds.PostgresDatabaseWarnMb)$mdTick"
    "- PostgresDatabaseFailMb: $mdTick$($summary.Thresholds.PostgresDatabaseFailMb)$mdTick"
    "- DocumentStorageWarnMb: $mdTick$($summary.Thresholds.DocumentStorageWarnMb)$mdTick"
    "- DocumentStorageFailMb: $mdTick$($summary.Thresholds.DocumentStorageFailMb)$mdTick"
    ""
    "## Measurements"
    ""
    "- HostDriveFreeGb: $mdTick$($summary.Measurements.HostDriveFreeGb)$mdTick"
    "- DocumentStorageSizeMb: $mdTick$($summary.Measurements.DocumentStorageSizeMb)$mdTick"
    "- DocumentStorageDriveFreeGb: $mdTick$($summary.Measurements.DocumentStorageDriveFreeGb)$mdTick"
    "- PostgresDatabaseSizeMb: $mdTick$($summary.Measurements.PostgresDatabaseSizeMb)$mdTick"
    ""
    "## Checks"
    ""
)

foreach ($result in $results) {
    $summaryMarkdown += "- $($result.Check): status=$mdTick$($result.Status)$mdTick, detail=$mdTick$($result.Detail)$mdTick"
}

Set-Content -Path $summaryMarkdownPath -Value $summaryMarkdown -Encoding utf8

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Capacidad operativa insuficiente: $($failed.Count) chequeo(s) en rojo."
}

$warnings = @($results | Where-Object Status -eq "WARN")
if ($warnings.Count -gt 0) {
    Write-Warning "Chequeos de capacidad con advertencias: $($warnings.Count)."
} else {
    Write-Host "Capacidad operativa validada en verde para perfil '$Profile' y escenario '$Scenario'." -ForegroundColor Green
}
