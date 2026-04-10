param(
    [switch]$SkipBuild
)

Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$envFilePath = Join-Path $workspaceRoot ".env"
$envExamplePath = Join-Path $workspaceRoot ".env.example"

function Invoke-DockerCompose {
    param([string[]]$Arguments)

    & docker compose @Arguments
}

if (-not (Test-Path -LiteralPath $envFilePath) -and (Test-Path -LiteralPath $envExamplePath)) {
    Copy-Item -LiteralPath $envExamplePath -Destination $envFilePath
    Write-Host "Se creo .env desde .env.example. Revisar GDMS_JWT_SIGNING_KEY y settings operativos antes de usarlo fuera de local." -ForegroundColor Yellow
}

Write-Host "Levantando stack Docker de GDMS..." -ForegroundColor Cyan
Set-Location $workspaceRoot
$composeArguments = @("up", "-d")
if (-not $SkipBuild) {
    $composeArguments = @("up", "--build", "-d")
}
Invoke-DockerCompose -Arguments $composeArguments

Write-Host ""
Write-Host "Servicios esperados:" -ForegroundColor Green
Write-Host "Swagger: http://localhost:8080/swagger" -ForegroundColor White
Write-Host "PostgreSQL: localhost:5433" -ForegroundColor White
Write-Host ""
Write-Host "Para revisar logs: docker compose logs -f" -ForegroundColor Yellow
