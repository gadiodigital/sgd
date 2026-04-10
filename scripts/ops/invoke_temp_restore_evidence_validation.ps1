param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDatabaseName,
    [Parameter(Mandatory = $true)]
    [string]$TargetStorageRoot,
    [string]$ApiBaseUrl = "http://127.0.0.1:18080",
    [string]$PostgresContainerName = "gdms-postgres",
    [string]$PostgresServiceName = "postgres",
    [string]$SuccessMarkerPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

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

function Resolve-PostgresPassword {
    param(
        [hashtable]$DotEnvValues,
        [string]$PreferredContainerName,
        [string]$ServiceName
    )

    if (-not [string]::IsNullOrWhiteSpace("$env:GDMS_POSTGRES_PASSWORD")) {
        return "$env:GDMS_POSTGRES_PASSWORD"
    }

    try {
        $containerName = Resolve-PostgresContainerName -PreferredContainerName $PreferredContainerName -ServiceName $ServiceName
        $containerPassword = (& docker exec $containerName printenv POSTGRES_PASSWORD 2>$null)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$containerPassword")) {
            return "$containerPassword".Trim()
        }
    } catch {
    }

    if ($DotEnvValues.ContainsKey("GDMS_POSTGRES_PASSWORD")) {
        return $DotEnvValues["GDMS_POSTGRES_PASSWORD"]
    }

    return "gdms_dev_password"
}

function Test-TcpPortFree {
    param([int]$Port)

    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
    try {
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        try {
            $listener.Stop()
        } catch {
        }
    }
}

function Get-AvailableApiBaseUrl {
    param([string]$RequestedBaseUrl)

    $requestedUri = [System.Uri]$RequestedBaseUrl
    if (Test-TcpPortFree -Port $requestedUri.Port) {
        return $RequestedBaseUrl
    }

    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        $dynamicPort = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    } finally {
        $listener.Stop()
    }

    return "{0}://{1}:{2}" -f $requestedUri.Scheme, $requestedUri.Host, $dynamicPort
}

function Wait-ApiHealthy {
    param(
        [string]$Url,
        [int]$RetryCount = 40,
        [int]$RetryDelaySeconds = 2
    )

    $httpClient = [System.Net.Http.HttpClient]::new()
    $httpClient.Timeout = [TimeSpan]::FromSeconds(5)
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

    throw "La API efimera no quedo healthy en '$Url' dentro del tiempo esperado."
}

