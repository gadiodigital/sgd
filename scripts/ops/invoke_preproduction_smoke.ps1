param(
    [string]$ApiBaseUrl = "http://127.0.0.1:8080",
    [string]$PostgresHost = "127.0.0.1",
    [int]$PostgresPort = 5433,
    [switch]$IncludeScanHost,
    [string]$ScanHostBaseUrl = "http://127.0.0.1:43127",
    [int]$HttpRetryCount = 10,
    [int]$HttpRetryDelaySeconds = 3,
    [switch]$CaptureSnapshotOnFailure,
    [switch]$ValidateConfiguration,
    [bool]$StrictConfiguration = $true,
    [switch]$ValidateRuntimeConfiguration,
    [switch]$ValidateOperationalRisks,
    [switch]$ValidateCapacityHeadroom,
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$CapacityHeadroomProfile = "preproduction-strict",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$CapacityScenario = "preproduction-smoke",
    [switch]$ValidateCapacityTrend,
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$CapacityTrendProfile = "preproduction-strict",
    [switch]$ValidateRecoveryDrillThresholds,
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$RecoveryThresholdProfile = "preproduction-strict",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$RecoveryThresholdScenario = "preproduction-smoke"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

$results = [System.Collections.Generic.List[object]]::new()
$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [TimeSpan]::FromSeconds(15)

function Add-CheckResult {
    param(
        [string]$Name,
        [bool]$Success,
        [string]$Detail
    )

    $results.Add([pscustomobject]@{
        Check = $Name
        Status = if ($Success) { "OK" } else { "FAIL" }
        Detail = $Detail
    })
}

function Test-HttpJson {
    param(
        [string]$Name,
        [string]$Url,
        [scriptblock]$Assert
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $HttpRetryCount; $attempt++) {
        try {
            $json = $httpClient.GetStringAsync($Url).GetAwaiter().GetResult()
            $response = $json | ConvertFrom-Json
            $detail = & $Assert $response
            Add-CheckResult -Name $Name -Success $true -Detail $detail
            return
        } catch {
            $lastError = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { $_.ToString() }
            if ($attempt -lt $HttpRetryCount) {
                Start-Sleep -Seconds $HttpRetryDelaySeconds
            }
        }
    }

    Add-CheckResult -Name $Name -Success $false -Detail $lastError
}

function Test-HttpStatus {
    param(
        [string]$Name,
        [string]$Url
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $HttpRetryCount; $attempt++) {
        try {
            $response = $httpClient.GetAsync($Url).GetAwaiter().GetResult()
            [void]$response.EnsureSuccessStatusCode()
            Add-CheckResult -Name $Name -Success $true -Detail "Reachable"
            return
        } catch {
            $lastError = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { $_.ToString() }
            if ($attempt -lt $HttpRetryCount) {
                Start-Sleep -Seconds $HttpRetryDelaySeconds
            }
        }
    }

    Add-CheckResult -Name $Name -Success $false -Detail $lastError
}

Write-Host "Ejecutando smoke operativo de preproduccion..." -ForegroundColor Cyan

if ($ValidateConfiguration) {
    $configurationScript = Join-Path (Split-Path -Parent $PSCommandPath) "assert_operational_configuration.ps1"
    $configurationArgs = @(
        "-ExecutionPolicy", "Bypass",
        "-File", $configurationScript
    )
    if ($StrictConfiguration) {
        $configurationArgs += "-Strict"
    }

    & powershell @configurationArgs
    if ($LASTEXITCODE -ne 0) {
        throw "La validacion de configuracion operativa fallo."
    }
}

if ($ValidateRuntimeConfiguration) {
    $runtimeConfigurationScript = Join-Path (Split-Path -Parent $PSCommandPath) "assert_runtime_stack_configuration.ps1"
    & powershell -ExecutionPolicy Bypass -File $runtimeConfigurationScript
    if ($LASTEXITCODE -ne 0) {
        throw "La validacion de configuracion runtime fallo."
    }
}

if ($ValidateOperationalRisks) {
    $riskScript = Join-Path (Split-Path -Parent $PSCommandPath) "assert_operational_risks.ps1"
    & powershell -ExecutionPolicy Bypass -File $riskScript
    if ($LASTEXITCODE -ne 0) {
        throw "La validacion de riesgos operativos fallo."
    }
}

if ($ValidateCapacityHeadroom) {
    $capacityScript = Join-Path (Split-Path -Parent $PSCommandPath) "assert_capacity_headroom.ps1"
    & powershell -ExecutionPolicy Bypass -File $capacityScript -Profile $CapacityHeadroomProfile -Scenario $CapacityScenario
    if ($LASTEXITCODE -ne 0) {
        throw "La validacion de capacidad operativa fallo."
    }
}

if ($ValidateCapacityTrend) {
    $capacityTrendScript = Join-Path (Split-Path -Parent $PSCommandPath) "assert_capacity_trend.ps1"
    & powershell -ExecutionPolicy Bypass -File $capacityTrendScript -Profile $CapacityTrendProfile -Scenario $CapacityScenario
    if ($LASTEXITCODE -ne 0) {
        throw "La validacion de tendencia de capacidad fallo."
    }
}

if ($ValidateRecoveryDrillThresholds) {
    $recoveryThresholdScript = Join-Path (Split-Path -Parent $PSCommandPath) "assert_recovery_drill_thresholds.ps1"
    & powershell -ExecutionPolicy Bypass -File $recoveryThresholdScript -Profile $RecoveryThresholdProfile -Scenario $RecoveryThresholdScenario
    if ($LASTEXITCODE -ne 0) {
        throw "La validacion de thresholds de recovery fallo."
    }
}

Test-HttpJson -Name "API health" -Url "$ApiBaseUrl/api/health" -Assert {
    param($payload)

    if ($payload.status -ne "Healthy") {
        throw "Status inesperado: $($payload.status)"
    }

    "Healthy, docs en $($payload.documentation)"
}

Test-HttpStatus -Name "Swagger UI" -Url "$ApiBaseUrl/swagger/index.html"

try {
    $postgresReachable = Test-NetConnection -ComputerName $PostgresHost -Port $PostgresPort -WarningAction SilentlyContinue
    Add-CheckResult -Name "PostgreSQL port" -Success ([bool]$postgresReachable.TcpTestSucceeded) -Detail "${PostgresHost}:$PostgresPort"
} catch {
    Add-CheckResult -Name "PostgreSQL port" -Success $false -Detail $_.Exception.Message
}

if ($IncludeScanHost) {
    Test-HttpJson -Name "windows-twain health" -Url "$ScanHostBaseUrl/health" -Assert {
        param($payload)

        if (-not $payload.status) {
            throw "Payload sin campo status."
        }

        "$($payload.status) en $ScanHostBaseUrl"
    }

    Test-HttpJson -Name "windows-twain status" -Url "$ScanHostBaseUrl/api/status" -Assert {
        param($payload)

        if (-not $payload.runMode) {
            throw "Payload sin campo runMode."
        }

        if (-not $payload.operations -or $payload.operations.Count -eq 0) {
            throw "Payload sin operaciones publicadas."
        }

        "$($payload.runMode), operaciones: $($payload.operations.Count)"
    }

    Test-HttpJson -Name "windows-twain operations" -Url "$ScanHostBaseUrl/api/operations" -Assert {
        param($payload)

        $operationIds = @($payload | ForEach-Object { $_.id })
        foreach ($required in @('list-scanners', 'clear-active-sessions', 'scan-flatbed-single', 'export-pdf')) {
            if ($operationIds -notcontains $required) {
                throw "Falta la operacion requerida: $required"
            }
        }

        "$($operationIds.Count) operaciones visibles"
    }
}

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    if ($CaptureSnapshotOnFailure) {
        try {
            $snapshotScript = Join-Path (Split-Path -Parent $PSCommandPath) "get_local_operational_snapshot.ps1"
            if ($IncludeScanHost) {
                & $snapshotScript -ApiBaseUrl $ApiBaseUrl -IncludeScanHost -ScanHostBaseUrl $ScanHostBaseUrl | Out-Null
            } else {
                & $snapshotScript -ApiBaseUrl $ApiBaseUrl | Out-Null
            }
        } catch {
            Write-Warning "No se pudo generar el snapshot operativo automatico: $($_.Exception.Message)"
        }
    }

    throw "Smoke operativo fallido: $($failed.Count) chequeo(s) en rojo."
}

Write-Host "Smoke operativo completado en verde." -ForegroundColor Green
$httpClient.Dispose()
