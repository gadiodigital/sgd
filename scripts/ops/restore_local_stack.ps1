param(
    [Parameter(Mandatory = $true)]
    [string]$BackupBundlePath,
    [string]$PostgresContainerName = "gdms-postgres",
    [string]$PostgresServiceName = "postgres",
    [string]$DatabaseUser = "gdms",
    [string]$TargetDatabaseName = "gdms_restore_validation",
    [string]$TargetStorageRoot = "",
    [switch]$AllowPrimaryDatabaseRestore,
    [switch]$AllowPrimaryStorageRestore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Invoke-DockerChecked {
    param([string[]]$ArgumentList)

    & docker @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "docker fallo: docker $($ArgumentList -join ' ')"
    }
}

function Resolve-PostgresContainerName {
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

    throw "No se encontro un contenedor PostgreSQL corriendo para el servicio '$ServiceName'."
}

function Assert-SafeDatabaseName {
    param([string]$DatabaseName)

    if ($DatabaseName -notmatch '^[A-Za-z0-9_]+$') {
        throw "El nombre de base '$DatabaseName' contiene caracteres no permitidos."
    }
}

$repoRoot = Get-RepoRoot
$resolvedBundlePath = [System.IO.Path]::GetFullPath($BackupBundlePath)
$manifestPath = Join-Path $resolvedBundlePath "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "No se encontro manifest.json en '$resolvedBundlePath'."
}

$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
$dumpPath = Join-Path $resolvedBundlePath $manifest.postgres.dumpFile
$storageArchivePath = Join-Path $resolvedBundlePath $manifest.storage.archiveFile
if (-not (Test-Path -LiteralPath $dumpPath)) {
    throw "No se encontro el dump PostgreSQL en '$dumpPath'."
}
if (-not (Test-Path -LiteralPath $storageArchivePath)) {
    throw "No se encontro el zip de storage en '$storageArchivePath'."
}

Assert-SafeDatabaseName -DatabaseName $TargetDatabaseName
if ($TargetDatabaseName -eq "gdms" -and -not $AllowPrimaryDatabaseRestore) {
    throw "Restaurar sobre la base principal requiere -AllowPrimaryDatabaseRestore."
}

$liveStorageRoot = Get-DefaultStorageRoot -RepoRoot $repoRoot
$resolvedPostgresContainerName = Resolve-PostgresContainerName -PreferredContainerName $PostgresContainerName -ServiceName $PostgresServiceName
$resolvedStorageRoot = if ([string]::IsNullOrWhiteSpace($TargetStorageRoot)) {
    Join-Path $repoRoot ("artifacts\ops\restore_validation\storage_{0}" -f ([DateTime]::UtcNow.ToString("yyyyMMdd_HHmmssZ")))
} else {
    [System.IO.Path]::GetFullPath($TargetStorageRoot)
}

if ($resolvedStorageRoot -eq $liveStorageRoot -and -not $AllowPrimaryStorageRestore) {
    throw "Restaurar sobre el storage principal requiere -AllowPrimaryStorageRestore."
}

$containerDumpPath = "/tmp/gdms-local-backup.dump"

Write-Host "Copiando dump al contenedor..." -ForegroundColor Cyan
Invoke-DockerChecked -ArgumentList @("cp", $dumpPath, "${resolvedPostgresContainerName}:$containerDumpPath")

Write-Host "Restaurando PostgreSQL en '$TargetDatabaseName'..." -ForegroundColor Cyan
try {
    $terminateSql = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TargetDatabaseName';"
    $dropSql = "DROP DATABASE IF EXISTS ""$TargetDatabaseName"";"
    $createSql = "CREATE DATABASE ""$TargetDatabaseName"";"
    Invoke-DockerChecked -ArgumentList @("exec", $resolvedPostgresContainerName, "psql", "-U", $DatabaseUser, "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-c", $terminateSql)
    Invoke-DockerChecked -ArgumentList @("exec", $resolvedPostgresContainerName, "psql", "-U", $DatabaseUser, "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-c", $dropSql)
    Invoke-DockerChecked -ArgumentList @("exec", $resolvedPostgresContainerName, "psql", "-U", $DatabaseUser, "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-c", $createSql)
    Invoke-DockerChecked -ArgumentList @("exec", $resolvedPostgresContainerName, "pg_restore", "-U", $DatabaseUser, "-d", $TargetDatabaseName, "--no-owner", "--no-privileges", $containerDumpPath)
    $tableCount = & docker exec $resolvedPostgresContainerName psql -U $DatabaseUser -d $TargetDatabaseName -t -A -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('public','identity');"
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo verificar la base restaurada."
    }
} finally {
    & docker exec $resolvedPostgresContainerName rm -f $containerDumpPath | Out-Null
}

Write-Host "Restaurando storage documental en '$resolvedStorageRoot'..." -ForegroundColor Cyan
if (Test-Path -LiteralPath $resolvedStorageRoot) {
    Remove-Item -LiteralPath $resolvedStorageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $resolvedStorageRoot -Force | Out-Null
Expand-Archive -LiteralPath $storageArchivePath -DestinationPath $resolvedStorageRoot -Force
$restoredFileCount = @(Get-ChildItem -Path $resolvedStorageRoot -Recurse -File -Force).Count

$summary = [pscustomobject]@{
    BundlePath = $resolvedBundlePath
    RestoredDatabase = $TargetDatabaseName
    RestoredTableCount = [int]("$tableCount".Trim())
    RestoredStorageRoot = $resolvedStorageRoot
    RestoredStorageFileCount = $restoredFileCount
}

$summary | Format-List
Write-Host "Restore local completado." -ForegroundColor Green
