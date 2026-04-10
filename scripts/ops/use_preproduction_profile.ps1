Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sourcePath = Join-Path $repoRoot ".env.preproduction.example"
$targetPath = Join-Path $repoRoot ".env"

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "No se encontro .env.preproduction.example en $repoRoot"
}

Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force

Write-Host ".env actualizado con el perfil preproduccion local." -ForegroundColor Green
Write-Host "Revisar y reemplazar estos valores antes de usarlo:" -ForegroundColor Yellow
Write-Host "- GDMS_POSTGRES_PASSWORD" -ForegroundColor White
Write-Host "- GDMS_JWT_SIGNING_KEY" -ForegroundColor White
