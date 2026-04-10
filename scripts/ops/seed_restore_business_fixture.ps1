param(
    [string]$PostgresContainerName = "gdms-postgres",
    [string]$PostgresServiceName = "postgres",
    [string]$DatabaseUser = "gdms",
    [string]$TargetDatabaseName = "gdms",
    [string]$TargetStorageRoot = ""
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

function Invoke-PostgresNonQuery {
    param(
        [string]$ContainerName,
        [string]$DatabaseName,
        [string]$UserName,
        [string]$Sql
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "docker"
    $startInfo.Arguments = "exec -i $ContainerName psql -U $UserName -d $DatabaseName -v ON_ERROR_STOP=1"
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $process.StandardInput.Write($Sql)
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        $detail = if (-not [string]::IsNullOrWhiteSpace($stderr)) { $stderr.Trim() } else { $stdout.Trim() }
        throw "Fallo la ejecucion SQL sobre '$DatabaseName'. $detail"
    }
}

function Convert-ToSqlLiteral {
    param([string]$Value)

    return $Value.Replace("'", "''")
}

$repoRoot = Get-RepoRoot
$resolvedStorageRoot = if ([string]::IsNullOrWhiteSpace($TargetStorageRoot)) {
    Get-DefaultStorageRoot -RepoRoot $repoRoot
} else {
    [System.IO.Path]::GetFullPath($TargetStorageRoot)
}

$postgresContainerName = Resolve-PostgresContainerName -PreferredContainerName $PostgresContainerName -ServiceName $PostgresServiceName

$fixtureTenantCode = "RECOVERY_FIXTURE"
$fixtureTenantName = "Recovery Fixture Tenant"
$fixtureUserEmail = "recovery.fixture@gdms.local"
$fixtureUserName = "Recovery Fixture"
$fixtureUserPassword = "RecoveryFixture!2026"
$fixtureUserPasswordHash = "AQAAAAIAAYagAAAAEHXlyZBd9WdmsxrdS4yka3atND23dRe/sbYRnLz2LXrqGY8GNCtSTNZGxWjpaJtrdg=="
$fixtureReviewerEmail = "recovery.reviewer@gdms.local"
$fixtureReviewerName = "Recovery Reviewer"
$fixtureDocumentTitle = "Recovery Fixture Contract"
$fixtureWorkflowTitle = "Review Recovery Fixture Contract"
$fixtureWorkflowNotes = "Validated during recovery drill"
$fixtureSignatureExternalReference = "RECOVERY-SIGNATURE-001"
$fixtureSignatureProviderCode = "INTERNAL"
$fixtureLegalHoldReason = "Preserve recovery fixture for evidence export validation"
$fixtureAuditEventType = "RECOVERY_FIXTURE_REVIEWED"
$fixtureAuditPayloadJson = '{"source":"recovery-drill","stage":"fixture-seed"}'
$fixtureStorageKeyV1 = "recovery-fixture/recovery-fixture-contract-v1.txt"
$fixtureStorageKeyV2 = "recovery-fixture/recovery-fixture-contract-v2.txt"
$fixtureMimeType = "text/plain"
$fixtureMetadataJson = '{"counterparty":"Recovery Fixture Corp","contractNumber":"REC-001","effectiveDate":"2026-04-09"}'
$fixtureContentV1 = @"
GDMS recovery fixture contract
contractNumber=REC-001
tenant=RECOVERY_FIXTURE
version=1
"@
$fixtureContentV2 = @"
GDMS recovery fixture contract
contractNumber=REC-001
tenant=RECOVERY_FIXTURE
version=2
approvedBy=Recovery Reviewer
"@

$storageFilePathV1 = Join-Path $resolvedStorageRoot ($fixtureStorageKeyV1 -replace '/', '\')
$storageFilePathV2 = Join-Path $resolvedStorageRoot ($fixtureStorageKeyV2 -replace '/', '\')
$storageDirectory = Split-Path -Parent $storageFilePathV1
New-Item -ItemType Directory -Path $storageDirectory -Force | Out-Null
[System.IO.File]::WriteAllText($storageFilePathV1, $fixtureContentV1, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($storageFilePathV2, $fixtureContentV2, [System.Text.UTF8Encoding]::new($false))

$fixtureHashV1 = (Get-FileHash -Path $storageFilePathV1 -Algorithm SHA256).Hash.ToLowerInvariant()
$fixtureSizeV1 = (Get-Item -LiteralPath $storageFilePathV1).Length
$fixtureHashV2 = (Get-FileHash -Path $storageFilePathV2 -Algorithm SHA256).Hash.ToLowerInvariant()
$fixtureSizeV2 = (Get-Item -LiteralPath $storageFilePathV2).Length

$sql = @"
DO `$`$
DECLARE
    fixture_tenant_id uuid;
    fixture_user_id uuid;
    fixture_reviewer_user_id uuid;
    fixture_role_id uuid;
    fixture_document_type_id uuid;
    fixture_retention_policy_id uuid;
    fixture_document_id uuid;
BEGIN
    INSERT INTO platform.tenants (code, name, sector, primary_country_code, is_active)
    VALUES ('$(Convert-ToSqlLiteral $fixtureTenantCode)', '$(Convert-ToSqlLiteral $fixtureTenantName)', 'CORPORATE', 'AR', true)
    ON CONFLICT (code) DO UPDATE
    SET name = EXCLUDED.name,
        sector = EXCLUDED.sector,
        primary_country_code = EXCLUDED.primary_country_code,
        is_active = true;

    SELECT tenant_id INTO fixture_tenant_id
    FROM platform.tenants
    WHERE code = '$(Convert-ToSqlLiteral $fixtureTenantCode)';

    INSERT INTO identity.users (tenant_id, email, full_name, status, password_hash, must_change_password, failed_login_count)
    VALUES (fixture_tenant_id, '$(Convert-ToSqlLiteral $fixtureUserEmail)', '$(Convert-ToSqlLiteral $fixtureUserName)', 'ACTIVE', '$(Convert-ToSqlLiteral $fixtureUserPasswordHash)', false, 0)
    ON CONFLICT (tenant_id, email) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        status = 'ACTIVE',
        password_hash = EXCLUDED.password_hash,
        must_change_password = false,
        failed_login_count = 0;

    SELECT user_id INTO fixture_user_id
    FROM identity.users
    WHERE tenant_id = fixture_tenant_id
      AND email = '$(Convert-ToSqlLiteral $fixtureUserEmail)';

    INSERT INTO identity.users (tenant_id, email, full_name, status, password_hash, must_change_password, failed_login_count)
    VALUES (fixture_tenant_id, '$(Convert-ToSqlLiteral $fixtureReviewerEmail)', '$(Convert-ToSqlLiteral $fixtureReviewerName)', 'ACTIVE', NULL, false, 0)
    ON CONFLICT (tenant_id, email) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        status = 'ACTIVE',
        must_change_password = false,
        failed_login_count = 0;

    SELECT user_id INTO fixture_reviewer_user_id
    FROM identity.users
    WHERE tenant_id = fixture_tenant_id
      AND email = '$(Convert-ToSqlLiteral $fixtureReviewerEmail)';

    SELECT role_id INTO fixture_role_id
    FROM identity.roles
    WHERE code = 'DOCUMENT_OPERATOR';

    IF fixture_role_id IS NOT NULL THEN
        INSERT INTO identity.user_roles (user_id, role_id)
        VALUES (fixture_user_id, fixture_role_id)
        ON CONFLICT (user_id, role_id) DO NOTHING;

        INSERT INTO identity.user_roles (user_id, role_id)
        VALUES (fixture_reviewer_user_id, fixture_role_id)
        ON CONFLICT (user_id, role_id) DO NOTHING;
    END IF;

    SELECT role_id INTO fixture_role_id
    FROM identity.roles
    WHERE code = 'TENANT_ADMIN';

    IF fixture_role_id IS NOT NULL THEN
        INSERT INTO identity.user_roles (user_id, role_id)
        VALUES (fixture_user_id, fixture_role_id)
        ON CONFLICT (user_id, role_id) DO NOTHING;
    END IF;

    SELECT document_type_id INTO fixture_document_type_id
    FROM configuration.document_types
    WHERE tenant_id IS NULL
      AND code = 'CONTRACT';

    SELECT retention_policy_id INTO fixture_retention_policy_id
    FROM records.retention_policies
    WHERE tenant_id IS NULL
      AND code = 'CONTRACT_10Y';

    SELECT document_id INTO fixture_document_id
    FROM documents.documents
    WHERE tenant_id = fixture_tenant_id
      AND title = '$(Convert-ToSqlLiteral $fixtureDocumentTitle)'
    ORDER BY created_at_utc ASC
    LIMIT 1;

    IF fixture_document_id IS NULL THEN
        INSERT INTO documents.documents
            (tenant_id, document_type_id, retention_policy_id, title, status, confidentiality_level, current_version_number, created_by_user_id)
        VALUES
            (fixture_tenant_id, fixture_document_type_id, fixture_retention_policy_id, '$(Convert-ToSqlLiteral $fixtureDocumentTitle)', 'ACTIVE', 2, 1, fixture_user_id)
        RETURNING document_id INTO fixture_document_id;
    ELSE
        UPDATE documents.documents
        SET document_type_id = fixture_document_type_id,
            retention_policy_id = fixture_retention_policy_id,
            status = 'ACTIVE',
            confidentiality_level = 2,
            current_version_number = 2,
            created_by_user_id = fixture_user_id
        WHERE document_id = fixture_document_id;
    END IF;

    DELETE FROM documents.document_versions
    WHERE document_id = fixture_document_id;

    INSERT INTO documents.document_versions
        (document_version_id, document_id, version_number, storage_object_key, mime_type, file_hash_sha256, file_size_bytes, uploaded_by_user_id)
    VALUES
        (gen_random_uuid(), fixture_document_id, 1, '$(Convert-ToSqlLiteral $fixtureStorageKeyV1)', '$(Convert-ToSqlLiteral $fixtureMimeType)', '$(Convert-ToSqlLiteral $fixtureHashV1)', $fixtureSizeV1, fixture_user_id),
        (gen_random_uuid(), fixture_document_id, 2, '$(Convert-ToSqlLiteral $fixtureStorageKeyV2)', '$(Convert-ToSqlLiteral $fixtureMimeType)', '$(Convert-ToSqlLiteral $fixtureHashV2)', $fixtureSizeV2, fixture_user_id);

    UPDATE documents.documents
    SET current_version_number = 2
    WHERE document_id = fixture_document_id;

    INSERT INTO documents.document_metadata (document_id, tenant_id, metadata, updated_at_utc)
    VALUES (fixture_document_id, fixture_tenant_id, CAST('$(Convert-ToSqlLiteral $fixtureMetadataJson)' AS jsonb), timezone('utc', now()))
    ON CONFLICT (document_id) DO UPDATE
    SET metadata = EXCLUDED.metadata,
        updated_at_utc = EXCLUDED.updated_at_utc,
        tenant_id = EXCLUDED.tenant_id;

    DELETE FROM documents.document_access_entries
    WHERE document_id = fixture_document_id
      AND user_id IN (fixture_reviewer_user_id);

    INSERT INTO documents.document_access_entries
        (document_access_entry_id, tenant_id, document_id, user_id, permission_code, granted_by_user_id, granted_at_utc)
    VALUES
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, fixture_reviewer_user_id, 'READ', fixture_user_id, timezone('utc', now())),
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, fixture_reviewer_user_id, 'DOWNLOAD', fixture_user_id, timezone('utc', now())),
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, fixture_reviewer_user_id, 'EDITMETADATA', fixture_user_id, timezone('utc', now())),
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, fixture_reviewer_user_id, 'UPLOADVERSION', fixture_user_id, timezone('utc', now()));

    DELETE FROM workflow.workflow_tasks
    WHERE tenant_id = fixture_tenant_id
      AND document_id = fixture_document_id
      AND title = '$(Convert-ToSqlLiteral $fixtureWorkflowTitle)';

    INSERT INTO workflow.workflow_tasks
        (workflow_task_id, tenant_id, document_id, title, notes, status, created_by_user_id, created_at_utc, due_at_utc, completed_by_user_id, completed_at_utc, assigned_to_user_id)
    VALUES
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, '$(Convert-ToSqlLiteral $fixtureWorkflowTitle)', '$(Convert-ToSqlLiteral $fixtureWorkflowNotes)', 'COMPLETED', fixture_user_id, timezone('utc', now()) - interval '2 days', timezone('utc', now()) - interval '1 day', fixture_reviewer_user_id, timezone('utc', now()) - interval '12 hours', fixture_reviewer_user_id);

    DELETE FROM signature.signature_envelopes
    WHERE tenant_id = fixture_tenant_id
      AND document_id = fixture_document_id
      AND external_reference = '$(Convert-ToSqlLiteral $fixtureSignatureExternalReference)';

    INSERT INTO signature.signature_envelopes
        (signature_envelope_id, tenant_id, document_id, signer_display_name, signer_email, signature_level, provider_code, external_reference, status, requested_by_user_id, requested_at_utc, due_at_utc, completed_by_user_id, completed_at_utc)
    VALUES
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, '$(Convert-ToSqlLiteral $fixtureReviewerName)', '$(Convert-ToSqlLiteral $fixtureReviewerEmail)', 'ELECTRONIC', '$(Convert-ToSqlLiteral $fixtureSignatureProviderCode)', '$(Convert-ToSqlLiteral $fixtureSignatureExternalReference)', 'SIGNED', fixture_user_id, timezone('utc', now()) - interval '1 day', timezone('utc', now()) + interval '13 days', fixture_reviewer_user_id, timezone('utc', now()) - interval '6 hours');

    DELETE FROM records.legal_holds
    WHERE tenant_id = fixture_tenant_id
      AND document_id = fixture_document_id
      AND reason = '$(Convert-ToSqlLiteral $fixtureLegalHoldReason)';

    INSERT INTO records.legal_holds
        (legal_hold_id, tenant_id, document_id, reason, is_active, created_by_user_id, created_at_utc)
    VALUES
        (gen_random_uuid(), fixture_tenant_id, fixture_document_id, '$(Convert-ToSqlLiteral $fixtureLegalHoldReason)', true, fixture_user_id, timezone('utc', now()) - interval '3 hours');

    DELETE FROM audit.audit_events
    WHERE tenant_id = fixture_tenant_id
      AND document_id = fixture_document_id
      AND event_type = '$(Convert-ToSqlLiteral $fixtureAuditEventType)';

    INSERT INTO audit.audit_events
        (tenant_id, actor_user_id, document_id, event_type, severity, payload, occurred_at_utc)
    VALUES
        (fixture_tenant_id, fixture_user_id, fixture_document_id, '$(Convert-ToSqlLiteral $fixtureAuditEventType)', 'INFO', CAST('$(Convert-ToSqlLiteral $fixtureAuditPayloadJson)' AS jsonb), timezone('utc', now()) - interval '90 minutes');
