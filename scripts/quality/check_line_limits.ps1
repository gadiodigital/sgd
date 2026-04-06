param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path,
    [int]$MaxLines = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$targets = @(
    (Join-Path $WorkspaceRoot "server\src"),
    (Join-Path $WorkspaceRoot "client"),
    (Join-Path $WorkspaceRoot "windows-twain")
)

$violations = @()

foreach ($target in $targets) {
    if (-not (Test-Path $target)) {
        continue
    }

    $files = Get-ChildItem -Path $target -Recurse -File |
        Where-Object {
            $_.Extension -in @(".cs", ".dart") -and
            $_.FullName -notmatch "\\bin\\" -and
            $_.FullName -notmatch "\\obj\\" -and
            $_.FullName -notmatch "\\.dart_tool\\" -and
            $_.Name -notlike "*.g.dart"
        }

    foreach ($file in $files) {
        $lineCount = (Get-Content -Path $file.FullName).Count

        if ($lineCount -gt $MaxLines) {
            $violations += [PSCustomObject]@{
                Path  = $file.FullName
                Lines = $lineCount
            }
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Host "Se detectaron archivos por encima de $MaxLines lineas:" -ForegroundColor Red
    $violations | Sort-Object Lines -Descending | Format-Table -AutoSize
    exit 1
}

Write-Host "OK: no se detectaron archivos .cs o .dart por encima de $MaxLines lineas." -ForegroundColor Green
