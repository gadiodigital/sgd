Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Continue"

$extensions = @(
    "ms-dotnettools.csdevkit",
    "ms-dotnettools.csharp",
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "ms-azuretools.vscode-docker",
    "ms-vscode.powershell",
    "redhat.vscode-yaml",
    "eamodio.gitlens"
)

foreach ($ext in $extensions) {
    Write-Host "Instalando $ext..." -ForegroundColor Cyan
    code --install-extension $ext --force
}

Write-Host "Extensiones VS Code instaladas." -ForegroundColor Green
