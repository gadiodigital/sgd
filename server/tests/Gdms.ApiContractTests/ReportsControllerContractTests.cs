namespace Gdms.ApiContractTests;

public sealed class ReportsControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public ReportsControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetOperationalSummary_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_reports_unauth", "API Reports Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/reports/operational-summary");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetOperationalSummary_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_reports_forbid", "API Reports Forbid");
        await SeedOperationalReportDataAsync(tenant.Id);
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/reports/operational-summary");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Reports_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_reports_ok", "API Reports OK");
        await SeedOperationalReportDataAsync(tenant.Id);
        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN");
        using var platformClient = _factory.CreateClientForPlatformAdmin();

        var operationalResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/reports/operational-summary");
        var platformResponse = await platformClient.GetAsync("/api/reports/platform-summary");
        var operationalBody = await operationalResponse.Content.ReadAsStringAsync();
        var platformBody = await platformResponse.Content.ReadAsStringAsync();

        Assert.True(
            operationalResponse.IsSuccessStatusCode,
            $"Operational summary devolvió {(int)operationalResponse.StatusCode}: {operationalBody}");
        Assert.True(
            platformResponse.IsSuccessStatusCode,
            $"Platform summary devolvió {(int)platformResponse.StatusCode}: {platformBody}");

        var operational = await operationalResponse.Content.ReadFromJsonAsync<OperationalReportResponse>();
        var platform = await platformResponse.Content.ReadFromJsonAsync<PlatformReportResponse>();

        Assert.NotNull(operational);
        Assert.Equal(3, operational!.TotalDocuments);
        Assert.Equal(1, operational.ActiveLegalHolds);
        Assert.Equal(1, operational.OpenWorkflowTasks);
        Assert.Equal(1, operational.PendingSignatures);
        Assert.Equal(1, operational.CancelledSignatures);
        Assert.Equal(1, operational.PendingDispositionItems);
        Assert.Equal(1, operational.FailedLoginsLast24Hours);

        Assert.NotNull(platform);
        Assert.True(platform!.TotalTenants >= 1);
        Assert.True(platform.TotalDocuments >= 3);
        Assert.True(platform.OpenWorkflowTasks >= 1);
        Assert.True(platform.PendingSignatures >= 1);
        Assert.True(platform.CancelledSignatures >= 1);
        Assert.True(platform.FailedLoginsLast24Hours >= 1);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task SeedOperationalReportDataAsync(Guid tenantId)
    {
        var actor = await CreateUserAsync(tenantId, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var assignee = await CreateUserAsync(tenantId, $"assignee.{Guid.NewGuid():N}@tenant.ar");
        var documentA = await CreateDocumentAsync(tenantId, actor.Id, "Contrato API A");
        var documentB = await CreateDocumentAsync(tenantId, actor.Id, "Contrato API B");

        await new PostgresLegalHoldRepository(_factory.DataSource).AddAsync(
            LegalHold.Create(tenantId, documentA.Id, "Hold contractual", actor.Id, DateTimeOffset.UtcNow),
            CancellationToken.None);
        await new PostgresWorkflowTaskRepository(_factory.DataSource).AddAsync(
            WorkflowTask.Create(
                tenantId,
                documentA.Id,
                "Revision API",
                null,
                assignee.Id,
                actor.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);

        var signatureRepository = new PostgresSignatureEnvelopeRepository(_factory.DataSource);
        await signatureRepository.AddAsync(
            SignatureEnvelope.Create(
                tenantId,
                documentA.Id,
                "Firmante API Pendiente",
                $"pending.{Guid.NewGuid():N}@tenant.ar",
                "ELECTRONIC",
                null,
                "api-pending",
                actor.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);
        var cancelledEnvelope = await signatureRepository.AddAsync(
            SignatureEnvelope.Create(
                tenantId,
                documentB.Id,
                "Firmante API Cancelada",
                $"cancelled.{Guid.NewGuid():N}@tenant.ar",
                "DIGITAL",
                null,
                "api-cancelled",
                actor.Id,
                DateTimeOffset.UtcNow,
                null),
            CancellationToken.None);
        await signatureRepository.CancelAsync(
            tenantId,
            cancelledEnvelope.Id,
            actor.Id,
            DateTimeOffset.UtcNow,
            "Cancelacion por reemplazo",
            CancellationToken.None);

        await InsertDueDocumentAsync(tenantId, actor.Id, "Contrato API Vencido");
        await new PostgresAuditEventRepository(_factory.DataSource).WriteAsync(
            tenantId,
            actor.Id,
            null,
            "LOGIN_FAILED",
            "ERROR",
            """{"reason":"bad-password"}""",
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Contract Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-contract/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210",
            512,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task InsertDueDocumentAsync(Guid tenantId, Guid createdByUserId, string title)
    {
        var retentionPolicyId = await GetRetentionPolicyIdAsync("CONTRACT_10Y");
        await using var command = _factory.DataSource.CreateCommand(
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
        await using var command = _factory.DataSource.CreateCommand(
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
