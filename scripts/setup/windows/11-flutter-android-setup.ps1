Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

function Add-UserPathEntry {
    param([string]$PathToAdd)

    if ([string]::IsNullOrWhiteSpace($PathToAdd)) { return }
    if (-not (Test-Path $PathToAdd)) { return }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()

    if (-not [string]::IsNullOrWhiteSpace($userPath)) {
        $parts = $userPath.Split(";") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }

    if ($parts -notcontains $PathToAdd) {
        $newUserPath = (($parts + $PathToAdd) | Select-Object -Unique) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    }

    if (($env:Path -split ";") -notcontains $PathToAdd) {
        $env:Path = "$env:Path;$PathToAdd"
    }
}

Write-Host "Instalando Flutter estable con Puro..." -ForegroundColor Cyan
puro install stable
puro global stable

Add-UserPathEntry "$env:USERPROFILE\.puro\bin"
Add-UserPathEntry "$env:USERPROFILE\AppData\Local\Pub\Cache\bin"

$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
if (Test-Path $androidSdk) {
    [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidSdk, "User")
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidSdk, "User")
    $env:ANDROID_SDK_ROOT = $androidSdk
    $env:ANDROID_HOME = $androidSdk
    Add-UserPathEntry (Join-Path $androidSdk "platform-tools")

    Write-Host "Configurando Flutter con Android SDK..." -ForegroundColor Cyan
    flutter config --android-sdk $androidSdk
} else {
    Write-Host "No encontre Android SDK en $androidSdk" -ForegroundColor Yellow
    Write-Host "Abri Android Studio, instala Android SDK + Build Tools + Command-line Tools y reejecuta este script." -ForegroundColor Yellow
}

Write-Host "Activando herramientas de monorepo Flutter..." -ForegroundColor Cyan
dart pub global activate melos

Write-Host "Chequeando entorno Flutter..." -ForegroundColor Cyan
flutter --version
flutter doctor

Write-Host ""
Write-Host "Si Flutter te pide aceptar licencias Android, corre manualmente:" -ForegroundColor Yellow
Write-Host "flutter doctor --android-licenses" -ForegroundColor White