END
`$`$;
"@

Invoke-PostgresNonQuery -ContainerName $postgresContainerName -DatabaseName $TargetDatabaseName -UserName $DatabaseUser -Sql $sql

[pscustomobject]@{
    TargetDatabase = $TargetDatabaseName
    TargetStorageRoot = $resolvedStorageRoot
    FixtureTenantCode = $fixtureTenantCode
    FixtureDocumentTitle = $fixtureDocumentTitle
    FixtureUserEmail = $fixtureUserEmail
    FixtureUserPassword = $fixtureUserPassword
    FixtureWorkflowTitle = $fixtureWorkflowTitle
    FixtureSignatureExternalReference = $fixtureSignatureExternalReference
    FixtureLegalHoldReason = $fixtureLegalHoldReason
    FixtureAuditEventType = $fixtureAuditEventType
    FixtureStorageKeyV1 = $fixtureStorageKeyV1
    FixtureStorageKeyV2 = $fixtureStorageKeyV2
    FixtureFileHashSha256V1 = $fixtureHashV1
    FixtureFileHashSha256V2 = $fixtureHashV2
    FixtureFileSizeBytesV1 = $fixtureSizeV1
    FixtureFileSizeBytesV2 = $fixtureSizeV2
} | Format-List

Write-Host "Fixture de recovery sembrado correctamente." -ForegroundColor Green
