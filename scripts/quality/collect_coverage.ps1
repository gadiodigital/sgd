param(
    [string]$WorkspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path,
    [string]$OutputRoot = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "artifacts\coverage")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Get-LcovSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $linesCovered = 0
    $linesValid = 0

    Get-Content -Path $Path | ForEach-Object {
        if ($_ -like "DA:*") {
            $parts = $_.Substring(3).Split(",")
            $linesValid++
            if ([int]$parts[1] -gt 0) {
                $linesCovered++
            }
        }
    }

    $lineRatePct = if ($linesValid -eq 0) {
        0
    }
    else {
        [math]::Round(($linesCovered / $linesValid) * 100, 2)
    }

    [PSCustomObject]@{
        LinesCovered = $linesCovered
        LinesValid   = $linesValid
        LineRatePct  = $lineRatePct
    }
}

function Get-MergedCoberturaSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $lineHits = @{}

    foreach ($path in $Paths) {
        [xml]$coverage = Get-Content -Path $path
        $classNodes = $coverage.SelectNodes("//class")
        if ($null -eq $classNodes) {
            continue
        }

        foreach ($classNode in $classNodes) {
            $filename = [string]$classNode.filename
            if ([string]::IsNullOrWhiteSpace($filename)) {
                continue
            }

            foreach ($lineNode in $classNode.lines.line) {
                $lineNumber = [int]$lineNode.number
                $hits = [int]$lineNode.hits
                $key = "$filename`:$lineNumber"

                if (-not $lineHits.ContainsKey($key) -or $hits -gt $lineHits[$key]) {
                    $lineHits[$key] = $hits
                }
            }
        }
    }

    $linesValid = $lineHits.Count
    $linesCovered = @($lineHits.Values | Where-Object { $_ -gt 0 }).Count
    $lineRatePct = if ($linesValid -eq 0) {
        0
    }
    else {
        [math]::Round(($linesCovered / $linesValid) * 100, 2)
    }

    return [PSCustomObject]@{
        LinesCovered = $linesCovered
        LinesValid   = $linesValid
        LineRatePct  = $lineRatePct
    }
}

function Get-CoberturaPackageSummaries {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $packageLines = @{}

    foreach ($path in $Paths) {
        [xml]$coverage = Get-Content -Path $path
        $packageNodes = $coverage.SelectNodes("//package")
        if ($null -eq $packageNodes) {
            continue
        }

        foreach ($packageNode in $packageNodes) {
            $packageName = [string]$packageNode.name
            if ([string]::IsNullOrWhiteSpace($packageName)) {
                continue
            }

            if (-not $packageLines.ContainsKey($packageName)) {
                $packageLines[$packageName] = @{}
            }

            foreach ($classNode in $packageNode.classes.class) {
                $filename = [string]$classNode.filename
                if ([string]::IsNullOrWhiteSpace($filename)) {
                    continue
                }

                foreach ($lineNode in $classNode.lines.line) {
                    $lineNumber = [int]$lineNode.number
                    $hits = [int]$lineNode.hits
                    $key = "$filename`:$lineNumber"

                    if (-not $packageLines[$packageName].ContainsKey($key) -or $hits -gt $packageLines[$packageName][$key]) {
                        $packageLines[$packageName][$key] = $hits
                    }
                }
            }
        }
    }

    return @(
        $packageLines.GetEnumerator() |
            ForEach-Object {
                $linesValid = $_.Value.Count
                $linesCovered = @($_.Value.Values | Where-Object { $_ -gt 0 }).Count
                [PSCustomObject]@{
                    Name        = $_.Key
                    LineRatePct = if ($linesValid -eq 0) {
                        0
                    }
                    else {
                        [math]::Round(($linesCovered / $linesValid) * 100, 2)
                    }
                }
            } |
            Sort-Object -Property Name
    )
}

