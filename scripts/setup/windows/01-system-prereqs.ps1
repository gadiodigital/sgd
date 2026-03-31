Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    throw "Este script debe ejecutarse como administrador."
}

Write-Host "Habilitando prerrequisitos de virtualizacion para Docker y WSL..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

try {
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
} catch {
    Write-Host "No fue posible habilitar Hyper-V. Si tu edicion no lo soporta, Docker Desktop puede seguir funcionando con WSL2." -ForegroundColor Yellow
}

Write-Host "Habilitando soporte de rutas largas..." -ForegroundColor Cyan
New-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

Write-Host "Inicializando WSL..." -ForegroundColor Cyan
try {
    wsl --install --no-distribution
} catch {
    Write-Host "WSL ya estaba disponible o requiere reinicio para terminar la instalacion." -ForegroundColor Yellow
}

try {
    wsl --set-default-version 2
} catch {
    Write-Host "No se pudo fijar WSL 2 todavia. Reintentalo despues del reinicio." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Fase 1 completada. Reinicia Windows antes de ejecutar 02-install-core-dev-tools.ps1." -ForegroundColor Green
