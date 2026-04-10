param(
    [string]$SummaryPath = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "artifacts\coverage\summary.json"),
    [double]$BackendLineThresholdPct = 5.0,
    [double]$FlutterLineThresholdPct = 0.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $SummaryPath)) {
    throw "No se encontro el resumen de coverage en $SummaryPath."
}

$summary = Get-Content -Path $SummaryPath -Raw | ConvertFrom-Json
$backendLineRatePct = [double]$summary.Backend.Total.LineRatePct
$flutterLineRatePct = [double]$summary.Flutter.Total.LineRatePct

if ($backendLineRatePct -lt $BackendLineThresholdPct) {
    throw "La cobertura backend ($backendLineRatePct%) esta por debajo del umbral requerido ($BackendLineThresholdPct%)."
}

if ($FlutterLineThresholdPct -gt 0 -and $flutterLineRatePct -lt $FlutterLineThresholdPct) {
    throw "La cobertura Flutter ($flutterLineRatePct%) esta por debajo del umbral requerido ($FlutterLineThresholdPct%)."
}

Write-Host "Cobertura backend validada: $backendLineRatePct% >= $BackendLineThresholdPct%" -ForegroundColor Green
if ($FlutterLineThresholdPct -gt 0) {
    Write-Host "Cobertura Flutter validada: $flutterLineRatePct% >= $FlutterLineThresholdPct%" -ForegroundColor Green
}
