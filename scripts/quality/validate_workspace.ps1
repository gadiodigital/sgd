Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    Write-Host "=== $Name ===" -ForegroundColor Cyan
    & $Action
    $exitCodeVariable = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    $exitCode = if ($null -ne $exitCodeVariable) { $LASTEXITCODE } else { 0 }

    if ($exitCode -ne 0) {
        throw "La etapa '$Name' finalizo con codigo $exitCode."
    }
}

Invoke-Step -Name "Line limits" -Action {
    & "$workspaceRoot\scripts\quality\check_line_limits.ps1" -WorkspaceRoot $workspaceRoot
}

Invoke-Step -Name ".NET build" -Action {
    dotnet build "$workspaceRoot\server\Gdms.sln"
}

Invoke-Step -Name ".NET test" -Action {
    dotnet test "$workspaceRoot\server\Gdms.sln" --no-build
}

$flutterTargets = @(
    "$workspaceRoot\client\apps\gdms_app",
    "$workspaceRoot\client\packages\core",
    "$workspaceRoot\client\packages\design_system",
    "$workspaceRoot\client\packages\feature_auth",
    "$workspaceRoot\client\packages\feature_config",
    "$workspaceRoot\client\packages\feature_documents",
    "$workspaceRoot\client\packages\feature_integrations",
    "$workspaceRoot\client\packages\feature_notifications",
    "$workspaceRoot\client\packages\feature_records",
    "$workspaceRoot\client\packages\feature_reports",
    "$workspaceRoot\client\packages\feature_search",
    "$workspaceRoot\client\packages\feature_signature",
    "$workspaceRoot\client\packages\feature_sector_corporate",
    "$workspaceRoot\client\packages\feature_sector_legal",
    "$workspaceRoot\client\packages\feature_sector_real_estate",
    "$workspaceRoot\client\packages\feature_admin",
    "$workspaceRoot\client\packages\feature_audit",
    "$workspaceRoot\client\packages\feature_workflow"
)

foreach ($target in $flutterTargets) {
    Invoke-Step -Name "Flutter analyze :: $target" -Action {
        Push-Location $target
        flutter analyze
        $exitCode = $LASTEXITCODE
        Pop-Location
        if ($exitCode -ne 0) {
            throw "flutter analyze fallo en $target con codigo $exitCode."
        }
    }

    Invoke-Step -Name "Flutter test :: $target" -Action {
        Push-Location $target
        flutter test
        $exitCode = $LASTEXITCODE
        Pop-Location
        if ($exitCode -ne 0) {
            throw "flutter test fallo en $target con codigo $exitCode."
        }
    }
}

Write-Host "Workspace validado correctamente." -ForegroundColor Green
