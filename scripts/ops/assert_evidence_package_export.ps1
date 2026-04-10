param(
    [string]$ApiBaseUrl = "http://127.0.0.1:8080",
    [string]$PostgresContainerName = "gdms-postgres",
    [string]$PostgresServiceName = "postgres",
    [string]$DatabaseUser = "gdms",
    [string]$TargetDatabaseName = "gdms"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-PostgresContainerName {
    param(
        [string]$PreferredContainerName,
        [string]$ServiceName
    )

    $runningNames = @(& docker ps --format "{{.Names}}")
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo consultar docker ps."
    }

    if ($runningNames -contains $PreferredContainerName) {
        return $PreferredContainerName
    }

    $serviceContainerId = (& docker compose ps -q $ServiceName 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$serviceContainerId")) {
        $resolvedName = (& docker ps --filter "id=$serviceContainerId" --format "{{.Names}}")
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$resolvedName")) {
            return "$resolvedName".Trim()
        }
    }

    throw "No se encontro un contenedor PostgreSQL corriendo para el servicio '$ServiceName'."
}

function Invoke-PostgresScalar {
    param(
        [string]$ContainerName,
        [string]$DatabaseName,
        [string]$UserName,
        [string]$Sql
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "docker"
    $startInfo.Arguments = "exec -i $ContainerName psql -U $UserName -d $DatabaseName -t -A -v ON_ERROR_STOP=1"
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        $process.StandardInput.Write($Sql)
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($process.ExitCode -ne 0) {
            $detail = if (-not [string]::IsNullOrWhiteSpace($stderr)) { $stderr.Trim() } else { $stdout.Trim() }
            throw "Fallo consulta PostgreSQL sobre '$DatabaseName'. $detail"
        }

        return "$stdout".Trim()
    } finally {
        $process.Dispose()
    }
}

function Invoke-RestMethodWithRetry {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers,
        [string]$ContentType = "",
        [string]$Body = "",
        [int]$RetryCount = 10,
        [int]$RetryDelaySeconds = 1
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
        try {
            $invokeArgs = @{
                Method = $Method
                Uri = $Uri
            }
            if ($Headers.Count -gt 0) {
                $invokeArgs.Headers = $Headers
            }
            if (-not [string]::IsNullOrWhiteSpace($ContentType)) {
                $invokeArgs.ContentType = $ContentType
            }
            if (-not [string]::IsNullOrWhiteSpace($Body)) {
                $invokeArgs.Body = $Body
            }

            return Invoke-RestMethod @invokeArgs
        } catch {
            $lastError = $_
            if ($attempt -lt $RetryCount) {
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }

    throw $lastError
}

function Get-HttpErrorDetail {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)

    $exception = $ErrorRecord.Exception
    $response = $null
    if ($null -ne $exception.PSObject.Properties["Response"]) {
        $response = $exception.Response
    }

    if ($null -eq $response) {
        return $exception.Message
    }

    $statusCode = try { [int]$response.StatusCode } catch { 0 }
    $reasonPhrase = try { [string]$response.ReasonPhrase } catch { "" }
    $body = ""

    try {
        if ($response.Content -is [System.Net.Http.HttpContent]) {
            $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        } elseif ($response.GetResponseStream) {
            $stream = $response.GetResponseStream()
            if ($null -ne $stream) {
                $reader = [System.IO.StreamReader]::new($stream)
                try {
                    $body = $reader.ReadToEnd()
                } finally {
                    $reader.Dispose()
                    $stream.Dispose()
                }
            }
        }
    } catch {
        $body = ""
    }

    $detail = "HTTP $statusCode"
    if (-not [string]::IsNullOrWhiteSpace($reasonPhrase)) {
        $detail += " $reasonPhrase"
    }
    if (-not [string]::IsNullOrWhiteSpace($body)) {
        $detail += " Body: $body"
    }

    return $detail
}

$postgresContainerName = Resolve-PostgresContainerName -PreferredContainerName $PostgresContainerName -ServiceName $PostgresServiceName
$fixtureRow = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT CONCAT_WS('|',
    t.tenant_id::text,
    d.document_id::text,
    t.code,
    u.email::text)
FROM documents.documents d
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
INNER JOIN identity.users u ON u.tenant_id = t.tenant_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
  AND u.email = 'recovery.fixture@gdms.local'
ORDER BY d.created_at_utc ASC
LIMIT 1;
"@

$fixtureParts = $fixtureRow.Split('|', 4)
if ($fixtureParts.Length -ne 4) {
    throw "No se pudo resolver el fixture documental para exportar evidencia."
}

$tenantId = [Guid]$fixtureParts[0]
$documentId = [Guid]$fixtureParts[1]
$tenantCode = $fixtureParts[2]
$userEmail = $fixtureParts[3]
$password = "RecoveryFixture!2026"

$loginBody = @{
    tenantCode = $tenantCode
    email = $userEmail
    password = $password
} | ConvertTo-Json

$loginUri = "$ApiBaseUrl/api/auth/token"
try {
    $session = Invoke-RestMethodWithRetry -Method "Post" -Uri $loginUri -Headers @{} -ContentType "application/json" -Body $loginBody
} catch {
    $httpDetail = Get-HttpErrorDetail -ErrorRecord $_
    throw "Fallo login del fixture contra '$loginUri'. $httpDetail"
}
$token = [string]$session.accessToken
if ([string]::IsNullOrWhiteSpace($token)) {
    throw "No se obtuvo access token para exportar evidencia."
}

$headers = @{
    Authorization = "Bearer $token"
}
$evidenceUri = "$ApiBaseUrl/api/tenants/$tenantId/documents/$documentId/evidence-package"
try {
    $payload = Invoke-RestMethodWithRetry -Method "Get" -Uri $evidenceUri -Headers $headers
} catch {
    $httpDetail = Get-HttpErrorDetail -ErrorRecord $_
    throw "Fallo descarga del evidence package contra '$evidenceUri'. $httpDetail"
}
if ($payload.DocumentId -ne $documentId.Guid) {
    throw "El evidence package no corresponde al documento fixture esperado."
}
if ($payload.TenantId -ne $tenantId.Guid) {
    throw "El evidence package no corresponde al tenant fixture esperado."
}
if ($payload.Metadata.contractNumber -ne "REC-001") {
    throw "El evidence package no contiene la metadata esperada del fixture."
}
if ($payload.Versions.Count -ne 2) {
    throw "Se esperaban 2 versiones en el evidence package y llegaron $($payload.Versions.Count)."
}
if ($payload.WorkflowTasks.Count -lt 1) {
    throw "El evidence package no contiene workflow tasks del fixture."
}
if ($payload.Signatures.Count -lt 1) {
    throw "El evidence package no contiene signatures del fixture."
}
if ($payload.LegalHolds.Count -lt 1) {
    throw "El evidence package no contiene legal holds del fixture."
}
if (-not ($payload.AuditEvents | Where-Object { $_.EventType -eq "RECOVERY_FIXTURE_REVIEWED" })) {
    throw "El evidence package no contiene el audit event del fixture."
}

[pscustomobject]@{
    TenantCode = $tenantCode
    UserEmail = $userEmail
    DocumentId = $documentId
    Versions = $payload.Versions.Count
    WorkflowTasks = $payload.WorkflowTasks.Count
    Signatures = $payload.Signatures.Count
    LegalHolds = $payload.LegalHolds.Count
    AuditEvents = @($payload.AuditEvents).Count
} | Format-List

Write-Host "Evidence package export validado en verde." -ForegroundColor Green
