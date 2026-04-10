param(
    [switch]$IncludeScanHost,
    [switch]$CaptureSnapshotOnFailure,
    [string]$ApiBaseUrl = "http://127.0.0.1:8080",
    [string]$PostgresHost = "127.0.0.1",
    [int]$PostgresPort = 5433,
    [string]$ScanHostBaseUrl = "http://127.0.0.1:43127"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "invoke_preproduction_smoke.ps1"
$args = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-ApiBaseUrl", $ApiBaseUrl,
    "-PostgresHost", $PostgresHost,
    "-PostgresPort", $PostgresPort,
    "-ValidateConfiguration",
    "-ValidateRuntimeConfiguration",
    "-ValidateOperationalRisks",
    "-ValidateCapacityHeadroom",
    "-ValidateCapacityTrend",
    "-ValidateRecoveryDrillThresholds"
)

if ($IncludeScanHost) {
    $args += @("-IncludeScanHost", "-ScanHostBaseUrl", $ScanHostBaseUrl)
}

if ($CaptureSnapshotOnFailure) {
    $args += "-CaptureSnapshotOnFailure"
}

& powershell @args
exit $LASTEXITCODE
