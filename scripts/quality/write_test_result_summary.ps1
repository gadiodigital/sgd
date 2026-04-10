param(
    [Parameter(Mandatory = $true)]
    [string]$TrxPath,
    [string]$OutputDirectory = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "artifacts\test-results"),
    [string]$SummaryBaseName = "summary"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $TrxPath)) {
    throw "No se encontro el archivo trx en '$TrxPath'."
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

[xml]$trx = Get-Content -LiteralPath $TrxPath
$testRun = $trx.TestRun
if ($null -eq $testRun) {
    throw "El archivo trx no contiene un nodo TestRun valido."
}

$counters = $testRun.ResultSummary.Counters
if ($null -eq $counters) {
    throw "El archivo trx no contiene Counters."
}

$unitTests = @($testRun.TestDefinitions.UnitTest)
$results = @($testRun.Results.UnitTestResult)

$suiteGroups = @{}
foreach ($unitTest in $unitTests) {
    $testId = [string]$unitTest.id
    $suiteName = [string]$unitTest.TestMethod.className
    if ([string]::IsNullOrWhiteSpace($suiteName)) {
        $suiteName = [string]$unitTest.name
    }

    if (-not $suiteGroups.ContainsKey($suiteName)) {
        $suiteGroups[$suiteName] = [ordered]@{
            Name = $suiteName
            Total = 0
            Passed = 0
            Failed = 0
            Skipped = 0
        }
    }

    $suiteGroups[$suiteName].Total++

    $matchingResults = @($results | Where-Object { [string]$_.testId -eq $testId })
    if ($matchingResults.Count -eq 0) {
        continue
    }

    foreach ($result in $matchingResults) {
        $outcome = [string]$result.outcome
        switch ($outcome.ToLowerInvariant()) {
            "passed" { $suiteGroups[$suiteName].Passed++ }
            "failed" { $suiteGroups[$suiteName].Failed++ }
            default { $suiteGroups[$suiteName].Skipped++ }
        }
    }
}

$orderedSuites = @(
    $suiteGroups.Values |
        ForEach-Object { [pscustomobject]$_ } |
        Sort-Object -Property Name
)

$startTime = [DateTimeOffset]::Parse([string]$testRun.Times.start)
$finishTime = [DateTimeOffset]::Parse([string]$testRun.Times.finish)
$duration = $finishTime - $startTime

$summary = [pscustomobject]@{
    GeneratedAtUtc = [DateTime]::UtcNow.ToString("o")
    TrxPath = (Resolve-Path -LiteralPath $TrxPath).Path
    Outcome = [string]$testRun.ResultSummary.outcome
    Total = [int]$counters.total
    Executed = [int]$counters.executed
    Passed = [int]$counters.passed
    Failed = [int]$counters.failed
    Skipped = [int]$counters.notExecuted
    Duration = $duration.ToString()
    Suites = $orderedSuites
}

$summaryJsonPath = Join-Path $OutputDirectory "$SummaryBaseName.json"
$summaryMarkdownPath = Join-Path $OutputDirectory "$SummaryBaseName.md"

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryJsonPath -Encoding utf8

$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add("# Test Result Summary")
$markdown.Add("")
$markdown.Add("- GeneratedAtUtc: `"$($summary.GeneratedAtUtc)`"")
$markdown.Add("- Outcome: `"$($summary.Outcome)`"")
$markdown.Add("- Total: `"$($summary.Total)`"")
$markdown.Add("- Executed: `"$($summary.Executed)`"")
$markdown.Add("- Passed: `"$($summary.Passed)`"")
$markdown.Add("- Failed: `"$($summary.Failed)`"")
$markdown.Add("- Skipped: `"$($summary.Skipped)`"")
$markdown.Add("- Duration: `"$($summary.Duration)`"")
$markdown.Add("- TrxPath: `"$($summary.TrxPath)`"")
$markdown.Add("")
$markdown.Add("| Suite | Total | Passed | Failed | Skipped |")
$markdown.Add("| --- | --- | --- | --- | --- |")

foreach ($suite in $summary.Suites) {
    $markdown.Add("| $($suite.Name) | $($suite.Total) | $($suite.Passed) | $($suite.Failed) | $($suite.Skipped) |")
}

$markdown | Set-Content -LiteralPath $summaryMarkdownPath -Encoding utf8

Write-Host "Resumen de test generado:"
Write-Host " - $summaryJsonPath"
Write-Host " - $summaryMarkdownPath"
