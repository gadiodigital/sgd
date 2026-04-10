param(
    [string]$ApiBaseUrl = "http://127.0.0.1:8080",
    [string]$PostgresHost = "127.0.0.1",
    [int]$PostgresPort = 5433,
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$CapacityHeadroomProfile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$CapacityScenario = "local-idle",
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$CapacityTrendProfile = "local-light",
    [switch]$IncludeScanHost,
    [string]$ScanHostBaseUrl = "http://127.0.0.1:43127",
    [string]$SnapshotPath = "C:\IA\codex\artifacts\ops\local_operational_snapshot.txt",
    [string]$SummaryJsonPath = "",
    [string]$SummaryMarkdownPath = "",
    [int]$DockerLogTail = 80,
    [int]$FileLogTail = 80
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

$snapshotDirectory = Split-Path -Parent $SnapshotPath
if (-not (Test-Path -Path $snapshotDirectory)) {
    New-Item -ItemType Directory -Path $snapshotDirectory -Force | Out-Null
}

$resolvedSummaryJsonPath = if ([string]::IsNullOrWhiteSpace($SummaryJsonPath)) {
    [System.IO.Path]::ChangeExtension($SnapshotPath, ".json")
} else {
    $SummaryJsonPath
}

$resolvedSummaryMarkdownPath = if ([string]::IsNullOrWhiteSpace($SummaryMarkdownPath)) {
    [System.IO.Path]::ChangeExtension($SnapshotPath, ".md")
} else {
    $SummaryMarkdownPath
}

$summaryJsonDirectory = Split-Path -Parent $resolvedSummaryJsonPath
if (-not (Test-Path -Path $summaryJsonDirectory)) {
    New-Item -ItemType Directory -Path $summaryJsonDirectory -Force | Out-Null
}

$summaryMarkdownDirectory = Split-Path -Parent $resolvedSummaryMarkdownPath
if (-not (Test-Path -Path $summaryMarkdownDirectory)) {
    New-Item -ItemType Directory -Path $summaryMarkdownDirectory -Force | Out-Null
}

$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [TimeSpan]::FromSeconds(15)
$lines = [System.Collections.Generic.List[string]]::new()
$checks = [System.Collections.Generic.List[object]]::new()
$generatedAt = Get-Date -Format o

function Add-Line {
    param([string]$Text = "")
    $lines.Add($Text)
}

function Add-Section {
    param([string]$Title)
    Add-Line "=== $Title ==="
}

function Add-CheckResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail,
        [string]$Source = "snapshot"
    )

    $checks.Add([pscustomobject]@{
        Check = $Name
        Status = $Status
        Detail = $Detail
        Source = $Source
    })
}

function Invoke-LoggedCommand {
    param(
        [string]$Label,
        [string]$Command,
        [string]$CheckName = ""
    )

    Add-Section $Label
    try {
        $output = powershell -NoProfile -Command $Command 2>&1
        if ($output) {
            foreach ($line in $output) {
                Add-Line "$line"
            }
        } else {
            Add-Line "(sin salida)"
        }
        if (-not [string]::IsNullOrWhiteSpace($CheckName)) {
            Add-CheckResult -Name $CheckName -Status "OK" -Detail "Comando ejecutado correctamente." -Source $Label
        }
    } catch {
        Add-Line "ERROR: $($_.Exception.Message)"
        if (-not [string]::IsNullOrWhiteSpace($CheckName)) {
            Add-CheckResult -Name $CheckName -Status "FAIL" -Detail $_.Exception.Message -Source $Label
        }
    }
    Add-Line
}

function Invoke-HttpJson {
    param(
        [string]$Label,
        [string]$Url,
        [string]$CheckName = "",
        [scriptblock]$Assert = $null
    )

    Add-Section $Label
    try {
        $json = $httpClient.GetStringAsync($Url).GetAwaiter().GetResult()
        $payload = $json | ConvertFrom-Json
        $payload | ConvertTo-Json -Depth 10 | ForEach-Object { Add-Line $_ }
        if (-not [string]::IsNullOrWhiteSpace($CheckName)) {
            $detail = if ($null -ne $Assert) { & $Assert $payload } else { "Payload JSON obtenido correctamente." }
            Add-CheckResult -Name $CheckName -Status "OK" -Detail $detail -Source $Label
        }
    } catch {
        Add-Line "ERROR: $($_.Exception.Message)"
        if (-not [string]::IsNullOrWhiteSpace($CheckName)) {
            Add-CheckResult -Name $CheckName -Status "FAIL" -Detail $_.Exception.Message -Source $Label
        }
    }
    Add-Line
}

function Invoke-PortCheck {
    param(
        [string]$Label,
        [string]$TargetHost,
        [int]$Port
    )

    Add-Section $Label
    try {
        $result = Test-NetConnection -ComputerName $TargetHost -Port $Port -WarningAction SilentlyContinue
        Add-Line ("ComputerName: {0}" -f $result.ComputerName)
        Add-Line ("RemotePort: {0}" -f $result.RemotePort)
        Add-Line ("TcpTestSucceeded: {0}" -f $result.TcpTestSucceeded)
        Add-CheckResult -Name $Label -Status $(if ($result.TcpTestSucceeded) { "OK" } else { "FAIL" }) -Detail "${TargetHost}:$Port" -Source "port-check"
    } catch {
        Add-Line "ERROR: $($_.Exception.Message)"
        Add-CheckResult -Name $Label -Status "FAIL" -Detail $_.Exception.Message -Source "port-check"
    }
    Add-Line
}