function Wait-HttpReady {
    param(
        [string]$Url,
        [int]$RetryCount = 30,
        [int]$RetryDelaySeconds = 1
    )

    $httpClient = [System.Net.Http.HttpClient]::new()
    $httpClient.Timeout = [TimeSpan]::FromSeconds(5)
    try {
        for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
            try {
                $response = $httpClient.GetAsync($Url).GetAwaiter().GetResult()
                if ($response.IsSuccessStatusCode) {
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

    throw "La API efimera no respondio correctamente en '$Url'."
}

$repoRoot = Get-RepoRoot
$resolvedStorageRoot = [System.IO.Path]::GetFullPath($TargetStorageRoot)
$dotEnvPath = Join-Path $repoRoot ".env"
$dotEnvValues = Read-DotEnvValues -Path $dotEnvPath
$postgresPassword = Resolve-PostgresPassword -DotEnvValues $dotEnvValues -PreferredContainerName $PostgresContainerName -ServiceName $PostgresServiceName
$effectiveApiBaseUrl = Get-AvailableApiBaseUrl -RequestedBaseUrl $ApiBaseUrl
$evidencePackageScript = Join-Path $PSScriptRoot "assert_evidence_package_export.ps1"
$apiProjectPath = Join-Path $repoRoot "server\src\Gdms.Api\Gdms.Api.csproj"
$apiHealthUrl = "$effectiveApiBaseUrl/api/health"
$swaggerReadyUrl = "$effectiveApiBaseUrl/swagger/v1/swagger.json"
$apiUri = [System.Uri]$effectiveApiBaseUrl

$stdoutPath = Join-Path $repoRoot "artifacts\ops\temp_restore_api.stdout.log"
$stderrPath = Join-Path $repoRoot "artifacts\ops\temp_restore_api.stderr.log"
if (Test-Path -LiteralPath $stdoutPath) {
    Remove-Item -LiteralPath $stdoutPath -Force
}
if (Test-Path -LiteralPath $stderrPath) {
    Remove-Item -LiteralPath $stderrPath -Force
}

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = "dotnet"
$startInfo.Arguments = "run --project `"$apiProjectPath`" --no-launch-profile --urls $effectiveApiBaseUrl"
$startInfo.WorkingDirectory = $repoRoot
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.Environment["ASPNETCORE_ENVIRONMENT"] = "PreProduction"
$startInfo.Environment["Postgres__MainDatabase"] = "Host=127.0.0.1;Port=5433;Database=$TargetDatabaseName;Username=gdms;Password=$postgresPassword;SSL Mode=Disable"
$startInfo.Environment["Storage__LocalRootPath"] = $resolvedStorageRoot
$startInfo.Environment["ApiRuntime__EnableHttpsRedirection"] = "false"
$startInfo.Environment["Firebase__UseEmulator"] = "false"
$startInfo.Environment["Jwt__SigningKey"] = "TemporaryEvidenceValidationSigningKey-2026-04-09"
$startInfo.Environment["Jwt__Issuer"] = "gdms-api-temp-restore"
$startInfo.Environment["Jwt__Audience"] = "gdms-clients-temp-restore"

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo

$stdoutWriter = [System.IO.StreamWriter]::new($stdoutPath, $false)
$stderrWriter = [System.IO.StreamWriter]::new($stderrPath, $false)
$outputHandler = [System.Diagnostics.DataReceivedEventHandler]{
    param($sender, $args)
    if ($null -ne $args.Data) {
        $stdoutWriter.WriteLine($args.Data)
        $stdoutWriter.Flush()
    }
}
$errorHandler = [System.Diagnostics.DataReceivedEventHandler]{
    param($sender, $args)
    if ($null -ne $args.Data) {
        $stderrWriter.WriteLine($args.Data)
        $stderrWriter.Flush()
    }
}

try {
    [void]$process.Start()
    $process.add_OutputDataReceived($outputHandler)
    $process.add_ErrorDataReceived($errorHandler)
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    Wait-ApiHealthy -Url $apiHealthUrl
    Wait-HttpReady -Url $swaggerReadyUrl

    Invoke-PowerShellScript -ScriptPath $evidencePackageScript -ArgumentList @(
        "-ApiBaseUrl", $effectiveApiBaseUrl,
        "-TargetDatabaseName", $TargetDatabaseName
    )

    [pscustomobject]@{
        ApiBaseUrl = $effectiveApiBaseUrl
        TargetDatabaseName = $TargetDatabaseName
        TargetStorageRoot = $resolvedStorageRoot
        ProcessId = $process.Id
        StdoutLog = $stdoutPath
        StderrLog = $stderrPath
    } | Format-List

    Write-Host "Evidence package sobre API efimera validado en verde." -ForegroundColor Green
    if (-not [string]::IsNullOrWhiteSpace($SuccessMarkerPath)) {
        $resolvedSuccessMarkerPath = [System.IO.Path]::GetFullPath($SuccessMarkerPath)
        Set-Content -Path $resolvedSuccessMarkerPath -Value ([DateTime]::UtcNow.ToString("o")) -Encoding utf8
    }
} catch {
    Start-Sleep -Milliseconds 500
    $stdoutTail = if (Test-Path -LiteralPath $stdoutPath) {
        (Get-Content -Path $stdoutPath -Tail 40 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
    } else {
        ""
    }
    $stderrTail = if (Test-Path -LiteralPath $stderrPath) {
        (Get-Content -Path $stderrPath -Tail 40 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
    } else {
        ""
    }

    $diagnostic = @()
    $diagnostic += "Fallo la validacion del evidence package sobre API efimera."
    $diagnostic += "Stdout: $stdoutPath"
    $diagnostic += "Stderr: $stderrPath"
    if (-not [string]::IsNullOrWhiteSpace($stdoutTail)) {
        $diagnostic += "Stdout tail:"
        $diagnostic += $stdoutTail
    }
    if (-not [string]::IsNullOrWhiteSpace($stderrTail)) {
        $diagnostic += "Stderr tail:"
        $diagnostic += $stderrTail
    }

    throw ($diagnostic -join [Environment]::NewLine)
} finally {
    if (-not $process.HasExited) {
        $process.Kill()
        $process.WaitForExit()
    }
    $stdoutWriter.Dispose()
    $stderrWriter.Dispose()
    $process.Dispose()
}
