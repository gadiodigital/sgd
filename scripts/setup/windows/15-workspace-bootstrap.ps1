Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$serverRoot = Join-Path $workspaceRoot "server"
$clientRoot = Join-Path $workspaceRoot "client"
$appRoot = Join-Path $clientRoot "apps\gdms_app"

Write-Host "Workspace detectado en $workspaceRoot" -ForegroundColor Cyan

Write-Host "Restaurando backend .NET..." -ForegroundColor Cyan
dotnet restore (Join-Path $serverRoot "Gdms.sln")
dotnet build (Join-Path $serverRoot "Gdms.sln")

Write-Host "Bootstrap del monorepo Flutter..." -ForegroundColor Cyan
Set-Location $clientRoot
melos bootstrap

Write-Host "Verificando app Flutter..." -ForegroundColor Cyan
Set-Location $appRoot
flutter pub get
flutter analyze

Write-Host ""
Write-Host "Bootstrap del workspace completado." -ForegroundColor Green
Write-Host "Siguiente: ejecutar 16-run-gdms-docker.ps1 para levantar PostgreSQL + API." -ForegroundColor Yellow
