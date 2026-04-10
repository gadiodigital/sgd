param(
    [string]$MetricsHistoryPath = "",
    [ValidateSet("local-light", "preproduction-strict")]
    [string]$Profile = "local-light",
    [ValidateSet("local-idle", "preproduction-smoke")]
    [string]$Scenario = "local-idle",
    [int]$TempRestoreMaxRtoMs = 22000,
    [int]$StackReprovisionMaxRtoMs = 24000,
    [int]$TempRestoreMaxValidationMs = 19000,
    [int]$StackReprovisionMaxValidationMs = 14000,
    [int]$TempRestoreMaxRpoMs = 25000,
    [int]$StackReprovisionMaxRpoMs = 26000,
    [int]$RollingWindowSize = 5,
    [int]$TempRestoreRtoMarginMs = 3000,
    [int]$TempRestoreValidationMarginMs = 3000,
    [int]$StackReprovisionRtoMarginMs = 4000,
    [int]$StackReprovisionValidationMarginMs = 3000,
    [int]$TempRestoreRpoMarginMs = 4000,
    [int]$StackReprovisionRpoMarginMs = 4000,
    [double]$RollingPercentile = 95
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Get-SafeArtifactSuffix {
    param([string]$Value)

    return ($Value -replace "[^A-Za-z0-9_.-]", "_")
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

function Get-RecentSuccessfulRuns {
    param(
        [object[]]$History,
        [string]$DrillType,
        [int]$WindowSize,
        [string]$Profile,
        [string]$Scenario
    )

    $allSucceededRuns = @(
        @($History) |
            Where-Object { $_.DrillType -eq $DrillType -and $_.Status -eq "Succeeded" }
    )

    $profileSpecificRuns = @(
        $allSucceededRuns |
            Where-Object {
                $null -ne $_.PSObject.Properties["MetricsProfile"] -and
                -not [string]::IsNullOrWhiteSpace([string]$_.MetricsProfile) -and
                $_.MetricsProfile -eq $Profile
            }
    )

    $scenarioSpecificRuns = @(
        $profileSpecificRuns |
            Where-Object {
                $null -ne $_.PSObject.Properties["MetricsScenario"] -and
                -not [string]::IsNullOrWhiteSpace([string]$_.MetricsScenario) -and
                $_.MetricsScenario -eq $Scenario
            }
    )

    $legacyRuns = @(
        $allSucceededRuns |
            Where-Object {
                $null -eq $_.PSObject.Properties["MetricsProfile"] -or
                [string]::IsNullOrWhiteSpace([string]$_.MetricsProfile)
            }
    )

    $minimumTaggedRunsForRolling = 3

    if ($scenarioSpecificRuns.Count -ge $minimumTaggedRunsForRolling) {
        return [pscustomobject]@{
            BaselineSource = "scenario-tagged-only"
            SelectedRunCount = @($scenarioSpecificRuns | Select-Object -Last $WindowSize).Count
            ScenarioRunCount = $scenarioSpecificRuns.Count
            ProfileRunCount = $profileSpecificRuns.Count
            LegacyRunCount = $legacyRuns.Count
            Runs = @($scenarioSpecificRuns | Select-Object -Last $WindowSize)
        }
    }

    if ($scenarioSpecificRuns.Count -gt 0) {
        $bootstrapRuns = @(
            $allSucceededRuns |
                Where-Object {
                    ($null -ne $_.PSObject.Properties["MetricsScenario"] -and
                        -not [string]::IsNullOrWhiteSpace([string]$_.MetricsScenario) -and
                        $_.MetricsScenario -eq $Scenario) -or
                    (($null -eq $_.PSObject.Properties["MetricsScenario"] -or
                        [string]::IsNullOrWhiteSpace([string]$_.MetricsScenario)) -and
                        $null -ne $_.PSObject.Properties["MetricsProfile"] -and
                        -not [string]::IsNullOrWhiteSpace([string]$_.MetricsProfile) -and
                        $_.MetricsProfile -eq $Profile) -or
                    ($null -eq $_.PSObject.Properties["MetricsProfile"] -or
                        [string]::IsNullOrWhiteSpace([string]$_.MetricsProfile))
                }
        )

        return [pscustomobject]@{
            BaselineSource = "scenario-tagged-plus-profile-legacy"
            SelectedRunCount = @($bootstrapRuns | Select-Object -Last $WindowSize).Count
            ScenarioRunCount = $scenarioSpecificRuns.Count
            ProfileRunCount = $profileSpecificRuns.Count
            LegacyRunCount = $legacyRuns.Count
            Runs = @($bootstrapRuns | Select-Object -Last $WindowSize)
        }
    }

    if ($profileSpecificRuns.Count -ge $minimumTaggedRunsForRolling) {
        return [pscustomobject]@{
            BaselineSource = "profile-tagged-only"
            SelectedRunCount = @($profileSpecificRuns | Select-Object -Last $WindowSize).Count
            ScenarioRunCount = 0
            ProfileRunCount = $profileSpecificRuns.Count
            LegacyRunCount = $legacyRuns.Count
            Runs = @($profileSpecificRuns | Select-Object -Last $WindowSize)
        }
    }

    if ($profileSpecificRuns.Count -gt 0) {
        $profileBootstrapRuns = @(
            $allSucceededRuns |
                Where-Object {
                    ($null -ne $_.PSObject.Properties["MetricsProfile"] -and
                        -not [string]::IsNullOrWhiteSpace([string]$_.MetricsProfile) -and
                        $_.MetricsProfile -eq $Profile) -or
                    ($null -eq $_.PSObject.Properties["MetricsProfile"] -or
                        [string]::IsNullOrWhiteSpace([string]$_.MetricsProfile))
                }
        )

        return [pscustomobject]@{
            BaselineSource = "profile-tagged-plus-legacy"
            SelectedRunCount = @($profileBootstrapRuns | Select-Object -Last $WindowSize).Count
            ScenarioRunCount = 0
            ProfileRunCount = $profileSpecificRuns.Count
            LegacyRunCount = $legacyRuns.Count
            Runs = @($profileBootstrapRuns | Select-Object -Last $WindowSize)
        }
    }

    return [pscustomobject]@{
        BaselineSource = "legacy-only"
        SelectedRunCount = @($legacyRuns | Select-Object -Last $WindowSize).Count
        ScenarioRunCount = 0
        ProfileRunCount = 0
        LegacyRunCount = $legacyRuns.Count
        Runs = @($legacyRuns | Select-Object -Last $WindowSize)
    }
}

function Get-DynamicThresholdDetail {
    param(
        [object[]]$Runs,
        [string]$MetricName,
        [int]$FixedThreshold,
        [int]$MarginMs,
        [double]$Percentile
    )

    $latestRun = $Runs[-1]
    $baselineRuns = @($Runs | Select-Object -SkipLast 1)
    $baselineRuns = @(
        $baselineRuns |
            Where-Object {
                $null -ne $_.PSObject.Properties[$MetricName] -and
                $null -ne $_.$MetricName -and
                "$($_.$MetricName)" -ne ""
        }
    )

    if ($baselineRuns.Count -eq 0) {
        return [pscustomobject]@{
            Threshold = $FixedThreshold
            Mode = "fixed"
            BaselineP50Ms = $null
            BaselinePercentileMs = $null
            BaselineAverageMs = $null
            MarginMs = $MarginMs
            ObservedMs = [int]$latestRun.$MetricName
            Detail = "Observed=$($latestRun.$MetricName) ms, fixed-threshold=$FixedThreshold ms, mode=fixed."
        }
    }

    $values = @(
        $baselineRuns |
            ForEach-Object { [double]($_.$MetricName) } |
            Sort-Object
    )
    $medianIndex = [math]::Ceiling((50.0 / 100.0) * $values.Count) - 1
    $medianIndex = [math]::Max(0, [math]::Min($values.Count - 1, $medianIndex))
    $medianValue = [math]::Round($values[$medianIndex], 0)
    $index = [math]::Ceiling(($Percentile / 100.0) * $values.Count) - 1
    $index = [math]::Max(0, [math]::Min($values.Count - 1, $index))
    $percentileValue = [math]::Round($values[$index], 0)
    $average = [math]::Round((($baselineRuns | Measure-Object -Property $MetricName -Average).Average), 0)
    $dynamicThreshold = [int]$percentileValue + $MarginMs
    $effectiveThreshold = [math]::Min([int]::MaxValue, [math]::Max($FixedThreshold, $dynamicThreshold))

    return [pscustomobject]@{
        Threshold = $effectiveThreshold
        Mode = "rolling"
        BaselineP50Ms = [int]$medianValue
        BaselinePercentileMs = [int]$percentileValue
        BaselineAverageMs = [int]$average
        MarginMs = $MarginMs
        ObservedMs = [int]$latestRun.$MetricName
        Detail = "Observed=$($latestRun.$MetricName) ms, p50-baseline=$medianValue ms, p$Percentile-baseline=$percentileValue ms, avg-baseline=$average ms, margin=$MarginMs ms, effective-threshold=$effectiveThreshold ms, mode=rolling."
    }
}

$repoRoot = Get-RepoRoot
$metricsRoot = Join-Path $repoRoot "artifacts\ops\recovery_metrics"
Ensure-Directory -Path $metricsRoot
$profileSuffix = Get-SafeArtifactSuffix -Value $Profile
$scenarioSuffix = Get-SafeArtifactSuffix -Value $Scenario
$summaryJsonPath = Join-Path $metricsRoot "threshold_summary.json"
$summaryMarkdownPath = Join-Path $metricsRoot "threshold_summary.md"
$profileSummaryJsonPath = Join-Path $metricsRoot ("threshold_summary.{0}.json" -f $profileSuffix)
$profileSummaryMarkdownPath = Join-Path $metricsRoot ("threshold_summary.{0}.md" -f $profileSuffix)
$scenarioSummaryJsonPath = Join-Path $metricsRoot ("threshold_summary.{0}.{1}.json" -f $profileSuffix, $scenarioSuffix)
$scenarioSummaryMarkdownPath = Join-Path $metricsRoot ("threshold_summary.{0}.{1}.md" -f $profileSuffix, $scenarioSuffix)
$resolvedMetricsHistoryPath = if ([string]::IsNullOrWhiteSpace($MetricsHistoryPath)) {
    Join-Path $metricsRoot "history.jsonl"
} else {
    [System.IO.Path]::GetFullPath($MetricsHistoryPath)
}

if (-not (Test-Path -LiteralPath $resolvedMetricsHistoryPath)) {
    throw "No existe el historial de metricas '$resolvedMetricsHistoryPath'."
}

$history = Get-Content -Path $resolvedMetricsHistoryPath |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_ | ConvertFrom-Json }

if (-not $history -or $history.Count -eq 0) {
    throw "El historial de metricas esta vacio."
}

$profileOverrides = @{
    "local-light" = @{
        TempRestoreMaxRtoMs = 22000
        StackReprovisionMaxRtoMs = 24000
        TempRestoreMaxValidationMs = 19000
        StackReprovisionMaxValidationMs = 14000
        TempRestoreMaxRpoMs = 25000
        StackReprovisionMaxRpoMs = 26000
        TempRestoreRtoMarginMs = 3000
        TempRestoreValidationMarginMs = 3000
        StackReprovisionRtoMarginMs = 4000
        StackReprovisionValidationMarginMs = 3000
        TempRestoreRpoMarginMs = 4000
        StackReprovisionRpoMarginMs = 4000
    }
    "preproduction-strict" = @{
        TempRestoreMaxRtoMs = 19500
        StackReprovisionMaxRtoMs = 21000
        TempRestoreMaxValidationMs = 17900
        StackReprovisionMaxValidationMs = 13250
        TempRestoreMaxRpoMs = 22000
        StackReprovisionMaxRpoMs = 22000
        TempRestoreRtoMarginMs = 750
        TempRestoreValidationMarginMs = 750
        StackReprovisionRtoMarginMs = 750
        StackReprovisionValidationMarginMs = 750
        TempRestoreRpoMarginMs = 1250
        StackReprovisionRpoMarginMs = 750
    }
}

$selectedProfile = $profileOverrides[$Profile]
$TempRestoreMaxRtoMs = $selectedProfile.TempRestoreMaxRtoMs
$StackReprovisionMaxRtoMs = $selectedProfile.StackReprovisionMaxRtoMs
$TempRestoreMaxValidationMs = $selectedProfile.TempRestoreMaxValidationMs
$StackReprovisionMaxValidationMs = $selectedProfile.StackReprovisionMaxValidationMs
$TempRestoreMaxRpoMs = $selectedProfile.TempRestoreMaxRpoMs
$StackReprovisionMaxRpoMs = $selectedProfile.StackReprovisionMaxRpoMs
$TempRestoreRtoMarginMs = $selectedProfile.TempRestoreRtoMarginMs
$TempRestoreValidationMarginMs = $selectedProfile.TempRestoreValidationMarginMs
$StackReprovisionRtoMarginMs = $selectedProfile.StackReprovisionRtoMarginMs
$StackReprovisionValidationMarginMs = $selectedProfile.StackReprovisionValidationMarginMs
$TempRestoreRpoMarginMs = $selectedProfile.TempRestoreRpoMarginMs
$StackReprovisionRpoMarginMs = $selectedProfile.StackReprovisionRpoMarginMs

$results = [System.Collections.Generic.List[object]]::new()

$tempRestoreSelection = Get-RecentSuccessfulRuns -History $history -DrillType "temp_restore_validation" -WindowSize $RollingWindowSize -Profile $Profile -Scenario $Scenario
$stackReprovisionSelection = Get-RecentSuccessfulRuns -History $history -DrillType "stack_reprovision" -WindowSize $RollingWindowSize -Profile $Profile -Scenario $Scenario
$tempRestoreRuns = @($tempRestoreSelection.Runs)
$stackReprovisionRuns = @($stackReprovisionSelection.Runs)

if ($tempRestoreRuns.Count -eq 0) {
    throw "No existe una corrida exitosa de 'temp_restore_validation' en el historial."
}

if ($stackReprovisionRuns.Count -eq 0) {
    throw "No existe una corrida exitosa de 'stack_reprovision' en el historial."
}

$tempRestore = $tempRestoreRuns[-1]
$stackReprovision = $stackReprovisionRuns[-1]
$tempRestoreRtoThreshold = Get-DynamicThresholdDetail -Runs $tempRestoreRuns -MetricName "RtoObservedMs" -FixedThreshold $TempRestoreMaxRtoMs -MarginMs $TempRestoreRtoMarginMs -Percentile $RollingPercentile
$tempRestoreValidationThreshold = Get-DynamicThresholdDetail -Runs $tempRestoreRuns -MetricName "ValidationExecutionMs" -FixedThreshold $TempRestoreMaxValidationMs -MarginMs $TempRestoreValidationMarginMs -Percentile $RollingPercentile
$tempRestoreRpoThreshold = Get-DynamicThresholdDetail -Runs $tempRestoreRuns -MetricName "RpoObservedMs" -FixedThreshold $TempRestoreMaxRpoMs -MarginMs $TempRestoreRpoMarginMs -Percentile $RollingPercentile
$stackReprovisionRtoThreshold = Get-DynamicThresholdDetail -Runs $stackReprovisionRuns -MetricName "RtoObservedMs" -FixedThreshold $StackReprovisionMaxRtoMs -MarginMs $StackReprovisionRtoMarginMs -Percentile $RollingPercentile
$stackReprovisionValidationThreshold = Get-DynamicThresholdDetail -Runs $stackReprovisionRuns -MetricName "ValidationExecutionMs" -FixedThreshold $StackReprovisionMaxValidationMs -MarginMs $StackReprovisionValidationMarginMs -Percentile $RollingPercentile
$stackReprovisionRpoThreshold = Get-DynamicThresholdDetail -Runs $stackReprovisionRuns -MetricName "RpoObservedMs" -FixedThreshold $StackReprovisionMaxRpoMs -MarginMs $StackReprovisionRpoMarginMs -Percentile $RollingPercentile

Add-CheckResult -Results $results -Check "Temp restore RTO" `
    -Success ($tempRestore.RtoObservedMs -le $tempRestoreRtoThreshold.Threshold) `
    -Detail $tempRestoreRtoThreshold.Detail

Add-CheckResult -Results $results -Check "Temp restore validation window" `
    -Success ($tempRestore.ValidationExecutionMs -le $tempRestoreValidationThreshold.Threshold) `
    -Detail $tempRestoreValidationThreshold.Detail

Add-CheckResult -Results $results -Check "Temp restore RPO" `
    -Success ($tempRestore.RpoObservedMs -le $tempRestoreRpoThreshold.Threshold) `
    -Detail $tempRestoreRpoThreshold.Detail

Add-CheckResult -Results $results -Check "Stack reprovision RTO" `
    -Success ($stackReprovision.RtoObservedMs -le $stackReprovisionRtoThreshold.Threshold) `
    -Detail $stackReprovisionRtoThreshold.Detail

Add-CheckResult -Results $results -Check "Stack reprovision validation window" `
    -Success ($stackReprovision.ValidationExecutionMs -le $stackReprovisionValidationThreshold.Threshold) `
    -Detail $stackReprovisionValidationThreshold.Detail

Add-CheckResult -Results $results -Check "Stack reprovision RPO" `
    -Success ($stackReprovision.RpoObservedMs -le $stackReprovisionRpoThreshold.Threshold) `
    -Detail $stackReprovisionRpoThreshold.Detail

$summary = [ordered]@{
    GeneratedAtUtc = [DateTimeOffset]::UtcNow.ToString("o")
    Profile = $Profile
    Scenario = $Scenario
    ArtifactSuffix = $profileSuffix
    RollingWindowSize = $RollingWindowSize
    RollingPercentile = $RollingPercentile
    DrillTypes = @(
        [ordered]@{
            DrillType = "temp_restore_validation"
            BaselineSource = $tempRestoreSelection.BaselineSource
            SelectedRunCount = $tempRestoreSelection.SelectedRunCount
            ScenarioRunCount = $tempRestoreSelection.ScenarioRunCount
            ProfileRunCount = $tempRestoreSelection.ProfileRunCount
            LegacyRunCount = $tempRestoreSelection.LegacyRunCount
            Metrics = @(
                [ordered]@{
                    MetricName = "RtoObservedMs"
                    ObservedMs = $tempRestoreRtoThreshold.ObservedMs
                    BaselineP50Ms = $tempRestoreRtoThreshold.BaselineP50Ms
                    BaselineP95Ms = $tempRestoreRtoThreshold.BaselinePercentileMs
                    BaselineAverageMs = $tempRestoreRtoThreshold.BaselineAverageMs
                    MarginMs = $tempRestoreRtoThreshold.MarginMs
                    EffectiveThresholdMs = $tempRestoreRtoThreshold.Threshold
                    Mode = $tempRestoreRtoThreshold.Mode
                }
                [ordered]@{
                    MetricName = "ValidationExecutionMs"
                    ObservedMs = $tempRestoreValidationThreshold.ObservedMs
                    BaselineP50Ms = $tempRestoreValidationThreshold.BaselineP50Ms
                    BaselineP95Ms = $tempRestoreValidationThreshold.BaselinePercentileMs
                    BaselineAverageMs = $tempRestoreValidationThreshold.BaselineAverageMs
                    MarginMs = $tempRestoreValidationThreshold.MarginMs
                    EffectiveThresholdMs = $tempRestoreValidationThreshold.Threshold
                    Mode = $tempRestoreValidationThreshold.Mode
                }
                [ordered]@{
                    MetricName = "RpoObservedMs"
                    ObservedMs = $tempRestoreRpoThreshold.ObservedMs
                    BaselineP50Ms = $tempRestoreRpoThreshold.BaselineP50Ms
                    BaselineP95Ms = $tempRestoreRpoThreshold.BaselinePercentileMs
                    BaselineAverageMs = $tempRestoreRpoThreshold.BaselineAverageMs
                    MarginMs = $tempRestoreRpoThreshold.MarginMs
                    EffectiveThresholdMs = $tempRestoreRpoThreshold.Threshold
                    Mode = $tempRestoreRpoThreshold.Mode
                }
            )
        }
        [ordered]@{
            DrillType = "stack_reprovision"
            BaselineSource = $stackReprovisionSelection.BaselineSource
            SelectedRunCount = $stackReprovisionSelection.SelectedRunCount
            ScenarioRunCount = $stackReprovisionSelection.ScenarioRunCount
            ProfileRunCount = $stackReprovisionSelection.ProfileRunCount
            LegacyRunCount = $stackReprovisionSelection.LegacyRunCount
            Metrics = @(
                [ordered]@{
                    MetricName = "RtoObservedMs"
                    ObservedMs = $stackReprovisionRtoThreshold.ObservedMs
                    BaselineP50Ms = $stackReprovisionRtoThreshold.BaselineP50Ms
                    BaselineP95Ms = $stackReprovisionRtoThreshold.BaselinePercentileMs
                    BaselineAverageMs = $stackReprovisionRtoThreshold.BaselineAverageMs
                    MarginMs = $stackReprovisionRtoThreshold.MarginMs
                    EffectiveThresholdMs = $stackReprovisionRtoThreshold.Threshold
                    Mode = $stackReprovisionRtoThreshold.Mode
                }
                [ordered]@{
                    MetricName = "ValidationExecutionMs"
                    ObservedMs = $stackReprovisionValidationThreshold.ObservedMs
                    BaselineP50Ms = $stackReprovisionValidationThreshold.BaselineP50Ms
                    BaselineP95Ms = $stackReprovisionValidationThreshold.BaselinePercentileMs
                    BaselineAverageMs = $stackReprovisionValidationThreshold.BaselineAverageMs
                    MarginMs = $stackReprovisionValidationThreshold.MarginMs
                    EffectiveThresholdMs = $stackReprovisionValidationThreshold.Threshold
                    Mode = $stackReprovisionValidationThreshold.Mode
                }
                [ordered]@{
                    MetricName = "RpoObservedMs"
                    ObservedMs = $stackReprovisionRpoThreshold.ObservedMs
                    BaselineP50Ms = $stackReprovisionRpoThreshold.BaselineP50Ms
                    BaselineP95Ms = $stackReprovisionRpoThreshold.BaselinePercentileMs
                    BaselineAverageMs = $stackReprovisionRpoThreshold.BaselineAverageMs
                    MarginMs = $stackReprovisionRpoThreshold.MarginMs
                    EffectiveThresholdMs = $stackReprovisionRpoThreshold.Threshold
                    Mode = $stackReprovisionRpoThreshold.Mode
                }
            )
        }
    )
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryJsonPath -Encoding utf8
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $profileSummaryJsonPath -Encoding utf8
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $scenarioSummaryJsonPath -Encoding utf8

$mdTick = [char]96
$summaryMarkdown = @(
    "# Recovery Threshold Summary"
    ""
    "- GeneratedAtUtc: $mdTick$($summary.GeneratedAtUtc)$mdTick"
    "- Profile: $mdTick$($summary.Profile)$mdTick"
    "- Scenario: $mdTick$($summary.Scenario)$mdTick"
    "- RollingWindowSize: $mdTick$($summary.RollingWindowSize)$mdTick"
    "- RollingPercentile: $mdTick" + "p$($summary.RollingPercentile)" + "$mdTick"
    ""
)

foreach ($drillSummary in $summary.DrillTypes) {
    $summaryMarkdown += "## $($drillSummary.DrillType)"
    $summaryMarkdown += ""
    $summaryMarkdown += "- BaselineSource: $mdTick$($drillSummary.BaselineSource)$mdTick"
    $summaryMarkdown += "- SelectedRunCount: $mdTick$($drillSummary.SelectedRunCount)$mdTick"
    $summaryMarkdown += "- ScenarioRunCount: $mdTick$($drillSummary.ScenarioRunCount)$mdTick"
    $summaryMarkdown += "- ProfileRunCount: $mdTick$($drillSummary.ProfileRunCount)$mdTick"
    $summaryMarkdown += "- LegacyRunCount: $mdTick$($drillSummary.LegacyRunCount)$mdTick"
    $summaryMarkdown += ""
    foreach ($metric in $drillSummary.Metrics) {
        $summaryMarkdown += (
            "- {0}: observed={8}{1} ms{8}, p50={8}{2} ms{8}, p95={8}{3} ms{8}, avg={8}{4} ms{8}, margin={8}{5} ms{8}, threshold={8}{6} ms{8}, mode={8}{7}{8}" -f `
                $metric.MetricName,
                $metric.ObservedMs,
                $metric.BaselineP50Ms,
                $metric.BaselineP95Ms,
                $metric.BaselineAverageMs,
                $metric.MarginMs,
                $metric.EffectiveThresholdMs,
                $metric.Mode,
                $mdTick
        )
    }
    $summaryMarkdown += ""
}

Set-Content -Path $summaryMarkdownPath -Value $summaryMarkdown -Encoding utf8
Set-Content -Path $profileSummaryMarkdownPath -Value $summaryMarkdown -Encoding utf8
Set-Content -Path $scenarioSummaryMarkdownPath -Value $summaryMarkdown -Encoding utf8

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Thresholds de recovery fuera de rango: $($failed.Count) chequeo(s) en rojo."
}

Write-Host "Thresholds de recovery validados en verde." -ForegroundColor Green
