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

function Install-OrUpdate-DotNetTool {
    param([string]$ToolName)

    $installed = dotnet tool list --global | Select-String -Pattern "^\s*$ToolName\s"
    if ($installed) {
        dotnet tool update --global $ToolName
    } else {
        dotnet tool install --global $ToolName
    }
}

Write-Host "Configurando Git..." -ForegroundColor Cyan
git config --global core.longpaths true
git config --global init.defaultBranch main

Write-Host "Agregando paths utiles..." -ForegroundColor Cyan
Add-UserPathEntry "$env:USERPROFILE\.dotnet\tools"
Add-UserPathEntry "$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
Add-UserPathEntry "$env:LOCALAPPDATA\Android\Sdk\platform-tools"

Write-Host "Detectando Java 21..." -ForegroundColor Cyan
$jdkRoot = Get-ChildItem "C:\Program Files\Microsoft" -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "jdk-21*" } |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($jdkRoot) {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkRoot.FullName, "User")
    $env:JAVA_HOME = $jdkRoot.FullName
    Add-UserPathEntry (Join-Path $jdkRoot.FullName "bin")
    Write-Host "JAVA_HOME -> $($jdkRoot.FullName)" -ForegroundColor Green
} else {
    Write-Host "No encontre el JDK 21 en la ruta esperada. Revisalo manualmente si Java falla." -ForegroundColor Yellow
}

Write-Host "Instalando herramientas globales .NET..." -ForegroundColor Cyan
Install-OrUpdate-DotNetTool "docfx"
Install-OrUpdate-DotNetTool "dotnet-ef"

Write-Host ""
Write-Host "Base de configuracion completada." -ForegroundColor Green
Write-Host "Siguiente: ejecutar 11-flutter-android-setup.ps1" -ForegroundColor Yellow
