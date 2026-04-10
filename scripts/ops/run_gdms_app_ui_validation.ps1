param(
    [string]$ApiBaseUrl = "http://127.0.0.1:8080",
    [string]$WindowsTwainBaseUrl = "http://127.0.0.1:43127",
    [string]$Device = "windows",
    [switch]$SkipHealthChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$appRoot = Join-Path $workspaceRoot "client\apps\gdms_app"

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

function Test-JsonEndpoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$RetryCount = 10,
        [int]$RetryDelaySeconds = 2
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 10
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
                Write-Host "$Name OK -> $Url" -ForegroundColor Green
                return
            }

            $lastError = "HTTP $($response.StatusCode)"
        }
        catch {
            $lastError = $_.Exception.Message
        }

        if ($attempt -lt $RetryCount) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "$Name no responde correctamente en $Url. Detalle: $lastError"
}

$flutterCommand = Resolve-FlutterCommand

if (-not $SkipHealthChecks) {
    Test-JsonEndpoint -Name "API health" -Url "$ApiBaseUrl/api/health"
    Test-JsonEndpoint -Name "windows-twain health" -Url "$WindowsTwainBaseUrl/health"
}

Write-Host "Abriendo gdms_app para validacion UI..." -ForegroundColor Cyan
Write-Host "API: $ApiBaseUrl" -ForegroundColor White
Write-Host "windows-twain: $WindowsTwainBaseUrl" -ForegroundColor White
Write-Host "Device: $Device" -ForegroundColor White

Push-Location $appRoot
try {
    & $flutterCommand run `
        -d $Device `
        --dart-define=GDMS_API_BASE_URL=$ApiBaseUrl `
        --dart-define=WINDOWS_TWAIN_BASE_URL=$WindowsTwainBaseUrl
}
finally {
    Pop-Location
}
