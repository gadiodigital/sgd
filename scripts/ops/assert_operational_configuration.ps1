param(
    [string]$ApiAppSettingsPath = "",
    [string]$ApiDevelopmentSettingsPath = "",
    [string]$ComposeFilePath = "",
    [string]$DotEnvPath = "",
    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

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

function Get-FirstMatchingValue {
    param(
        [string[]]$Lines,
        [string]$Pattern
    )

    foreach ($line in $Lines) {
        if ($line -match $Pattern) {
            return $Matches[1]
        }
    }

    return ""
}

function Read-DotEnvValues {
    param([string]$Path)

    $values = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $values
    }

    foreach ($line in Get-Content -Path $Path) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $separatorIndex = $line.IndexOf("=")
        if ($separatorIndex -lt 1) {
            continue
        }

        $key = $line.Substring(0, $separatorIndex).Trim()
        $value = $line.Substring($separatorIndex + 1).Trim()
        $values[$key] = $value
    }

    return $values
}

$repoRoot = Get-RepoRoot
$resolvedAppSettingsPath = if ([string]::IsNullOrWhiteSpace($ApiAppSettingsPath)) {
    Join-Path $repoRoot "server\src\Gdms.Api\appsettings.json"
} else {
    [System.IO.Path]::GetFullPath($ApiAppSettingsPath)
}

$resolvedDevelopmentSettingsPath = if ([string]::IsNullOrWhiteSpace($ApiDevelopmentSettingsPath)) {
    Join-Path $repoRoot "server\src\Gdms.Api\appsettings.Development.json"
} else {
    [System.IO.Path]::GetFullPath($ApiDevelopmentSettingsPath)
}

$resolvedComposeFilePath = if ([string]::IsNullOrWhiteSpace($ComposeFilePath)) {
    Join-Path $repoRoot "docker-compose.yml"
} else {
    [System.IO.Path]::GetFullPath($ComposeFilePath)
}

$resolvedDotEnvPath = if ([string]::IsNullOrWhiteSpace($DotEnvPath)) {
    Join-Path $repoRoot ".env"
} else {
    [System.IO.Path]::GetFullPath($DotEnvPath)
}

$appSettings = Get-Content -Path $resolvedAppSettingsPath -Raw | ConvertFrom-Json
$developmentSettings = Get-Content -Path $resolvedDevelopmentSettingsPath -Raw | ConvertFrom-Json
$composeLines = Get-Content -Path $resolvedComposeFilePath
$dotEnvValues = Read-DotEnvValues -Path $resolvedDotEnvPath
$results = [System.Collections.Generic.List[object]]::new()

$jwtSigningKey = [string]$appSettings.Jwt.SigningKey
$devJwtSigningKey = [string]$developmentSettings.Jwt.SigningKey
$allowAnyOrigin = [bool]$developmentSettings.Cors.AllowAnyOriginInDevelopment
$firebaseEmulator = [bool]$developmentSettings.Firebase.UseEmulator
$developmentPostgresConnection = [string]$developmentSettings.Postgres.MainDatabase
$composeAspNetCoreEnvironment = if ($dotEnvValues.ContainsKey("GDMS_ASPNETCORE_ENVIRONMENT")) { $dotEnvValues["GDMS_ASPNETCORE_ENVIRONMENT"] } else { "Development" }
$composePostgresPassword = if ($dotEnvValues.ContainsKey("GDMS_POSTGRES_PASSWORD")) { $dotEnvValues["GDMS_POSTGRES_PASSWORD"] } else { "gdms_dev_password" }
$composeFirebaseUseEmulator = if ($dotEnvValues.ContainsKey("GDMS_FIREBASE_USE_EMULATOR")) { $dotEnvValues["GDMS_FIREBASE_USE_EMULATOR"] } else { "true" }
$composeJwtSigningKey = if ($dotEnvValues.ContainsKey("GDMS_JWT_SIGNING_KEY")) { $dotEnvValues["GDMS_JWT_SIGNING_KEY"] } else { "" }
$composeUsesJwtOverride = Get-FirstMatchingValue -Lines $composeLines -Pattern '^\s*Jwt__SigningKey:\s*(.+)$'
$isDevelopmentLike = "$composeAspNetCoreEnvironment".Trim().ToLowerInvariant() -eq "development"
$usesFirebaseEmulator = "$composeFirebaseUseEmulator".Trim().ToLowerInvariant() -eq "true"
$usesPlaceholderJwtSigningKey = $composeJwtSigningKey -match '^change-this-'
$usesPlaceholderPostgresPassword = $composePostgresPassword -match '^change-this-'

