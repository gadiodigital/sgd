param(
    [string]$Device = "windows",
    [string]$ApiBaseUrl = "http://127.0.0.1:5015",
    [string]$WindowsTwainBaseUrl = "http://127.0.0.1:43128",
    [string]$TestPath = "integration_test\gdms_app_ui_document_scan_flow_test.dart",
    [string]$OutputDirectory = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "artifacts\ui-tests")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$appRoot = Join-Path $workspaceRoot "client\apps\gdms_app"
$resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$logPath = Join-Path $resolvedOutputDirectory "gdms_app_ui_automation.log"
$summaryJsonPath = Join-Path $resolvedOutputDirectory "gdms_app_ui_automation_summary.json"
$summaryMarkdownPath = Join-Path $resolvedOutputDirectory "gdms_app_ui_automation_summary.md"

function Resolve-FlutterCommand {
    $fromPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -ne $fromPath) {
        return $fromPath.Source
    }

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) {
        $candidates += Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
    }

    $candidates += @(
        "C:\FlutterSDK\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "C:\tools\flutter\bin\flutter.bat"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "No se encontro flutter. Agregar Flutter al PATH o definir FLUTTER_ROOT."
}

$flutterCommand = Resolve-FlutterCommand
New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null

Push-Location $appRoot
try {
    $output = & $flutterCommand test $TestPath `
        -d $Device `
        --dart-define=GDMS_API_BASE_URL=$ApiBaseUrl `
        --dart-define=WINDOWS_TWAIN_BASE_URL=$WindowsTwainBaseUrl 2>&1
    $exitCode = $LASTEXITCODE

    $output | Tee-Object -FilePath $logPath

    $passed = $false
    $failed = $false
    $executedTests = 0
    $passedTests = 0
    $failedTests = 0
    foreach ($line in $output) {
        $text = [string]$line
        if ($text -match 'All tests passed!') {
            $passed = $true
        }
        if ($text -match 'Some tests failed\.') {
            $failed = $true
        }
        if ($text -match '\+(\d+):\s+All tests passed!') {
            $executedTests = [Math]::Max($executedTests, [int]$Matches[1])
            $passedTests = [Math]::Max($passedTests, [int]$Matches[1])
        }
        if ($text -match '\+(\d+)\s+-\s+(\d+):\s+Some tests failed\.') {
            $passedTests = [Math]::Max($passedTests, [int]$Matches[1])
            $failedTests = [Math]::Max($failedTests, [int]$Matches[2])
            $executedTests = [Math]::Max($executedTests, $passedTests + $failedTests)
        }
        if ($text -match 'Correctas!\s+-\s+Con error:\s+(\d+),\s+Superado:\s+(\d+),\s+Omitido:\s+(\d+),\s+Total:\s+(\d+)') {
            $executedTests = [int]$Matches[4]
            $failedTests = [int]$Matches[1]
            $passedTests = [int]$Matches[2]
        }
    }

    if ($executedTests -eq 0 -and $passed) {
        $executedTests = 1
        $passedTests = 1
    }

    $status = if ($exitCode -eq 0 -and $passed -and -not $failed) { "passed" } else { "failed" }

    if ($passedTests -eq 0 -and $failedTests -eq 0 -and $executedTests -gt 0) {
        if ($status -eq "passed") {
            $passedTests = $executedTests
        } else {
            $failedTests = [Math]::Max(1, $executedTests)
        }
    }

    $summary = [pscustomobject]@{
        GeneratedAtUtc = [DateTime]::UtcNow.ToString("o")
        Device = $Device
        ApiBaseUrl = $ApiBaseUrl
        WindowsTwainBaseUrl = $WindowsTwainBaseUrl
        TestPath = $TestPath
        LogPath = $logPath
        ExitCode = $exitCode
        Status = $status
        Total = $executedTests
        Passed = $passedTests
        Failed = $failedTests
        Suites = @(
            [pscustomobject]@{
                Name = $TestPath.Replace("\", "/")
                Total = $executedTests
                Passed = $passedTests
                Failed = $failedTests
            }
        )
    }

    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path $summaryJsonPath -Encoding utf8

    $markdown = @(
        "# GDMS App UI Automation Summary",
        "",
        "- GeneratedAtUtc: `"$($summary.GeneratedAtUtc)`"",
        "- Status: `"$($summary.Status)`"",
        "- Device: `"$($summary.Device)`"",
        "- TestPath: `"$($summary.TestPath)`"",
        "- ApiBaseUrl: `"$($summary.ApiBaseUrl)`"",
        "- WindowsTwainBaseUrl: `"$($summary.WindowsTwainBaseUrl)`"",
        "- ExitCode: `"$($summary.ExitCode)`"",
        "- Total: `"$($summary.Total)`"",
        "- Passed: `"$($summary.Passed)`"",
        "- Failed: `"$($summary.Failed)`"",
        "- LogPath: `"$($summary.LogPath)`"",
        "",
        "| Suite | Total | Passed | Failed |",
        "| --- | --- | --- | --- |",
        "| $($summary.Suites[0].Name) | $($summary.Suites[0].Total) | $($summary.Suites[0].Passed) | $($summary.Suites[0].Failed) |"
    )
    $markdown | Set-Content -Path $summaryMarkdownPath -Encoding utf8

    Write-Host "Resumen UI generado:"
    Write-Host " - $summaryJsonPath"
    Write-Host " - $summaryMarkdownPath"

    if ($exitCode -ne 0) {
        exit $exitCode
    }
}
finally {
    Pop-Location
}
