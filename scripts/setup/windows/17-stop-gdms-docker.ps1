Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
Set-Location $workspaceRoot

Write-Host "Deteniendo stack Docker de GDMS..." -ForegroundColor Cyan
docker compose down

Write-Host "Stack detenido." -ForegroundColor Green
