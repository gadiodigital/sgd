param(
    [string]$OutputRoot = "",
    [string]$PostgresContainerName = "gdms-postgres",
    [string]$PostgresServiceName = "postgres",
    [string]$DatabaseName = "gdms",
    [string]$DatabaseUser = "gdms",
    [string]$StorageRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

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

function Invoke-DockerCapture {
    param(
        [string[]]$ArgumentList,
        [string]$OutputPath
    )

    $errorPath = "$OutputPath.stderr.txt"
    try {
        $process = Start-Process -FilePath "docker" -ArgumentList $ArgumentList -Wait -NoNewWindow -PassThru -RedirectStandardOutput $OutputPath -RedirectStandardError $errorPath
        if ($process.ExitCode -ne 0) {
            $message = if (Test-Path -LiteralPath $errorPath) { (Get-Content -Path $errorPath -Raw).Trim() } else { "docker fallo con exit code $($process.ExitCode)." }
            throw $message
        }
    } finally {
        if (Test-Path -LiteralPath $errorPath) {
            Remove-Item -LiteralPath $errorPath -Force
        }
    }
}

$repoRoot = Get-RepoRoot
$resolvedOutputRoot = if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    Join-Path $repoRoot "artifacts\ops\backups"
} else {
    [System.IO.Path]::GetFullPath($OutputRoot)
}

$resolvedStorageRoot = if ([string]::IsNullOrWhiteSpace($StorageRoot)) {
    Get-DefaultStorageRoot -RepoRoot $repoRoot
} else {
    [System.IO.Path]::GetFullPath($StorageRoot)
}

$resolvedPostgresContainerName = Resolve-PostgresContainerName -PreferredContainerName $PostgresContainerName -ServiceName $PostgresServiceName

if (-not (Test-Path -LiteralPath $resolvedStorageRoot)) {
    Write-Warning "El storage local '$resolvedStorageRoot' no existe todavia. Se respaldara como directorio vacio."
    New-Item -ItemType Directory -Path $resolvedStorageRoot -Force | Out-Null
}

$timestamp = [DateTime]::UtcNow.ToString("yyyyMMdd_HHmmssZ")
$bundlePath = Join-Path $resolvedOutputRoot "backup_$timestamp"
New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null

$databaseDumpPath = Join-Path $bundlePath "postgres_gdms.dump"
$storageArchivePath = Join-Path $bundlePath "document_storage.zip"
$manifestPath = Join-Path $bundlePath "manifest.json"

Write-Host "Generando backup PostgreSQL..." -ForegroundColor Cyan
Invoke-DockerCapture -ArgumentList @(
    "exec",
    $resolvedPostgresContainerName,
    "pg_dump",
    "-U", $DatabaseUser,
    "-d", $DatabaseName,
    "-Fc",
    "--no-owner",
    "--no-privileges"
) -OutputPath $databaseDumpPath

Write-Host "Empaquetando storage documental..." -ForegroundColor Cyan
if (Test-Path -LiteralPath $storageArchivePath) {
    Remove-Item -LiteralPath $storageArchivePath -Force
}
[System.IO.Compression.ZipFile]::CreateFromDirectory($resolvedStorageRoot, $storageArchivePath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

$databaseHash = (Get-FileHash -Path $databaseDumpPath -Algorithm SHA256).Hash.ToLowerInvariant()
$storageHash = (Get-FileHash -Path $storageArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()

$manifest = [pscustomobject]@{
    createdAtUtc = [DateTime]::UtcNow.ToString("o")
    postgres = [pscustomobject]@{
        containerName = $resolvedPostgresContainerName
        serviceName = $PostgresServiceName
        databaseName = $DatabaseName
        databaseUser = $DatabaseUser
        dumpFile = [System.IO.Path]::GetFileName($databaseDumpPath)
        sha256 = $databaseHash
    }
    storage = [pscustomobject]@{
        sourcePath = $resolvedStorageRoot
        archiveFile = [System.IO.Path]::GetFileName($storageArchivePath)
        sha256 = $storageHash
    }
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding utf8

$summary = [pscustomobject]@{
    BundlePath = $bundlePath
    DatabaseDump = $databaseDumpPath
    DatabaseDumpMb = [Math]::Round((Get-Item -LiteralPath $databaseDumpPath).Length / 1MB, 2)
    StorageArchive = $storageArchivePath
    StorageArchiveMb = [Math]::Round((Get-Item -LiteralPath $storageArchivePath).Length / 1MB, 2)
}

$summary | Format-List
Write-Host "Backup local completado." -ForegroundColor Green
