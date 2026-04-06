namespace Gdms.IntegrationTests;

public sealed class RecordsServiceIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public RecordsServiceIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task ApplyRetentionPolicyAsync_Should_Persist_Assignment_And_Audit_Event()
    {
        var tenant = await CreateTenantAsync("records_retention", "Records Retention");
        var user = await CreateUserAsync(tenant.Id, "records@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, user.Id, "Contrato con Retencion");
        var service = CreateRecordsService();

        await service.ApplyRetentionPolicyAsync(
            tenant.Id,
            document.Id,
            "CONTRACT_10Y",
            user.Id,
            CancellationToken.None);

        var policyCode = await GetAssignedRetentionPolicyCodeAsync(document.Id);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.Equal("CONTRACT_10Y", policyCode);
        Assert.Contains(auditEvents, entry => entry.EventType == "RETENTION_POLICY_APPLIED");
    }

    [PostgresIntegrationFact]
    public async Task CreateAndReleaseLegalHoldAsync_Should_Persist_State_And_Audit_Events()
    {
        var tenant = await CreateTenantAsync("records_hold", "Records Hold");
        var user = await CreateUserAsync(tenant.Id, "hold@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, user.Id, "Contrato con Hold");
        var service = CreateRecordsService();

        var legalHold = await service.CreateLegalHoldAsync(
            tenant.Id,
            document.Id,
            "Investigacion regulatoria",
            user.Id,
            CancellationToken.None);
        var released = await service.ReleaseLegalHoldAsync(
            tenant.Id,
            legalHold.Id,
            "Revision completada",
            user.Id,
            CancellationToken.None);

        var holds = await service.ListLegalHoldsAsync(tenant.Id, document.Id, CancellationToken.None);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.Single(holds);
        Assert.False(holds.Single().IsActive);
        Assert.Equal("Revision completada", released.ReleaseReason);
        Assert.Contains(auditEvents, entry => entry.EventType == "LEGAL_HOLD_CREATED");
        Assert.Contains(auditEvents, entry => entry.EventType == "LEGAL_HOLD_RELEASED");
    }

    [PostgresIntegrationFact]
    public async Task ListDispositionCandidatesAsync_Should_Return_Due_Documents_When_Retention_Expired()
    {
        var tenant = await CreateTenantAsync("records_due", "Records Due");
        var user = await CreateUserAsync(tenant.Id, "due@tenant.ar");
        var service = CreateRecordsService();
        var retentionPolicyId = await GetRetentionPolicyIdAsync("CONTRACT_10Y");
        var dueDocumentId = Guid.NewGuid();

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
        command.Parameters.AddWithValue("document_id", dueDocumentId);
        command.Parameters.AddWithValue("tenant_id", tenant.Id);
        command.Parameters.AddWithValue("retention_policy_id", retentionPolicyId);
        command.Parameters.AddWithValue("title", "Contrato vencido");
        command.Parameters.AddWithValue("created_by_user_id", user.Id);
        command.Parameters.AddWithValue("created_at_utc", DateTimeOffset.UtcNow.AddDays(-4000));
        await command.ExecuteNonQueryAsync();

        var candidates = await service.ListDispositionCandidatesAsync(
            tenant.Id,
            DateTimeOffset.UtcNow,
            CancellationToken.None);

        Assert.Contains(candidates, candidate =>
            candidate.DocumentId == dueDocumentId &&
            candidate.RetentionPolicyCode == "CONTRACT_10Y" &&
            candidate.RecommendedAction == "ARCHIVE");
    }

    private RecordsService CreateRecordsService()
    {
        return new RecordsService(
            new PostgresTenantRepository(_fixture.DataSource),
            new PostgresDocumentRepository(_fixture.DataSource),
            new PostgresDocumentDispositionRepository(_fixture.DataSource),
            new PostgresRetentionPolicyRepository(_fixture.DataSource),
            new PostgresLegalHoldRepository(_fixture.DataSource),
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
        var user = User.Create(tenantId, email, "Records Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_fixture.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/contracts/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            256,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_fixture.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task<string?> GetAssignedRetentionPolicyCodeAsync(Guid documentId)
    {
        await using var command = _fixture.DataSource.CreateCommand(
            """
            SELECT rp.code
            FROM documents.documents d
            INNER JOIN records.retention_policies rp ON rp.retention_policy_id = d.retention_policy_id
            WHERE d.document_id = @document_id;
            """);
        command.Parameters.AddWithValue("document_id", documentId);
        return await command.ExecuteScalarAsync() as string;
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
