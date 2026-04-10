param(
    [string]$PostgresContainerName = "gdms-postgres",
    [string]$PostgresServiceName = "postgres",
    [string]$DatabaseUser = "gdms",
    [string]$TargetDatabaseName = "gdms",
    [string]$TargetStorageRoot = "",
    [switch]$RequireFixtureDocument
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-DefaultStorageRoot {
    param([string]$RepoRoot)

    $appSettingsPath = Join-Path $RepoRoot "server\src\Gdms.Api\appsettings.json"
    $appSettings = Get-Content -Path $appSettingsPath -Raw | ConvertFrom-Json
    $configuredPath = [string]$appSettings.Storage.LocalRootPath
    if ([string]::IsNullOrWhiteSpace($configuredPath)) {
        $configuredPath = "data/storage/documents"
    }

    $contentRoot = Join-Path $RepoRoot "server\src\Gdms.Api"
    if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        return [System.IO.Path]::GetFullPath($configuredPath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $contentRoot $configuredPath))
}

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
        [string]$Sql,
        [int]$RetryCount = 10,
        [int]$RetryDelaySeconds = 2
    )

    $lastError = ""
    for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
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
            if ($process.ExitCode -eq 0) {
                return "$stdout".Trim()
            }

            $lastError = if (-not [string]::IsNullOrWhiteSpace($stderr)) {
                "$stderr".Trim()
            } else {
                "$stdout".Trim()
            }
        } finally {
            $process.Dispose()
        }

        if ($attempt -lt $RetryCount) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    throw "Fallo consulta PostgreSQL sobre '$DatabaseName'. $lastError"
}

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

$repoRoot = Get-RepoRoot
$resolvedStorageRoot = if ([string]::IsNullOrWhiteSpace($TargetStorageRoot)) {
    Get-DefaultStorageRoot -RepoRoot $repoRoot
} else {
    [System.IO.Path]::GetFullPath($TargetStorageRoot)
}

$postgresContainerName = Resolve-PostgresContainerName -PreferredContainerName $PostgresContainerName -ServiceName $PostgresServiceName
$results = [System.Collections.Generic.List[object]]::new()

$rolesCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM identity.roles;")
if ($rolesCount -ge 5) {
    Add-CheckResult -Results $results -Name "Identity roles seed" -Status "OK" -Detail "Roles sembrados: $rolesCount."
} else {
    Add-CheckResult -Results $results -Name "Identity roles seed" -Status "FAIL" -Detail "Se esperaban al menos 5 roles seed y solo hay $rolesCount."
}

$documentTypesCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM configuration.document_types WHERE tenant_id IS NULL;")
if ($documentTypesCount -ge 4) {
    Add-CheckResult -Results $results -Name "Document types seed" -Status "OK" -Detail "Tipos documentales seed: $documentTypesCount."
} else {
    Add-CheckResult -Results $results -Name "Document types seed" -Status "FAIL" -Detail "Se esperaban al menos 4 tipos documentales seed y solo hay $documentTypesCount."
}

$contractSchemaCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM configuration.document_types WHERE tenant_id IS NULL AND code IN ('CONTRACT','PROPERTY_DOSSIER','CASE_FILE','INVOICE') AND metadata_schema <> '{}'::jsonb;")
if ($contractSchemaCount -eq 4) {
    Add-CheckResult -Results $results -Name "Document type metadata schema" -Status "OK" -Detail "Los tipos documentales seed conservan metadata_schema."
} else {
    Add-CheckResult -Results $results -Name "Document type metadata schema" -Status "FAIL" -Detail "Solo $contractSchemaCount de 4 tipos seed conservan metadata_schema."
}

$retentionPoliciesCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM records.retention_policies WHERE tenant_id IS NULL;")
if ($retentionPoliciesCount -ge 4) {
    Add-CheckResult -Results $results -Name "Retention policies seed" -Status "OK" -Detail "Politicas seed: $retentionPoliciesCount."
} else {
    Add-CheckResult -Results $results -Name "Retention policies seed" -Status "FAIL" -Detail "Se esperaban al menos 4 politicas seed y solo hay $retentionPoliciesCount."
}

$tableCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('platform','identity','configuration','documents','records','audit','workflow','signature');")
if ($tableCount -ge 15) {
    Add-CheckResult -Results $results -Name "Core business tables" -Status "OK" -Detail "Tablas de negocio detectadas: $tableCount."
} else {
    Add-CheckResult -Results $results -Name "Core business tables" -Status "FAIL" -Detail "Cantidad inesperadamente baja de tablas de negocio: $tableCount."
}

$orphanVersionsCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM documents.document_versions dv LEFT JOIN documents.documents d ON d.document_id = dv.document_id WHERE d.document_id IS NULL;")
if ($orphanVersionsCount -eq 0) {
    Add-CheckResult -Results $results -Name "Orphan document versions" -Status "OK" -Detail "No hay versiones huerfanas."
} else {
    Add-CheckResult -Results $results -Name "Orphan document versions" -Status "FAIL" -Detail "Se detectaron $orphanVersionsCount versiones huerfanas."
}

$versionMismatchCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT COUNT(*)
FROM documents.documents d
LEFT JOIN (
    SELECT document_id, MAX(version_number) AS max_version_number
    FROM documents.document_versions
    GROUP BY document_id
) dv ON dv.document_id = d.document_id
WHERE d.current_version_number <> COALESCE(dv.max_version_number, 0);
"@)
if ($versionMismatchCount -eq 0) {
    Add-CheckResult -Results $results -Name "Document current version integrity" -Status "OK" -Detail "No hay desalineacion entre current_version_number y max(version_number)."
} else {
    Add-CheckResult -Results $results -Name "Document current version integrity" -Status "FAIL" -Detail "Se detectaron $versionMismatchCount documentos con version actual inconsistente."
}

$documentVersionsCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM documents.document_versions;")
$storageFileCount = if (Test-Path -LiteralPath $resolvedStorageRoot) {
    @(Get-ChildItem -Path $resolvedStorageRoot -Recurse -File -Force -ErrorAction SilentlyContinue).Count
} else {
    0
}

if ($documentVersionsCount -eq 0) {
    Add-CheckResult -Results $results -Name "Storage vs document versions" -Status "OK" -Detail "No hay versiones documentales; storage con $storageFileCount archivos."
} elseif ($storageFileCount -lt $documentVersionsCount) {
    Add-CheckResult -Results $results -Name "Storage vs document versions" -Status "WARN" -Detail "Hay $documentVersionsCount versiones documentales y solo $storageFileCount archivos en storage."
} else {
    Add-CheckResult -Results $results -Name "Storage vs document versions" -Status "OK" -Detail "Storage con $storageFileCount archivos para $documentVersionsCount versiones documentales."
}

$tenantCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM platform.tenants;")
$userCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM identity.users;")
Add-CheckResult -Results $results -Name "Tenant/user business presence" -Status "OK" -Detail "Tenants: $tenantCount. Usuarios: $userCount."

$fixtureDocumentCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql "SELECT COUNT(*) FROM documents.documents d INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id WHERE t.code = 'RECOVERY_FIXTURE' AND d.title = 'Recovery Fixture Contract';")
if ($RequireFixtureDocument -and $fixtureDocumentCount -eq 0) {
    Add-CheckResult -Results $results -Name "Recovery fixture document presence" -Status "FAIL" -Detail "No se encontro el documento fixture requerido."
} elseif ($fixtureDocumentCount -eq 0) {
    Add-CheckResult -Results $results -Name "Recovery fixture document presence" -Status "OK" -Detail "No hay fixture documental sembrado en este restore."
} else {
    $fixtureVersionsRaw = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT string_agg(
    CONCAT_WS('|',
        dv.version_number::text,
        dv.storage_object_key,
        dv.file_hash_sha256,
        dv.file_size_bytes::text),
    '||ROW||'
    ORDER BY dv.version_number)
FROM documents.documents d
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
INNER JOIN documents.document_versions dv ON dv.document_id = d.document_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract';
"@
    $fixtureVersions = @(
        "$fixtureVersionsRaw".Split([string[]]@("||ROW||"), [System.StringSplitOptions]::RemoveEmptyEntries) |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($fixtureVersions.Count -ne 2) {
        Add-CheckResult -Results $results -Name "Recovery fixture versions" -Status "FAIL" -Detail "Se esperaban 2 versiones del fixture y hay $($fixtureVersions.Count)."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture versions" -Status "OK" -Detail "El fixture conserva 2 versiones documentales."
    }

    foreach ($fixtureVersionRow in $fixtureVersions) {
        if ([string]::IsNullOrWhiteSpace($fixtureVersionRow)) {
            continue
        }

        $fixtureParts = $fixtureVersionRow.Split('|', 4)
        if ($fixtureParts.Length -ne 4) {
            Add-CheckResult -Results $results -Name "Recovery fixture row format" -Status "FAIL" -Detail "Fila de version fixture invalida: '$fixtureVersionRow'."
            continue
        }
        $fixtureVersionNumber = $fixtureParts[0]
        $fixtureStorageKey = $fixtureParts[1]
        $fixtureExpectedHash = $fixtureParts[2]
        $fixtureExpectedSize = [int64]$fixtureParts[3]
        $fixtureFilePath = Join-Path $resolvedStorageRoot ($fixtureStorageKey -replace '/', '\')

        if (-not (Test-Path -LiteralPath $fixtureFilePath)) {
            Add-CheckResult -Results $results -Name "Recovery fixture storage object v$fixtureVersionNumber" -Status "FAIL" -Detail "No existe el archivo fixture '$fixtureStorageKey' en storage."
            continue
        }

        $fixtureActualHash = (Get-FileHash -Path $fixtureFilePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $fixtureActualSize = (Get-Item -LiteralPath $fixtureFilePath).Length

        if ($fixtureActualHash -ne $fixtureExpectedHash) {
            Add-CheckResult -Results $results -Name "Recovery fixture storage hash v$fixtureVersionNumber" -Status "FAIL" -Detail "Hash esperado '$fixtureExpectedHash' pero storage contiene '$fixtureActualHash'."
        } else {
            Add-CheckResult -Results $results -Name "Recovery fixture storage hash v$fixtureVersionNumber" -Status "OK" -Detail "Hash SHA256 de la version $fixtureVersionNumber coincide con la base."
        }

        if ($fixtureActualSize -ne $fixtureExpectedSize) {
            Add-CheckResult -Results $results -Name "Recovery fixture storage size v$fixtureVersionNumber" -Status "FAIL" -Detail "Tamanio esperado '$fixtureExpectedSize' bytes pero storage contiene '$fixtureActualSize'."
        } else {
            Add-CheckResult -Results $results -Name "Recovery fixture storage size v$fixtureVersionNumber" -Status "OK" -Detail "Tamanio de la version $fixtureVersionNumber consistente con la base."
        }
    }

    $fixtureMetadata = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT COALESCE(dm.metadata::text, '{}')
FROM documents.documents d
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
LEFT JOIN documents.document_metadata dm ON dm.document_id = d.document_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
ORDER BY d.created_at_utc ASC
LIMIT 1;
"@

    if ($fixtureMetadata -match '"contractNumber"\s*:\s*"REC-001"' -and $fixtureMetadata -match '"counterparty"\s*:\s*"Recovery Fixture Corp"') {
        Add-CheckResult -Results $results -Name "Recovery fixture metadata payload" -Status "OK" -Detail "Metadata del fixture restaurada correctamente."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture metadata payload" -Status "FAIL" -Detail "La metadata del fixture no contiene los campos esperados."
    }

    $fixtureAclCount = [int](Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT COUNT(*)
FROM documents.document_access_entries dae
INNER JOIN documents.documents d ON d.document_id = dae.document_id
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
INNER JOIN identity.users u ON u.user_id = dae.user_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
  AND u.email = 'recovery.reviewer@gdms.local';
"@)
    if ($fixtureAclCount -ge 4) {
        Add-CheckResult -Results $results -Name "Recovery fixture ACL entries" -Status "OK" -Detail "ACL del fixture restaurada con $fixtureAclCount permisos explicitos."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture ACL entries" -Status "FAIL" -Detail "Se esperaban al menos 4 permisos ACL del fixture y solo hay $fixtureAclCount."
    }

    $fixtureWorkflowState = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT CONCAT_WS('|', wt.status, COALESCE(assignee.email::text, ''), COALESCE(completer.email::text, ''))
FROM workflow.workflow_tasks wt
INNER JOIN documents.documents d ON d.document_id = wt.document_id
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
LEFT JOIN identity.users assignee ON assignee.user_id = wt.assigned_to_user_id
LEFT JOIN identity.users completer ON completer.user_id = wt.completed_by_user_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
  AND wt.title = 'Review Recovery Fixture Contract'
ORDER BY wt.created_at_utc DESC
LIMIT 1;
"@
    if ($fixtureWorkflowState -eq "COMPLETED|recovery.reviewer@gdms.local|recovery.reviewer@gdms.local") {
        Add-CheckResult -Results $results -Name "Recovery fixture workflow state" -Status "OK" -Detail "Workflow restaurado con tarea completada y reviewer correcto."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture workflow state" -Status "FAIL" -Detail "Estado workflow inesperado para el fixture: '$fixtureWorkflowState'."
    }

    $fixtureSignatureState = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT CONCAT_WS('|', se.status, se.provider_code, se.external_reference, COALESCE(se.signer_email::text, ''), COALESCE(completer.email::text, ''))
FROM signature.signature_envelopes se
INNER JOIN documents.documents d ON d.document_id = se.document_id
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
LEFT JOIN identity.users completer ON completer.user_id = se.completed_by_user_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
  AND se.external_reference = 'RECOVERY-SIGNATURE-001'
ORDER BY se.requested_at_utc DESC
LIMIT 1;
"@
    if ($fixtureSignatureState -eq "SIGNED|INTERNAL|RECOVERY-SIGNATURE-001|recovery.reviewer@gdms.local|recovery.reviewer@gdms.local") {
        Add-CheckResult -Results $results -Name "Recovery fixture signature state" -Status "OK" -Detail "Firma restaurada con envelope firmado y reviewer correcto."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture signature state" -Status "FAIL" -Detail "Estado signature inesperado para el fixture: '$fixtureSignatureState'."
    }

    $fixtureLegalHoldState = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT CONCAT_WS('|', lh.reason, lh.is_active::text, COALESCE(creator.email::text, ''))
FROM records.legal_holds lh
INNER JOIN documents.documents d ON d.document_id = lh.document_id
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
LEFT JOIN identity.users creator ON creator.user_id = lh.created_by_user_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
  AND lh.reason = 'Preserve recovery fixture for evidence export validation'
ORDER BY lh.created_at_utc DESC
LIMIT 1;
"@
    if ($fixtureLegalHoldState -eq "Preserve recovery fixture for evidence export validation|true|recovery.fixture@gdms.local") {
        Add-CheckResult -Results $results -Name "Recovery fixture legal hold state" -Status "OK" -Detail "Legal hold restaurado y activo para el fixture."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture legal hold state" -Status "FAIL" -Detail "Estado legal hold inesperado para el fixture: '$fixtureLegalHoldState'."
    }

    $fixtureAuditState = Invoke-PostgresScalar -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql @"
SELECT CONCAT_WS('|', event_type, severity, COALESCE(actor.email::text, ''), COALESCE(payload->>'source', ''))
FROM audit.audit_events ae
INNER JOIN documents.documents d ON d.document_id = ae.document_id
INNER JOIN platform.tenants t ON t.tenant_id = d.tenant_id
LEFT JOIN identity.users actor ON actor.user_id = ae.actor_user_id
WHERE t.code = 'RECOVERY_FIXTURE'
  AND d.title = 'Recovery Fixture Contract'
  AND ae.event_type = 'RECOVERY_FIXTURE_REVIEWED'
ORDER BY ae.occurred_at_utc DESC
LIMIT 1;
"@
    if ($fixtureAuditState -eq "RECOVERY_FIXTURE_REVIEWED|INFO|recovery.fixture@gdms.local|recovery-drill") {
        Add-CheckResult -Results $results -Name "Recovery fixture audit state" -Status "OK" -Detail "Audit event restaurado para el fixture."
    } else {
        Add-CheckResult -Results $results -Name "Recovery fixture audit state" -Status "FAIL" -Detail "Estado audit inesperado para el fixture: '$fixtureAuditState'."
    }
}

$results | Format-Table -AutoSize

$failed = @($results | Where-Object Status -eq "FAIL")
if ($failed.Count -gt 0) {
    throw "Integridad de restore comprometida: $($failed.Count) chequeo(s) en rojo."
}

$warnings = @($results | Where-Object Status -eq "WARN")
if ($warnings.Count -gt 0) {
    Write-Warning "Integridad de restore con advertencias: $($warnings.Count)."
} else {
    Write-Host "Integridad de restore validada en verde." -ForegroundColor Green
}
