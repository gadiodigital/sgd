Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Host "==== .NET ====" -ForegroundColor Cyan
dotnet --list-sdks

Write-Host "==== Git ====" -ForegroundColor Cyan
git --version

Write-Host "==== VS Code ====" -ForegroundColor Cyan
code --version

Write-Host "==== Node / npm ====" -ForegroundColor Cyan
node --version
npm --version

Write-Host "==== Firebase CLI ====" -ForegroundColor Cyan
firebase --version

Write-Host "==== Java ====" -ForegroundColor Cyan
java --version

Write-Host "==== Android ADB ====" -ForegroundColor Cyan
adb --version

Write-Host "==== Puro ====" -ForegroundColor Cyan
puro --version

Write-Host "==== Flutter ====" -ForegroundColor Cyan
flutter --version
flutter doctor
