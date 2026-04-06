param(
    [string]$SummaryPath = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "artifacts\coverage\summary.json"),
    [double]$BackendLineThresholdPct = 5.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $SummaryPath)) {
    throw "No se encontro el resumen de coverage en $SummaryPath."
}

$summary = Get-Content -Path $SummaryPath -Raw | ConvertFrom-Json
$backendLineRatePct = [double]$summary.Backend.Total.LineRatePct

if ($backendLineRatePct -lt $BackendLineThresholdPct) {
    throw "La cobertura backend ($backendLineRatePct%) esta por debajo del umbral requerido ($BackendLineThresholdPct%)."
}

Write-Host "Cobertura backend validada: $backendLineRatePct% >= $BackendLineThresholdPct%" -ForegroundColor Green