function Invoke-ScriptSnapshot {
    param([string]$Label)

    $ScriptPath = $null
    $CheckName = $null
    $Arguments = @()

    switch ($Label) {
        "effective operational configuration" {
            $ScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "assert_operational_configuration.ps1"
            $CheckName = "Operational configuration"
        }
        "runtime stack configuration" {
            $ScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "assert_runtime_stack_configuration.ps1"
            $CheckName = "Runtime stack configuration"
        }
        "operational risks" {
            $ScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "assert_operational_risks.ps1"
            $CheckName = "Operational risks"
        }
        "capacity headroom" {
            $ScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "assert_capacity_headroom.ps1"
            $CheckName = "Capacity headroom"
            $Arguments = @("-Profile", $CapacityHeadroomProfile, "-Scenario", $CapacityScenario)
        }
        "capacity trend" {
            $ScriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "assert_capacity_trend.ps1"
            $CheckName = "Capacity trend"
            $Arguments = @("-Profile", $CapacityTrendProfile, "-Scenario", $CapacityScenario)
        }
        default {
            throw "Snapshot script label no soportado: $Label"
        }
    }

    Add-Section $Label
    try {
        $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
        if ($output) {
            foreach ($line in $output) {
                Add-Line "$line"
            }
        } else {
            Add-Line "(sin salida)"
        }

        if ($LASTEXITCODE -eq 0) {
            Add-CheckResult -Name $CheckName -Status "OK" -Detail "Validacion completada sin errores." -Source $Label
        } else {
            Add-CheckResult -Name $CheckName -Status "FAIL" -Detail "ExitCode: $LASTEXITCODE" -Source $Label
        }
    } catch {
        Add-Line "ERROR: $($_.Exception.Message)"
        Add-CheckResult -Name $CheckName -Status "FAIL" -Detail $_.Exception.Message -Source $Label
    }
    Add-Line
}

function Invoke-ApiEnvExcerpt {
    Add-Section "api container env excerpt"
    try {
        $containerName = docker ps --filter "name=gdms-api" --format "{{.Names}}" | Select-Object -First 1
        if (-not $containerName) {
            Add-Line "gdms-api no esta corriendo"
            Add-CheckResult -Name "API container env excerpt" -Status "WARN" -Detail "gdms-api no esta corriendo." -Source "docker inspect"
        } else {
            $envLines = docker inspect $containerName --format "{{range .Config.Env}}{{println .}}{{end}}"
            foreach ($line in $envLines) {
                if ($line -match '^(ASPNETCORE_ENVIRONMENT|Postgres__MainDatabase|Firebase__ProjectId|Firebase__UseEmulator|Jwt__Issuer|Jwt__Audience)=') {
                    Add-Line $line
                }
                if ($line -match '^(ApiRuntime__EnableHttpsRedirection)=') {
                    Add-Line $line
                }
            }
            Add-CheckResult -Name "API container env excerpt" -Status "OK" -Detail "Variables efectivas del contenedor capturadas." -Source "docker inspect"
        }
    } catch {
        Add-Line "ERROR: $($_.Exception.Message)"
        Add-CheckResult -Name "API container env excerpt" -Status "FAIL" -Detail $_.Exception.Message -Source "docker inspect"
    }
    Add-Line
}

