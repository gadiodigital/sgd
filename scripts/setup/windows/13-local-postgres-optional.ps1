Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

Write-Host "Instalando PostgreSQL 18 local..." -ForegroundColor Cyan
winget install -e --id PostgreSQL.PostgreSQL.18 --accept-package-agreements --accept-source-agreements

Write-Host ""
Write-Host "Si el instalador te pidio pasos interactivos, completalos." -ForegroundColor Yellow
Write-Host "Despues verifica con:" -ForegroundColor Yellow
Write-Host "psql --version" -ForegroundColor White
Write-Host ""
Write-Host "Cuando PostgreSQL quede operativo, el proyecto puede adaptarse para correr local sin Docker." -ForegroundColor Green
