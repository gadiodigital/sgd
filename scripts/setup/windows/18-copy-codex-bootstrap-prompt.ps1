Set-ExecutionPolicy Bypass -Scope Process -Force
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$promptFile = Join-Path $PSScriptRoot "18-codex-bootstrap-prompt.md"

if (-not (Test-Path $promptFile)) {
    throw "No se encontro el archivo de prompt en $promptFile"
}

$content = Get-Content -Raw -Path $promptFile
$match = [regex]::Match($content, '(?s)```text\r?\n(.*?)\r?\n```')

if (-not $match.Success) {
    throw "No se pudo extraer el bloque de prompt desde $promptFile"
}

$prompt = $match.Groups[1].Value.Trim()
Set-Clipboard -Value $prompt

Write-Host "Prompt de reingreso copiado al portapapeles." -ForegroundColor Green
Write-Host "Archivo fuente: $promptFile" -ForegroundColor Cyan
Write-Host "Contexto principal esperado: $(Join-Path $workspaceRoot 'contexto_handoff.md')" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pega ahora el contenido en Codex en la nueva PC." -ForegroundColor Yellow