function Write-SummaryArtifacts {
    $statusOrder = @{
        FAIL = 0
        WARN = 1
        OK   = 2
    }

    $orderedChecks = @($checks | Sort-Object { $statusOrder[$_.Status] }, Check)
    $okCount = @($orderedChecks | Where-Object Status -eq "OK").Count
    $warnCount = @($orderedChecks | Where-Object Status -eq "WARN").Count
    $failCount = @($orderedChecks | Where-Object Status -eq "FAIL").Count
    $overallStatus = if ($failCount -gt 0) { "FAIL" } elseif ($warnCount -gt 0) { "WARN" } else { "OK" }

    $summary = [pscustomobject]@{
        GeneratedAt = $generatedAt
        SnapshotPath = $SnapshotPath
        IncludeScanHost = [bool]$IncludeScanHost
        ApiBaseUrl = $ApiBaseUrl
        PostgresHost = $PostgresHost
        PostgresPort = $PostgresPort
        CapacityHeadroomProfile = $CapacityHeadroomProfile
        CapacityTrendProfile = $CapacityTrendProfile
        CapacityScenario = $CapacityScenario
        OverallStatus = $overallStatus
        Counts = [pscustomobject]@{
            OK = $okCount
            WARN = $warnCount
            FAIL = $failCount
        }
        Checks = $orderedChecks
    }

    $summary | ConvertTo-Json -Depth 6 | Set-Content -Path $resolvedSummaryJsonPath

    $markdown = [System.Collections.Generic.List[string]]::new()
    $markdown.Add("# GDMS Local Operational Snapshot Summary")
    $markdown.Add("")
    $markdown.Add("- GeneratedAt: $generatedAt")
    $markdown.Add("- OverallStatus: $overallStatus")
    $markdown.Add("- SnapshotPath: $SnapshotPath")
    $markdown.Add("- IncludeScanHost: $([bool]$IncludeScanHost)")
    $markdown.Add("- API: $ApiBaseUrl")
    $markdown.Add("- PostgreSQL: ${PostgresHost}:$PostgresPort")
    $markdown.Add("- CapacityProfile: $CapacityHeadroomProfile / Trend=$CapacityTrendProfile / Scenario=$CapacityScenario")
    $markdown.Add("- Counts: OK=$okCount WARN=$warnCount FAIL=$failCount")
    $markdown.Add("")
    $markdown.Add("| Check | Status | Detail | Source |")
    $markdown.Add("| --- | --- | --- | --- |")
    foreach ($check in $orderedChecks) {
        $detail = ($check.Detail -replace '\|', '\|' -replace "`r?`n", ' ').Trim()
        $source = ($check.Source -replace '\|', '\|').Trim()
        $markdown.Add("| $($check.Check) | $($check.Status) | $detail | $source |")
    }

    $markdown | Set-Content -Path $resolvedSummaryMarkdownPath
}

Add-Line "GDMS local operational snapshot"
Add-Line "GeneratedAt: $generatedAt"
Add-Line

Invoke-LoggedCommand -Label "docker compose ps" -Command "cd C:\IA\codex; docker compose ps" -CheckName "docker compose ps"
Invoke-LoggedCommand -Label "docker ps --format" -Command 'docker ps --format ''table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}''' -CheckName "docker ps summary"
Invoke-ScriptSnapshot -Label "effective operational configuration"
Invoke-ScriptSnapshot -Label "runtime stack configuration"
Invoke-ScriptSnapshot -Label "operational risks"
Invoke-ScriptSnapshot -Label "capacity headroom"
Invoke-ScriptSnapshot -Label "capacity trend"
Invoke-PortCheck -Label "postgres port check" -TargetHost $PostgresHost -Port $PostgresPort
Invoke-HttpJson -Label "api health" -Url "$ApiBaseUrl/api/health" -CheckName "API health" -Assert {
    param($payload)

    if ($payload.status -ne "Healthy") {
        throw "Status inesperado: $($payload.status)"
    }

    "Healthy"
}
Invoke-ApiEnvExcerpt

Invoke-LoggedCommand -Label "docker compose logs api --tail $DockerLogTail" -Command "cd C:\IA\codex; docker compose logs api --tail $DockerLogTail"
Invoke-LoggedCommand -Label "docker compose logs postgres --tail $DockerLogTail" -Command "cd C:\IA\codex; docker compose logs postgres --tail $DockerLogTail"

if ($IncludeScanHost) {
    Invoke-PortCheck -Label "windows-twain port check" -TargetHost "127.0.0.1" -Port 43127
    Invoke-HttpJson -Label "windows-twain health" -Url "$ScanHostBaseUrl/health" -CheckName "windows-twain health" -Assert {
        param($payload)

        if (-not $payload.status) {
            throw "Payload sin campo status."
        }

        "$($payload.status)"
    }
    Invoke-HttpJson -Label "windows-twain status" -Url "$ScanHostBaseUrl/api/status" -CheckName "windows-twain status" -Assert {
        param($payload)

        if (-not $payload.runMode) {
            throw "Payload sin campo runMode."
        }

        "$($payload.runMode)"
    }

    try {
        $statusJson = $httpClient.GetStringAsync("$ScanHostBaseUrl/api/status").GetAwaiter().GetResult()
        $status = $statusJson | ConvertFrom-Json
        if ($status.startupLogPath -and (Test-Path -Path $status.startupLogPath)) {
            Add-Section "windows-twain startup log tail"
            Get-Content -Path $status.startupLogPath -Tail $FileLogTail | ForEach-Object { Add-Line $_ }
            Add-Line
            Add-CheckResult -Name "windows-twain startup log tail" -Status "OK" -Detail "Tail capturado desde $($status.startupLogPath)." -Source "file-tail"
        }
    } catch {
        Add-Section "windows-twain startup log tail"
        Add-Line "ERROR: $($_.Exception.Message)"
        Add-Line
        Add-CheckResult -Name "windows-twain startup log tail" -Status "FAIL" -Detail $_.Exception.Message -Source "file-tail"
    }
}

$lines | Set-Content -Path $SnapshotPath
Write-SummaryArtifacts
$httpClient.Dispose()

Write-Host "Snapshot operativo generado en $SnapshotPath" -ForegroundColor Green
Write-Host "Resumen JSON generado en $resolvedSummaryJsonPath" -ForegroundColor Green
Write-Host "Resumen Markdown generado en $resolvedSummaryMarkdownPath" -ForegroundColor Green
