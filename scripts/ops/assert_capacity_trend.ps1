param(
    [string]$MetricsHistoryPath = "",
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$Profile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$Scenario = "local-idle",
    [int]$RollingWindowSize = 5,
    [double]$RollingPercentile = 95,
    [double]$HostDriveFreeGbDropMargin = 2,
    [double]$StorageDriveFreeGbDropMargin = 2,
    [double]$PostgresDatabaseGrowthMarginMb = 64,
    [double]$DocumentStorageGrowthMarginMb = 64
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$profileOverrides = @{
    "local-light" = @{
        HostDriveFreeGbDropMargin = 2
        StorageDriveFreeGbDropMargin = 2
        PostgresDatabaseGrowthMarginMb = 64
        DocumentStorageGrowthMarginMb = 64
    }
    "preproduction-strict" = @{
        HostDriveFreeGbDropMargin = 1
        StorageDriveFreeGbDropMargin = 1
        PostgresDatabaseGrowthMarginMb = 32
        DocumentStorageGrowthMarginMb = 32
    }
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

function Add-CheckResult {
    param(
        [System.Collections.Generic.List[object]]$Results,
        [string]$Check,
        [bool]$Success,
        [string]$Detail
    )

    $Results.Add([pscustomobject]@{
        Check = $Check
        Status = if ($Success) { "OK" } else { "FAIL" }
        Detail = $Detail
    })
}

function Get-RecentProfileRuns {
    param(
        [object[]]$History,
        [string]$Profile,
        [string]$Scenario,
        [int]$WindowSize
    )

    $profileRuns = @(
        @($History) |
            Where-Object { $_.Profile -eq $Profile }
    )

    $scenarioRuns = @(
        $profileRuns |
            Where-Object {
                $null -ne $_.PSObject.Properties["Scenario"] -and
                -not [string]::IsNullOrWhiteSpace([string]$_.Scenario) -and
                $_.Scenario -eq $Scenario
            }
    )

    if ($scenarioRuns.Count -ge 2) {
        return [pscustomobject]@{
            BaselineSource = "scenario-tagged-only"
            SelectedRunCount = @($scenarioRuns | Select-Object -Last $WindowSize).Count
            ScenarioRunCount = $scenarioRuns.Count
            ProfileRunCount = $profileRuns.Count
            Runs = @($scenarioRuns | Select-Object -Last $WindowSize)
        }
    }

    if ($scenarioRuns.Count -gt 0) {
        $bootstrapRuns = @(
            $profileRuns |
                Where-Object {
                    ($null -ne $_.PSObject.Properties["Scenario"] -and
                        -not [string]::IsNullOrWhiteSpace([string]$_.Scenario) -and
                        $_.Scenario -eq $Scenario) -or
                    ($null -eq $_.PSObject.Properties["Scenario"] -or
                        [string]::IsNullOrWhiteSpace([string]$_.Scenario))
                }
        )

        return [pscustomobject]@{
            BaselineSource = "scenario-tagged-plus-legacy"
            SelectedRunCount = @($bootstrapRuns | Select-Object -Last $WindowSize).Count
            ScenarioRunCount = $scenarioRuns.Count
            ProfileRunCount = $profileRuns.Count
            Runs = @($bootstrapRuns | Select-Object -Last $WindowSize)
        }
    }

    return [pscustomobject]@{
        BaselineSource = "profile-legacy-only"
        SelectedRunCount = @($profileRuns | Select-Object -Last $WindowSize).Count
        ScenarioRunCount = 0
        ProfileRunCount = $profileRuns.Count
        Runs = @($profileRuns | Select-Object -Last $WindowSize)
    }
}

function Get-LowWatermarkTrendDetail {
    param(
        [object[]]$Runs,
        [string]$MetricName,
        [double]$Margin,
        [double]$Percentile
    )

    $latest = [double]$Runs[-1].Measurements.$MetricName
    $baselineRuns = @($Runs | Select-Object -SkipLast 1)
    if ($baselineRuns.Count -eq 0) {
        return [pscustomobject]@{
            Success = $true
            Mode = "fixed"
            Observed = $latest
            BaselineP50 = $null
            BaselinePercentile = $null
            BaselineAverage = $null
            EffectiveThreshold = $null
            Detail = "Observed=$latest, mode=fixed por muestra insuficiente."
        }
    }

    $values = @(
        $baselineRuns |
            ForEach-Object { [double]$_.Measurements.$MetricName } |
            Sort-Object
    )
    $medianIndex = [math]::Ceiling((50.0 / 100.0) * $values.Count) - 1
    $medianIndex = [math]::Max(0, [math]::Min($values.Count - 1, $medianIndex))
    $medianValue = [math]::Round($values[$medianIndex], 2)
    $percentileIndex = [math]::Ceiling(($Percentile / 100.0) * $values.Count) - 1
    $percentileIndex = [math]::Max(0, [math]::Min($values.Count - 1, $percentileIndex))
    $percentileValue = [math]::Round($values[$percentileIndex], 2)
    $baselineAverage = [math]::Round((($baselineRuns | ForEach-Object { [double]$_.Measurements.$MetricName } | Measure-Object -Average).Average), 2)
    $effectiveThreshold = [math]::Round(($percentileValue - $Margin), 2)
    return [pscustomobject]@{
        Success = ($latest -ge $effectiveThreshold)
        Mode = "rolling"
        Observed = $latest
        BaselineP50 = $medianValue
        BaselinePercentile = $percentileValue
        BaselineAverage = $baselineAverage
        EffectiveThreshold = $effectiveThreshold
        Detail = "Observed=$latest, p50-baseline=$medianValue, p$Percentile-baseline=$percentileValue, avg-baseline=$baselineAverage, allowed-drop=$Margin, effective-threshold>=$effectiveThreshold, mode=rolling."
    }
}

function Get-HighWatermarkTrendDetail {
    param(
        [object[]]$Runs,
        [string]$MetricName,
        [double]$Margin,
        [double]$Percentile
    )

    $latest = [double]$Runs[-1].Measurements.$MetricName
    $baselineRuns = @($Runs | Select-Object -SkipLast 1)
    if ($baselineRuns.Count -eq 0) {
        return [pscustomobject]@{
            Success = $true
            Mode = "fixed"
            Observed = $latest
            BaselineP50 = $null
            BaselinePercentile = $null
            BaselineAverage = $null
            EffectiveThreshold = $null
            Detail = "Observed=$latest, mode=fixed por muestra insuficiente."
        }
    }

    $values = @(
        $baselineRuns |
            ForEach-Object { [double]$_.Measurements.$MetricName } |
            Sort-Object
    )
    $medianIndex = [math]::Ceiling((50.0 / 100.0) * $values.Count) - 1
    $medianIndex = [math]::Max(0, [math]::Min($values.Count - 1, $medianIndex))
    $medianValue = [math]::Round($values[$medianIndex], 2)
    $percentileIndex = [math]::Ceiling(($Percentile / 100.0) * $values.Count) - 1
    $percentileIndex = [math]::Max(0, [math]::Min($values.Count - 1, $percentileIndex))
    $percentileValue = [math]::Round($values[$percentileIndex], 2)
    $baselineAverage = [math]::Round((($baselineRuns | ForEach-Object { [double]$_.Measurements.$MetricName } | Measure-Object -Average).Average), 2)
    $effectiveThreshold = [math]::Round(($percentileValue + $Margin), 2)
    return [pscustomobject]@{
        Success = ($latest -le $effectiveThreshold)
        Mode = "rolling"
        Observed = $latest
        BaselineP50 = $medianValue
        BaselinePercentile = $percentileValue
        BaselineAverage = $baselineAverage
        EffectiveThreshold = $effectiveThreshold
        Detail = "Observed=$latest, p50-baseline=$medianValue, p$Percentile-baseline=$percentileValue, avg-baseline=$baselineAverage, allowed-growth=$Margin, effective-threshold<=$effectiveThreshold, mode=rolling."
    }
}

$repoRoot = Get-RepoRoot
$capacityMetricsRoot = Join-Path $repoRoot "artifacts\ops\capacity_metrics"
Ensure-Directory -Path $capacityMetricsRoot
$selectedProfile = $profileOverrides[$Profile]
$HostDriveFreeGbDropMargin = $selectedProfile.HostDriveFreeGbDropMargin
$StorageDriveFreeGbDropMargin = $selectedProfile.StorageDriveFreeGbDropMargin
$PostgresDatabaseGrowthMarginMb = $selectedProfile.PostgresDatabaseGrowthMarginMb
$DocumentStorageGrowthMarginMb = $selectedProfile.DocumentStorageGrowthMarginMb
$artifactSuffix = "$Profile.$Scenario"
$summaryJsonPath = Join-Path $capacityMetricsRoot "trend_summary.$artifactSuffix.json"
$summaryMarkdownPath = Join-Path $capacityMetricsRoot "trend_summary.$artifactSuffix.md"
$resolvedMetricsHistoryPath = if ([string]::IsNullOrWhiteSpace($MetricsHistoryPath)) {
    Join-Path $capacityMetricsRoot "history.jsonl"
} else {
    [System.IO.Path]::GetFullPath($MetricsHistoryPath)
}

if (-not (Test-Path -LiteralPath $resolvedMetricsHistoryPath)) {
    throw "No existe el historial de capacidad '$resolvedMetricsHistoryPath'."
}

$history = @(
    Get-Content -Path $resolvedMetricsHistoryPath |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_ | ConvertFrom-Json }
)

if ($history.Count -eq 0) {
    throw "El historial de capacidad esta vacio."
}

$selectedRuns = Get-RecentProfileRuns -History $history -Profile $Profile -Scenario $Scenario -WindowSize $RollingWindowSize
$baselineSource = [string]$selectedRuns.BaselineSource
$selectedRunCount = [int]$selectedRuns.SelectedRunCount
$scenarioRunCount = [int]$selectedRuns.ScenarioRunCount
$profileRunCount = [int]$selectedRuns.ProfileRunCount
$runs = @($selectedRuns.Runs)
if ($runs.Count -eq 0) {
    throw "No existen corridas de capacidad para el perfil '$Profile'."
}

$hostDriveTrend = Get-LowWatermarkTrendDetail -Runs $runs -MetricName "HostDriveFreeGb" -Margin $HostDriveFreeGbDropMargin -Percentile $RollingPercentile
$storageDriveTrend = Get-LowWatermarkTrendDetail -Runs $runs -MetricName "DocumentStorageDriveFreeGb" -Margin $StorageDriveFreeGbDropMargin -Percentile $RollingPercentile
$postgresGrowthTrend = Get-HighWatermarkTrendDetail -Runs $runs -MetricName "PostgresDatabaseSizeMb" -Margin $PostgresDatabaseGrowthMarginMb -Percentile $RollingPercentile
$storageGrowthTrend = Get-HighWatermarkTrendDetail -Runs $runs -MetricName "DocumentStorageSizeMb" -Margin $DocumentStorageGrowthMarginMb -Percentile $RollingPercentile

$results = [System.Collections.Generic.List[object]]::new()
Add-CheckResult -Results $results -Check "Host drive free space trend" -Success $hostDriveTrend.Success -Detail $hostDriveTrend.Detail
Add-CheckResult -Results $results -Check "Document storage drive free space trend" -Success $storageDriveTrend.Success -Detail $storageDriveTrend.Detail
Add-CheckResult -Results $results -Check "PostgreSQL main database growth trend" -Success $postgresGrowthTrend.Success -Detail $postgresGrowthTrend.Detail
Add-CheckResult -Results $results -Check "Document storage growth trend" -Success $storageGrowthTrend.Success -Detail $storageGrowthTrend.Detail

$summary = [ordered]@{
    GeneratedAtUtc = [DateTimeOffset]::UtcNow.ToString("o")
    Profile = $Profile
    Scenario = $Scenario
    BaselineSource = $baselineSource
    SelectedRunCount = $selectedRunCount
    ScenarioRunCount = $scenarioRunCount
    ProfileRunCount = $profileRunCount
    Margins = [ordered]@{
        HostDriveFreeGbDropMargin = $HostDriveFreeGbDropMargin
        StorageDriveFreeGbDropMargin = $StorageDriveFreeGbDropMargin
        PostgresDatabaseGrowthMarginMb = $PostgresDatabaseGrowthMarginMb
        DocumentStorageGrowthMarginMb = $DocumentStorageGrowthMarginMb
    }
    RollingWindowSize = $RollingWindowSize
    RollingPercentile = $RollingPercentile
    Metrics = @(
        [ordered]@{
            MetricName = "HostDriveFreeGb"
            Direction = "low-watermark"
            Observed = $hostDriveTrend.Observed
            BaselineP50 = $hostDriveTrend.BaselineP50
            BaselineP95 = $hostDriveTrend.BaselinePercentile
            BaselineAverage = $hostDriveTrend.BaselineAverage
            EffectiveThreshold = $hostDriveTrend.EffectiveThreshold
            Mode = $hostDriveTrend.Mode
        }
        [ordered]@{
            MetricName = "DocumentStorageDriveFreeGb"
            Direction = "low-watermark"
            Observed = $storageDriveTrend.Observed
            BaselineP50 = $storageDriveTrend.BaselineP50
            BaselineP95 = $storageDriveTrend.BaselinePercentile
            BaselineAverage = $storageDriveTrend.BaselineAverage
            EffectiveThreshold = $storageDriveTrend.EffectiveThreshold
            Mode = $storageDriveTrend.Mode
        }
        [ordered]@{
            MetricName = "PostgresDatabaseSizeMb"
            Direction = "high-watermark"
            Observed = $postgresGrowthTrend.Observed
            BaselineP50 = $postgresGrowthTrend.BaselineP50
            BaselineP95 = $postgresGrowthTrend.BaselinePercentile
            BaselineAverage = $postgresGrowthTrend.BaselineAverage
            EffectiveThreshold = $postgresGrowthTrend.EffectiveThreshold
            Mode = $postgresGrowthTrend.Mode
        }
        [ordered]@{
            MetricName = "DocumentStorageSizeMb"
            Direction = "high-watermark"
            Observed = $storageGrowthTrend.Observed
            BaselineP50 = $storageGrowthTrend.BaselineP50
            BaselineP95 = $storageGrowthTrend.BaselinePercentile
            BaselineAverage = $storageGrowthTrend.BaselineAverage
            EffectiveThreshold = $storageGrowthTrend.EffectiveThreshold
            Mode = $storageGrowthTrend.Mode
        }
    )
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryJsonPath -Encoding utf8

$mdTick = [char]96
$summaryMarkdown = @(
    "# Capacity Trend Summary"
    ""
    "- GeneratedAtUtc: $mdTick$($summary.GeneratedAtUtc)$mdTick"
    "- Profile: $mdTick$($summary.Profile)$mdTick"
    "- Scenario: $mdTick$($summary.Scenario)$mdTick"
    "- BaselineSource: $mdTick$($summary.BaselineSource)$mdTick"
    "- SelectedRunCount: $mdTick$($summary.SelectedRunCount)$mdTick"
    "- ScenarioRunCount: $mdTick$($summary.ScenarioRunCount)$mdTick"
    "- ProfileRunCount: $mdTick$($summary.ProfileRunCount)$mdTick"
    "- HostDriveFreeGbDropMargin: $mdTick$($summary.Margins.HostDriveFreeGbDropMargin)$mdTick"
    "- StorageDriveFreeGbDropMargin: $mdTick$($summary.Margins.StorageDriveFreeGbDropMargin)$mdTick"
    "- PostgresDatabaseGrowthMarginMb: $mdTick$($summary.Margins.PostgresDatabaseGrowthMarginMb)$mdTick"
    "- DocumentStorageGrowthMarginMb: $mdTick$($summary.Margins.DocumentStorageGrowthMarginMb)$mdTick"
    "- RollingWindowSize: $mdTick$($summary.RollingWindowSize)$mdTick"
    "- RollingPercentile: $mdTick" + "p$($summary.RollingPercentile)" + "$mdTick"
    ""
)

foreach ($metric in $summary.Metrics) {
    $summaryMarkdown += "- $($metric.MetricName): direction=$mdTick$($metric.Direction)$mdTick, observed=$mdTick$($metric.Observed)$mdTick, p50=$mdTick$($metric.BaselineP50)$mdTick, p95=$mdTick$($metric.BaselineP95)$mdTick, avg=$mdTick$($metric.BaselineAverage)$mdTick, threshold=$mdTick$($metric.EffectiveThreshold)$mdTick, mode=$mdTick$($metric.Mode)$mdTick"
}

Set-Content -Path $summaryMarkdownPath -Value $summaryMarkdown -Encoding utf8

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Tendencia de capacidad fuera de rango: $($failed.Count) chequeo(s) en rojo."
}

Write-Host "Tendencia de capacidad validada en verde para perfil '$Profile' y escenario '$Scenario'." -ForegroundColor Green
