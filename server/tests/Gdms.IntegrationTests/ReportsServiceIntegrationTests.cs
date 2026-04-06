namespace Gdms.IntegrationTests;

public sealed class ReportsServiceIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public ReportsServiceIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task GetOperationalSummaryAsync_Should_Aggregate_Tenant_State_From_Real_Data()
    {
        var tenant = await CreateTenantAsync("reports_ops", "Reports Ops");
        var actor = await CreateUserAsync(tenant.Id, "reports.ops@tenant.ar");
        var assignee = await CreateUserAsync(tenant.Id, "reports.assignee@tenant.ar");
        var documentA = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato operativo A");
        var documentB = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato operativo B");
        var service = CreateReportsService();

        await new PostgresLegalHoldRepository(_fixture.DataSource).AddAsync(
            LegalHold.Create(tenant.Id, documentA.Id, "Investigacion activa", actor.Id, DateTimeOffset.UtcNow),
            CancellationToken.None);
        await new PostgresWorkflowTaskRepository(_fixture.DataSource).AddAsync(
            WorkflowTask.Create(
                tenant.Id,
                documentA.Id,
                "Revisar vencimiento",
                null,
                assignee.Id,
                actor.Id,
                DateTimeOffset.UtcNow,
                DateTimeOffset.UtcNow.AddDays(1)),
            CancellationToken.None);

        var signatureRepository = new PostgresSignatureEnvelopeRepository(_fixture.DataSource);
        var pendingEnvelope = await signatureRepository.AddAsync(
            SignatureEnvelope.Create(
                tenant.Id,
                documentA.Id,
                "Firmante Operativo",
                "pending@tenant.ar",
                "ELECTRONIC",
                null,
                "pending-ref",
                actor.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);
        var cancelledEnvelope = await signatureRepository.AddAsync(
            SignatureEnvelope.Create(
                tenant.Id,
                documentB.Id,
                "Firmante Cancelado",
                "cancelled@tenant.ar",
                "DIGITAL",
                null,
                "cancelled-ref",
                actor.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);
        await signatureRepository.CancelAsync(
            tenant.Id,
            cancelledEnvelope.Id,
            actor.Id,
            DateTimeOffset.UtcNow,
            "Cancelacion operativa",
            CancellationToken.None);

        await InsertDueDocumentAsync(tenant.Id, actor.Id, "Contrato vencido");

        var auditRepository = new PostgresAuditEventRepository(_fixture.DataSource);
        await auditRepository.WriteAsync(
            tenant.Id,
            actor.Id,
            null,
            "LOGIN_FAILED",
            "ERROR",
            """{"reason":"bad-password"}""",
            CancellationToken.None);
        await auditRepository.WriteAsync(
            tenant.Id,
            actor.Id,
            null,
            "LOGIN_FAILED",
            "ERROR",
            """{"reason":"outdated-window"}""",
            CancellationToken.None);

        var summary = await service.GetOperationalSummaryAsync(tenant.Id, CancellationToken.None);

        Assert.Equal(3, summary.TotalDocuments);
        Assert.Equal(1, summary.ActiveLegalHolds);
        Assert.Equal(1, summary.OpenWorkflowTasks);
        Assert.Equal(1, summary.PendingSignatures);
        Assert.Equal(1, summary.CancelledSignatures);
        Assert.Equal(1, summary.PendingDispositionItems);
        Assert.Equal(2, summary.FailedLoginsLast24Hours);
        Assert.NotEqual(Guid.Empty, pendingEnvelope.Id);
    }

    [PostgresIntegrationFact]
    public async Task GetPlatformSummaryAsync_Should_Aggregate_Multiple_Tenants()
    {
        var tenantA = await CreateTenantAsync("reports_platform_a", "Reports Platform A");
        var tenantB = await CreateTenantAsync("reports_platform_b", "Reports Platform B");
        var actorA = await CreateUserAsync(tenantA.Id, "platform.a@tenant.ar");
        var actorB = await CreateUserAsync(tenantB.Id, "platform.b@tenant.ar");
        var documentA = await CreateDocumentAsync(tenantA.Id, actorA.Id, "Documento tenant A");
        var documentB = await CreateDocumentAsync(tenantB.Id, actorB.Id, "Documento tenant B");
        var service = CreateReportsService();

        await new PostgresWorkflowTaskRepository(_fixture.DataSource).AddAsync(
            WorkflowTask.Create(
                tenantA.Id,
                documentA.Id,
                "Task abierta tenant A",
                null,
                actorA.Id,
                actorA.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);

        var signatureRepository = new PostgresSignatureEnvelopeRepository(_fixture.DataSource);
        await signatureRepository.AddAsync(
            SignatureEnvelope.Create(
                tenantA.Id,
                documentA.Id,
                "Firmante Tenant A",
                "tenant.a@sign.ar",
                "ELECTRONIC",
                null,
                "platform-pending",
                actorA.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);

        var cancelledEnvelope = await signatureRepository.AddAsync(
            SignatureEnvelope.Create(
                tenantB.Id,
                documentB.Id,
                "Firmante Tenant B",
                "tenant.b@sign.ar",
                "DIGITAL",
                null,
                "platform-cancelled",
                actorB.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);
        await signatureRepository.CancelAsync(
            tenantB.Id,
            cancelledEnvelope.Id,
            actorB.Id,
            DateTimeOffset.UtcNow,
            "Remplazo contractual",
            CancellationToken.None);

        var auditRepository = new PostgresAuditEventRepository(_fixture.DataSource);
        await auditRepository.WriteAsync(
            tenantA.Id,
            actorA.Id,
            null,
            "LOGIN_FAILED",
            "ERROR",
            """{"reason":"bad-password"}""",
            CancellationToken.None);
        await auditRepository.WriteAsync(
            tenantB.Id,
            actorB.Id,
            null,
            "LOGIN_FAILED",
            "ERROR",
            """{"reason":"bad-password"}""",
            CancellationToken.None);

        var summary = await service.GetPlatformSummaryAsync(CancellationToken.None);

        Assert.True(summary.TotalTenants >= 2);
        Assert.True(summary.TotalDocuments >= 2);
        Assert.True(summary.OpenWorkflowTasks >= 1);
        Assert.True(summary.PendingSignatures >= 1);
        Assert.True(summary.CancelledSignatures >= 1);
        Assert.True(summary.FailedLoginsLast24Hours >= 2);
    }

    private ReportsService CreateReportsService()
    {
        return new ReportsService(
            new PostgresTenantRepository(_fixture.DataSource),
            new PostgresDocumentRepository(_fixture.DataSource),
            new PostgresLegalHoldRepository(_fixture.DataSource),
            new PostgresWorkflowTaskRepository(_fixture.DataSource),
            new PostgresSignatureEnvelopeRepository(_fixture.DataSource),
            new PostgresDocumentDispositionRepository(_fixture.DataSource),
            new PostgresAuditEventRepository(_fixture.DataSource));
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_fixture.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "Reports Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_fixture.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/reports/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
            640,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_fixture.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task InsertDueDocumentAsync(Guid tenantId, Guid createdByUserId, string title)
    {
        var retentionPolicyId = await GetRetentionPolicyIdAsync("CONTRACT_10Y");
        await using var command = _fixture.DataSource.CreateCommand(
            """
            INSERT INTO documents.documents
                (document_id, tenant_id, document_type_id, retention_policy_id, title, status, confidentiality_level, current_version_number, created_by_user_id, created_at_utc)
            SELECT
                @document_id,
                @tenant_id,
                document_type_id,
                @retention_policy_id,
                @title,
                'ACTIVE',
                1,
                0,
                @created_by_user_id,
                @created_at_utc
            FROM configuration.document_types
            WHERE code = 'CONTRACT'
            ORDER BY tenant_id NULLS FIRST
            LIMIT 1;
            """);
        command.Parameters.AddWithValue("document_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("retention_policy_id", retentionPolicyId);
        command.Parameters.AddWithValue("title", title);
        command.Parameters.AddWithValue("created_by_user_id", createdByUserId);
        command.Parameters.AddWithValue("created_at_utc", DateTimeOffset.UtcNow.AddDays(-4000));
        await command.ExecuteNonQueryAsync();
    }

    private async Task<Guid> GetRetentionPolicyIdAsync(string policyCode)
    {
        await using var command = _fixture.DataSource.CreateCommand(
            """
            SELECT retention_policy_id
            FROM records.retention_policies
            WHERE code = @code
            LIMIT 1;
            """);
        command.Parameters.AddWithValue("code", policyCode);
        var result = await command.ExecuteScalarAsync();
        return (Guid)result!;
    }
}
