Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

function Resolve-FlutterCommand {
    $fromPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -ne $fromPath) {
        return $fromPath.Source
    }

    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_ROOT)) {
        $candidates += Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
    }

    $candidates += @(
        "C:\FlutterSDK\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "C:\tools\flutter\bin\flutter.bat"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "No se encontro flutter. Agregar Flutter al PATH o definir FLUTTER_ROOT."
}

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

$flutterCommand = Resolve-FlutterCommand

Invoke-Step -Name "Line limits" -Action {
    & "$workspaceRoot\scripts\quality\check_line_limits.ps1" -WorkspaceRoot $workspaceRoot
}

Invoke-Step -Name ".NET build" -Action {
    dotnet build "$workspaceRoot\server\Gdms.sln"
}

Invoke-Step -Name ".NET test" -Action {
    dotnet test "$workspaceRoot\server\Gdms.sln" --no-build
}

$postgresIntegrationConnection = [Environment]::GetEnvironmentVariable("GDMS_TEST_POSTGRES_CONNECTION")
if (-not [string]::IsNullOrWhiteSpace($postgresIntegrationConnection)) {
    Invoke-Step -Name ".NET integration test" -Action {
        dotnet test "$workspaceRoot\server\tests\Gdms.IntegrationTests\Gdms.IntegrationTests.csproj" --no-build
    }
}
else {
    Write-Host "=== .NET integration test ===" -ForegroundColor Cyan
    Write-Host "Omitido: definir GDMS_TEST_POSTGRES_CONNECTION para ejecutar integration tests de PostgreSQL." -ForegroundColor Yellow
}

Invoke-Step -Name "windows-twain build" -Action {
    dotnet build "$workspaceRoot\windows-twain\windows-twain.csproj"
}

Invoke-Step -Name "Database scripts" -Action {
    & "$workspaceRoot\scripts\quality\validate_database_scripts.ps1" -WorkspaceRoot $workspaceRoot
}

$flutterTargets = & "$workspaceRoot\scripts\quality\get_flutter_targets.ps1" -WorkspaceRoot $workspaceRoot

foreach ($target in $flutterTargets) {
    Invoke-Step -Name "Flutter analyze :: $target" -Action {
        Push-Location $target
        & $flutterCommand analyze
        $exitCode = $LASTEXITCODE
        Pop-Location
        if ($exitCode -ne 0) {
            throw "flutter analyze fallo en $target con codigo $exitCode."
        }
    }

    Invoke-Step -Name "Flutter test :: $target" -Action {
        Push-Location $target
        & $flutterCommand test
        $exitCode = $LASTEXITCODE
        Pop-Location
        if ($exitCode -ne 0) {
            throw "flutter test fallo en $target con codigo $exitCode."
        }
    }
}

Write-Host "Workspace validado correctamente." -ForegroundColor Green