if ([string]::IsNullOrWhiteSpace($jwtSigningKey) -and [string]::IsNullOrWhiteSpace($devJwtSigningKey) -and [string]::IsNullOrWhiteSpace($composeJwtSigningKey)) {
    Add-CheckResult -Results $results -Name "JWT signing key" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "No hay Jwt:SigningKey configurada ni por archivo ni por .env."
} else {
    Add-CheckResult -Results $results -Name "JWT signing key" -Status "OK" -Detail "Existe una clave JWT efectiva por archivo o .env."
}

if ([string]::IsNullOrWhiteSpace($composeUsesJwtOverride)) {
    Add-CheckResult -Results $results -Name "docker compose JWT override" -Status "FAIL" -Detail "docker-compose no expone Jwt__SigningKey a la API."
} elseif ([string]::IsNullOrWhiteSpace($composeJwtSigningKey)) {
    Add-CheckResult -Results $results -Name "docker compose JWT override" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "docker-compose no define Jwt__SigningKey para la API."
} elseif ($usesPlaceholderJwtSigningKey) {
    Add-CheckResult -Results $results -Name "docker compose JWT override" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "docker-compose usa un placeholder de Jwt__SigningKey."
} else {
    Add-CheckResult -Results $results -Name "docker compose JWT override" -Status "OK" -Detail "docker-compose define Jwt__SigningKey."
}

if ($isDevelopmentLike -and $allowAnyOrigin) {
    Add-CheckResult -Results $results -Name "CORS abierto en Development" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "AllowAnyOriginInDevelopment=true con ASPNETCORE_ENVIRONMENT=Development."
} else {
    Add-CheckResult -Results $results -Name "CORS abierto en Development" -Status "OK" -Detail "El entorno efectivo no expone CORS abierto por development."
}

if ($usesFirebaseEmulator) {
    Add-CheckResult -Results $results -Name "Firebase emulator" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "La configuracion efectiva usa Firebase emulator."
} else {
    Add-CheckResult -Results $results -Name "Firebase emulator" -Status "OK" -Detail "Firebase no esta en modo emulator."
}

if ($isDevelopmentLike) {
    Add-CheckResult -Results $results -Name "ASPNETCORE_ENVIRONMENT" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "docker-compose levanta la API en Development."
} else {
    Add-CheckResult -Results $results -Name "ASPNETCORE_ENVIRONMENT" -Status "OK" -Detail "docker-compose usa $composeAspNetCoreEnvironment."
}

if ($composePostgresPassword -eq 'gdms_dev_password') {
    Add-CheckResult -Results $results -Name "Credenciales PostgreSQL" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "Se detecto la password de desarrollo gdms_dev_password en el entorno efectivo."
} elseif ($usesPlaceholderPostgresPassword) {
    Add-CheckResult -Results $results -Name "Credenciales PostgreSQL" -Status ($(if ($Strict) { "FAIL" } else { "WARN" })) -Detail "El entorno efectivo usa un placeholder de password PostgreSQL."
} else {
    Add-CheckResult -Results $results -Name "Credenciales PostgreSQL" -Status "OK" -Detail "No se detectaron credenciales de desarrollo conocidas."
}

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Configuracion operativa invalida: $($failed.Count) chequeo(s) en rojo."
}

$warnings = @($results | Where-Object Status -eq "WARN")
if ($warnings.Count -gt 0) {
    Write-Warning "Configuracion operativa con advertencias: $($warnings.Count)."
} else {
    Write-Host "Configuracion operativa validada en verde." -ForegroundColor Green
}
