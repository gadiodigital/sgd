param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptsRoot = Join-Path $WorkspaceRoot "database\scripts"
$readmePath = Join-Path $scriptsRoot "README.md"

if (-not (Test-Path -Path $scriptsRoot)) {
    throw "No se encontro el directorio de scripts de base de datos en $scriptsRoot."
}

if (-not (Test-Path -Path $readmePath)) {
    throw "No se encontro el README de scripts de base de datos en $readmePath."
}

$scriptFiles = @(Get-ChildItem -Path $scriptsRoot -File -Filter "*.sql" | Sort-Object Name)

if ($scriptFiles.Count -eq 0) {
    throw "No se encontraron scripts SQL en $scriptsRoot."
}

$expectedIndex = 1

foreach ($scriptFile in $scriptFiles) {
    if ($scriptFile.Name -notmatch '^(?<index>\d{3})_(?<name>.+)\.sql$') {
        throw "El archivo $($scriptFile.Name) no respeta el formato 000_nombre.sql."
    }

    $scriptIndex = [int]$Matches.index
    if ($scriptIndex -ne $expectedIndex) {
        throw "La secuencia de scripts SQL tiene un gap o desorden en $($scriptFile.Name). Se esperaba $(('{0:D3}' -f $expectedIndex))."
    }

    if ($scriptFile.Length -le 0) {
        throw "El archivo $($scriptFile.Name) esta vacio."
    }

    $expectedIndex++
}

$readmeContent = Get-Content -Path $readmePath -Raw
$readmeScriptNames = @([regex]::Matches($readmeContent, '\b\d{3}_[a-z0-9_]+\.sql\b', 'IgnoreCase') |
    ForEach-Object { $_.Value } |
    Select-Object -Unique)

$actualScriptNames = @($scriptFiles | ForEach-Object { $_.Name })

$missingInReadme = @($actualScriptNames | Where-Object { $_ -notin $readmeScriptNames })
$extraInReadme = @($readmeScriptNames | Where-Object { $_ -notin $actualScriptNames })

if ($missingInReadme.Count -gt 0) {
    throw "Faltan scripts en database\\scripts\\README.md: $($missingInReadme -join ', ')."
}

if ($extraInReadme.Count -gt 0) {
    throw "README.md referencia scripts inexistentes: $($extraInReadme -join ', ')."
}

Write-Host "Scripts SQL validados correctamente: $($scriptFiles.Count) archivos secuenciales y documentados." -ForegroundColor Green
