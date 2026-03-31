Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

function Install-WingetPackage {
    param([string]$Id)

    Write-Host "Instalando $Id..." -ForegroundColor Cyan
    winget install -e --id $Id --accept-package-agreements --accept-source-agreements --disable-interactivity
}

winget source update

$packages = @(
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Microsoft.DotNet.SDK.10",
    "Docker.DockerDesktop",
    "OpenJS.NodeJS.LTS",
    "Google.AndroidStudio",
    "Microsoft.OpenJDK.21",
    "Google.PlatformTools",
    "pingbird.Puro",
    "Google.FirebaseCLI",
    "DBeaver.DBeaver.Community"
)

foreach ($package in $packages) {
    Install-WingetPackage -Id $package
}

Write-Host ""
Write-Host "Fase 2 completada. Abre una terminal nueva y continua con 03-post-install-docker.ps1." -ForegroundColor Green