function Convert-ToRelativeDisplayPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $normalizedBase = (Resolve-Path $BasePath).Path.TrimEnd("\") + "\"
    $normalizedFull = (Resolve-Path $FullPath).Path

    if ($normalizedFull.StartsWith($normalizedBase, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $normalizedFull.Substring($normalizedBase.Length).Replace("\", "/")
    }

    return $normalizedFull.Replace("\", "/")
}

if (Test-Path -Path $OutputRoot) {
    Remove-Item -Path $OutputRoot -Recurse -Force
}

$backendOutputRoot = Join-Path $OutputRoot "backend"
$flutterOutputRoot = Join-Path $OutputRoot "flutter"

New-Item -ItemType Directory -Path $backendOutputRoot -Force | Out-Null
New-Item -ItemType Directory -Path $flutterOutputRoot -Force | Out-Null

Invoke-Step -Name "Collect backend coverage" -Action {
    dotnet test "$WorkspaceRoot\server\Gdms.sln" `
        --collect:"XPlat Code Coverage" `
        --results-directory "$backendOutputRoot\raw"
}

$backendCoverageFiles = @(
    Get-ChildItem -Path "$backendOutputRoot\raw" -Recurse -Filter "coverage.cobertura.xml" |
        Select-Object -ExpandProperty FullName
)

if ($backendCoverageFiles.Count -eq 0) {
    throw "No se encontro coverage.cobertura.xml para backend."
}

$backendCoverageFiles | Sort-Object | ForEach-Object -Begin { $index = 1 } -Process {
    Copy-Item -Path $_ -Destination (Join-Path $backendOutputRoot ("coverage.$index.cobertura.xml")) -Force
    $index++
}

$backendTotal = Get-MergedCoberturaSummary -Paths $backendCoverageFiles
$backendPackages = Get-CoberturaPackageSummaries -Paths $backendCoverageFiles

$flutterTargets = & "$PSScriptRoot\get_flutter_targets.ps1" -WorkspaceRoot $WorkspaceRoot
$flutterSummaries = @()

foreach ($target in $flutterTargets) {
    $targetName = Convert-ToRelativeDisplayPath -BasePath $WorkspaceRoot -FullPath $target
    $safeTargetName = $targetName.Replace("/", "__")
    $targetOutputRoot = Join-Path $flutterOutputRoot $safeTargetName
    New-Item -ItemType Directory -Path $targetOutputRoot -Force | Out-Null

    Invoke-Step -Name "Collect Flutter coverage :: $targetName" -Action {
        Push-Location $target
        flutter test --coverage
        $exitCode = $LASTEXITCODE
        Pop-Location
        if ($exitCode -ne 0) {
            throw "flutter test --coverage fallo en $targetName con codigo $exitCode."
        }
    }

    $lcovFile = Join-Path $target "coverage\lcov.info"
    if (-not (Test-Path -Path $lcovFile)) {
        throw "No se encontro lcov.info en $targetName."
    }

    Copy-Item -Path $lcovFile -Destination (Join-Path $targetOutputRoot "lcov.info") -Force
    $lcovSummary = Get-LcovSummary -Path $lcovFile

    $targetCoverageRoot = Join-Path $target "coverage"
    if (Test-Path -Path $targetCoverageRoot) {
        Remove-Item -Path $targetCoverageRoot -Recurse -Force
    }

    $flutterSummaries += [PSCustomObject]@{
        Name         = $targetName
        LineRatePct  = $lcovSummary.LineRatePct
        LinesCovered = $lcovSummary.LinesCovered
        LinesValid   = $lcovSummary.LinesValid
    }
}

$flutterTotalCovered = ($flutterSummaries | Measure-Object -Property LinesCovered -Sum).Sum
$flutterTotalValid = ($flutterSummaries | Measure-Object -Property LinesValid -Sum).Sum
$flutterTotalRatePct = if ($flutterTotalValid -eq 0) {
    0
}
else {
    [math]::Round(($flutterTotalCovered / $flutterTotalValid) * 100, 2)
}

$summary = [PSCustomObject]@{
    GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    Backend        = [PSCustomObject]@{
        Total    = [PSCustomObject]@{
            LineRatePct  = $backendTotal.LineRatePct
            LinesCovered = [int]$backendTotal.LinesCovered
            LinesValid   = [int]$backendTotal.LinesValid
        }
        Packages = $backendPackages
    }
    Flutter        = [PSCustomObject]@{
        Total   = [PSCustomObject]@{
            LineRatePct  = $flutterTotalRatePct
            LinesCovered = [int]$flutterTotalCovered
            LinesValid   = [int]$flutterTotalValid
        }
        Targets = $flutterSummaries
    }
}

$summaryJsonPath = Join-Path $OutputRoot "summary.json"
$summaryMdPath = Join-Path $OutputRoot "summary.md"

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $summaryJsonPath

$summaryLines = @(
    "# Coverage summary",
    "",
    "Generated at UTC: $($summary.GeneratedAtUtc)",
    "",
    "## Backend",
    "",
    "- Total line coverage: $($summary.Backend.Total.LineRatePct)% ($($summary.Backend.Total.LinesCovered)/$($summary.Backend.Total.LinesValid))",
    ""
)

foreach ($package in $summary.Backend.Packages) {
    $summaryLines += "- $($package.Name): $($package.LineRatePct)%"
}

$summaryLines += @(
    "",
    "## Flutter",
    "",
    "- Total line coverage: $($summary.Flutter.Total.LineRatePct)% ($($summary.Flutter.Total.LinesCovered)/$($summary.Flutter.Total.LinesValid))",
    ""
)

foreach ($target in $summary.Flutter.Targets) {
    $summaryLines += "- $($target.Name): $($target.LineRatePct)% ($($target.LinesCovered)/$($target.LinesValid))"
}

$summaryLines | Set-Content -Path $summaryMdPath

Write-Host "Coverage recolectada en $OutputRoot" -ForegroundColor Green
Write-Host "Backend total: $($summary.Backend.Total.LineRatePct)%"
Write-Host "Flutter total: $($summary.Flutter.Total.LineRatePct)%"
