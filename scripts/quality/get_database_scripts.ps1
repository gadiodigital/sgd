param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
)

$scriptsRoot = Join-Path $WorkspaceRoot "database\scripts"

Get-ChildItem -Path $scriptsRoot -File -Filter "*.sql" |
    Sort-Object Name |
    ForEach-Object { $_.FullName }
