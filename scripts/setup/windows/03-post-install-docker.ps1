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

Write-Host "Configurando WSL 2 como backend por defecto..." -ForegroundColor Cyan
try {
    wsl --set-default-version 2
} catch {
    Write-Host "No se pudo confirmar WSL2. Verifica la instalacion de WSL despues del reinicio." -ForegroundColor Yellow
}

Write-Host "Agregando el usuario actual al grupo docker-users..." -ForegroundColor Cyan
try {
    net localgroup docker-users $env:USERNAME /add | Out-Null
} catch {
    Write-Host "No se pudo agregar al grupo docker-users. Si el grupo no existe aun, abre Docker Desktop una vez y vuelve a correr este script." -ForegroundColor Yellow
}

$dockerDesktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerDesktop) {
    Write-Host "Abriendo Docker Desktop..." -ForegroundColor Cyan
    Start-Process -FilePath $dockerDesktop | Out-Null
    Start-Sleep -Seconds 8
} else {
    Write-Host "No se encontro Docker Desktop en la ruta esperada. Verifica la instalacion." -ForegroundColor Yellow
}

Write-Host "Verificando Docker..." -ForegroundColor Cyan
try {
    docker --version
    docker compose version
} catch {
    Write-Host "Docker CLI todavia no esta disponible en esta terminal. Cierra sesion, vuelve a abrir PowerShell y reejecuta este script." -ForegroundColor Yellow
    exit 0
}

for ($attempt = 1; $attempt -le 30; $attempt++) {
    try {
        docker info | Out-Null
        Write-Host "Docker engine operativo." -ForegroundColor Green
        Write-Host "Si Windows aun no aplico el grupo docker-users, cerra sesion y volve a entrar antes de seguir." -ForegroundColor Yellow
        exit 0
    } catch {
        Start-Sleep -Seconds 5
    }
}

Write-Host "Docker Desktop esta instalado, pero el engine no quedo operativo todavia. Abre Docker Desktop y espera a que termine de inicializar." -ForegroundColor Yellow
