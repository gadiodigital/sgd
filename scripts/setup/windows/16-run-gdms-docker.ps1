Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

function Invoke-DockerCompose {
    param([string[]]$Arguments)

    & docker compose @Arguments
}

Write-Host "Levantando stack Docker de GDMS..." -ForegroundColor Cyan
Set-Location $workspaceRoot
Invoke-DockerCompose -Arguments @("up", "--build", "-d")

Write-Host ""
Write-Host "Servicios esperados:" -ForegroundColor Green
Write-Host "Swagger: http://localhost:8080/swagger" -ForegroundColor White
Write-Host "PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host ""
Write-Host "Para revisar logs: docker compose logs -f" -ForegroundColor Yellow
