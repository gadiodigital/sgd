param(
    [string]$DotEnvPath = "",
    [string]$ApiContainerName = "gdms-api"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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

function Resolve-RunningContainerName {
    param(
        [string]$PreferredName,
        [int]$RetryCount = 5,
        [int]$RetryDelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $runningNames = @(docker ps --format "{{.Names}}")
        if ($LASTEXITCODE -eq 0) {
            if ($runningNames -contains $PreferredName) {
                return $PreferredName
            }

            $partialMatch = @($runningNames | Where-Object { $_ -like "*$PreferredName*" } | Select-Object -First 1)
            if ($partialMatch.Count -gt 0) {
                return $partialMatch[0]
            }
        }

        if ($attempt -lt $RetryCount) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    return ""
}

$repoRoot = Get-RepoRoot
$resolvedDotEnvPath = if ([string]::IsNullOrWhiteSpace($DotEnvPath)) {
    Join-Path $repoRoot ".env"
} else {
    [System.IO.Path]::GetFullPath($DotEnvPath)
}

$dotEnvValues = Read-DotEnvValues -Path $resolvedDotEnvPath
$containerName = Resolve-RunningContainerName -PreferredName $ApiContainerName
if (-not $containerName) {
    throw "No se encontro un contenedor API corriendo con nombre '$ApiContainerName'."
}

$containerEnvLines = docker inspect $containerName --format "{{range .Config.Env}}{{println .}}{{end}}"
$containerEnv = @{}
foreach ($line in $containerEnvLines) {
    $separatorIndex = $line.IndexOf("=")
    if ($separatorIndex -lt 1) {
        continue
    }

    $containerEnv[$line.Substring(0, $separatorIndex)] = $line.Substring($separatorIndex + 1)
}

$results = [System.Collections.Generic.List[object]]::new()

$expectedMappings = @(
    @{ Name = "ASPNETCORE_ENVIRONMENT"; DotEnvKey = "GDMS_ASPNETCORE_ENVIRONMENT"; ContainerKey = "ASPNETCORE_ENVIRONMENT" },
    @{ Name = "ApiRuntime__EnableHttpsRedirection"; DotEnvKey = "GDMS_API_ENABLE_HTTPS_REDIRECTION"; ContainerKey = "ApiRuntime__EnableHttpsRedirection" },
    @{ Name = "Firebase__UseEmulator"; DotEnvKey = "GDMS_FIREBASE_USE_EMULATOR"; ContainerKey = "Firebase__UseEmulator" },
    @{ Name = "Firebase__ProjectId"; DotEnvKey = "GDMS_FIREBASE_PROJECT_ID"; ContainerKey = "Firebase__ProjectId" },
    @{ Name = "Jwt__Issuer"; DotEnvKey = "GDMS_JWT_ISSUER"; ContainerKey = "Jwt__Issuer" },
    @{ Name = "Jwt__Audience"; DotEnvKey = "GDMS_JWT_AUDIENCE"; ContainerKey = "Jwt__Audience" }
)

foreach ($mapping in $expectedMappings) {
    $expectedValue = if ($dotEnvValues.ContainsKey($mapping.DotEnvKey)) { $dotEnvValues[$mapping.DotEnvKey] } else { "" }
    $runtimeValue = if ($containerEnv.ContainsKey($mapping.ContainerKey)) { $containerEnv[$mapping.ContainerKey] } else { "" }

    if ([string]::IsNullOrWhiteSpace($expectedValue)) {
        Add-CheckResult -Results $results -Name $mapping.Name -Status "WARN" -Detail "No hay valor esperado en .env."
    } elseif ($expectedValue -eq $runtimeValue) {
        Add-CheckResult -Results $results -Name $mapping.Name -Status "OK" -Detail "Runtime alineado con .env."
    } else {
        Add-CheckResult -Results $results -Name $mapping.Name -Status "FAIL" -Detail "Runtime='$runtimeValue' difiere de .env='$expectedValue'."
    }
}

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Configuracion runtime desalineada: $($failed.Count) chequeo(s) en rojo."
}

$warnings = @($results | Where-Object Status -eq "WARN")
if ($warnings.Count -gt 0) {
    Write-Warning "Configuracion runtime con advertencias: $($warnings.Count)."
} else {
    Write-Host "Configuracion runtime validada en verde." -ForegroundColor Green
}
