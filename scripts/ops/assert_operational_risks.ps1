param(
    [int]$ApiLogTail = 120,
    [int]$PostgresLogTail = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-CheckResult {
    param(
        [System.Collections.Generic.List[object]]$Results,
        [string]$Name,
        [string]$Status,
        [string]$Detail
    )

    $Results.Add([pscustomobject]@{
        Check = $Name
        Status = $Status
        Detail = $Detail
    })
}

function Get-DockerComposeLogs {
    param(
        [string]$ServiceName,
        [int]$Tail,
        [int]$RetryCount = 5,
        [int]$RetryDelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        $stdoutPath = Join-Path $env:TEMP ("gdms-{0}-logs-{1}.stdout.txt" -f $ServiceName, [guid]::NewGuid().ToString("N"))
        $stderrPath = Join-Path $env:TEMP ("gdms-{0}-logs-{1}.stderr.txt" -f $ServiceName, [guid]::NewGuid().ToString("N"))
        try {
            $process = Start-Process -FilePath "docker" -ArgumentList @("compose", "logs", $ServiceName, "--tail", "$Tail") -Wait -NoNewWindow -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
            if ($process.ExitCode -eq 0) {
                return (Get-Content -Path $stdoutPath -Raw)
            }
        } finally {
            if (Test-Path -LiteralPath $stdoutPath) {
                Remove-Item -LiteralPath $stdoutPath -Force
            }
            if (Test-Path -LiteralPath $stderrPath) {
                Remove-Item -LiteralPath $stderrPath -Force
            }
        }

        if ($attempt -lt $RetryCount) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "No se pudieron leer los logs de $ServiceName."
}

$apiLogs = Get-DockerComposeLogs -ServiceName "api" -Tail $ApiLogTail
$postgresLogs = Get-DockerComposeLogs -ServiceName "postgres" -Tail $PostgresLogTail

$results = [System.Collections.Generic.List[object]]::new()

if ($apiLogs -match 'DataProtection\.Repositories\.FileSystemXmlRepository\[60\]' -or
    $apiLogs -match 'Protected data will be unavailable when container is destroyed') {
    Add-CheckResult -Results $results -Name "API DataProtection persistence" -Status "FAIL" -Detail "Las keys de DataProtection siguen sin persistencia durable del contenedor."
} else {
    Add-CheckResult -Results $results -Name "API DataProtection persistence" -Status "OK" -Detail "No se detectaron warnings de persistencia efimera de DataProtection."
}

if ($apiLogs -match 'No XML encryptor configured') {
    Add-CheckResult -Results $results -Name "API DataProtection encryption" -Status "WARN" -Detail "Las keys de DataProtection se persisten sin cifrado en reposo del host."
} else {
    Add-CheckResult -Results $results -Name "API DataProtection encryption" -Status "OK" -Detail "No se detectaron warnings de DataProtection sin cifrado."
}

if ($apiLogs -match 'Failed to determine the https port for redirect') {
    Add-CheckResult -Results $results -Name "API HTTPS redirection" -Status "WARN" -Detail "La API intenta redirigir a HTTPS sin puerto HTTPS configurado en este stack local."
} else {
    Add-CheckResult -Results $results -Name "API HTTPS redirection" -Status "OK" -Detail "No se detectaron warnings de HTTPS redirection."
}

if ($postgresLogs -match '\bPANIC:\b' -or $postgresLogs -match 'database system is not accepting connections') {
    Add-CheckResult -Results $results -Name "PostgreSQL critical log patterns" -Status "FAIL" -Detail "Se detectaron patrones criticos en logs de PostgreSQL."
} else {
    Add-CheckResult -Results $results -Name "PostgreSQL critical log patterns" -Status "OK" -Detail "No se detectaron patrones criticos en logs de PostgreSQL."
}

if ($postgresLogs -match '\bFATAL:\b') {
    Add-CheckResult -Results $results -Name "PostgreSQL fatal log patterns" -Status "WARN" -Detail "Se detectaron entradas FATAL en el tail actual de PostgreSQL."
} else {
    Add-CheckResult -Results $results -Name "PostgreSQL fatal log patterns" -Status "OK" -Detail "No se detectaron entradas FATAL en el tail actual."
}

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Riesgos operativos detectados: $($failed.Count) chequeo(s) en rojo."
}

$warnings = @($results | Where-Object Status -eq "WARN")
if ($warnings.Count -gt 0) {
    Write-Warning "Riesgos operativos con advertencias: $($warnings.Count)."
} else {
    Write-Host "Riesgos operativos validados en verde." -ForegroundColor Green
}
