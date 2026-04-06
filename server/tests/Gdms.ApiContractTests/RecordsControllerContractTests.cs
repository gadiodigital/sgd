namespace Gdms.ApiContractTests;

public sealed class RecordsControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public RecordsControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetDispositionCandidates_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_records_unauth", "API Records Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/records/disposition-candidates");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetDispositionCandidates_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_records_forbid", "API Records Forbid");
        await SeedDispositionCandidateAsync(tenant.Id, "Contrato tenant correcto");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "COMPLIANCE_OFFICER");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/records/disposition-candidates");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetDispositionCandidates_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_records_role", "API Records Role");
        await SeedDispositionCandidateAsync(tenant.Id, "Contrato sin rol suficiente");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/records/disposition-candidates");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetDispositionCandidates_Should_Return_Expected_Payload_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_records_ok", "API Records OK");
        var documentId = await SeedDispositionCandidateAsync(tenant.Id, "Contrato vencido API Records");
        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "COMPLIANCE_OFFICER");
        using var platformClient = _factory.CreateClientForPlatformAdmin();

        var tenantResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/records/disposition-candidates");
        var platformResponse = await platformClient.GetAsync($"/api/tenants/{tenant.Id}/records/disposition-candidates");

        tenantResponse.EnsureSuccessStatusCode();
        platformResponse.EnsureSuccessStatusCode();

        var tenantPayload = await tenantResponse.Content.ReadFromJsonAsync<DispositionCandidateResponse[]>();
        var platformPayload = await platformResponse.Content.ReadFromJsonAsync<DispositionCandidateResponse[]>();

        Assert.NotNull(tenantPayload);
        Assert.NotNull(platformPayload);
        Assert.Contains(tenantPayload!, item =>
            item.DocumentId == documentId &&
            item.Title == "Contrato vencido API Records" &&
            item.RetentionPolicyCode == "CONTRACT_10Y" &&
            item.RecommendedAction == "ARCHIVE" &&
            item.HasActiveLegalHold == false);
        Assert.Contains(platformPayload!, item => item.DocumentId == documentId);
    }

    [PostgresContractFact]
    public async Task ApplyRetentionPolicy_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_records_apply_role", "API Records Apply Role");
        var actor = await CreateUserAsync(tenant.Id, $"records.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato sin permisos records");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/records/documents/{document.Id}/retention-policy",
            new ApplyRetentionPolicyRequest { RetentionPolicyCode = "CONTRACT_10Y" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Records_Write_Endpoints_Should_Persist_Expected_State_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_records_write", "API Records Write");
        var actor = await CreateUserAsync(tenant.Id, $"records.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato gestionado por records");
        var expectedPolicyId = await GetRetentionPolicyIdAsync("CONTRACT_10Y");
        using var client = _factory.CreateClientForTenant(tenant.Id, "COMPLIANCE_OFFICER");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var applyResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/records/documents/{document.Id}/retention-policy",
            new ApplyRetentionPolicyRequest { RetentionPolicyCode = " contract_10y " });
        var createHoldResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/records/documents/{document.Id}/legal-holds",
            new CreateLegalHoldRequest { Reason = " Investigacion regulatoria activa " });

        Assert.Equal(HttpStatusCode.NoContent, applyResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Created, createHoldResponse.StatusCode);

        var createdHold = await createHoldResponse.Content.ReadFromJsonAsync<LegalHoldResponse>();
        Assert.NotNull(createdHold);
        Assert.Equal(document.Id, createdHold!.DocumentId);
        Assert.Equal("Investigacion regulatoria activa", createdHold.Reason);
        Assert.True(createdHold.IsActive);
        Assert.Equal(actor.Id, createdHold.CreatedByUserId);

        var releaseResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/records/legal-holds/{createdHold.Id}/release",
            new ReleaseLegalHoldRequest { Reason = " Evidencia consolidada " });

        releaseResponse.EnsureSuccessStatusCode();

        var releasedHold = await releaseResponse.Content.ReadFromJsonAsync<LegalHoldResponse>();
        Assert.NotNull(releasedHold);
        Assert.Equal(createdHold.Id, releasedHold!.Id);
        Assert.False(releasedHold.IsActive);
        Assert.Equal(actor.Id, releasedHold.ReleasedByUserId);
        Assert.Equal("Evidencia consolidada", releasedHold.ReleaseReason);
        Assert.NotNull(releasedHold.ReleasedAtUtc);

        var appliedPolicyId = await GetDocumentRetentionPolicyIdAsync(document.Id);
        var persistedHold = await new PostgresLegalHoldRepository(_factory.DataSource)
            .GetByIdAsync(tenant.Id, createdHold.Id, CancellationToken.None);

        Assert.Equal(expectedPolicyId, appliedPolicyId);
        Assert.NotNull(persistedHold);
        Assert.False(persistedHold!.IsActive);
        Assert.Equal("Evidencia consolidada", persistedHold.ReleaseReason);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<Guid> SeedDispositionCandidateAsync(Guid tenantId, string title)
    {
        var actor = await CreateUserAsync(tenantId, $"records.{Guid.NewGuid():N}@tenant.ar");
        var retentionPolicyId = await GetRetentionPolicyIdAsync("CONTRACT_10Y");
        return await SeedDocumentRowAsync(
            tenantId,
            actor.Id,
            title,
            DateTimeOffset.UtcNow.AddDays(-4000),
            retentionPolicyId);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Records Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-records/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            1024,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
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

    private async Task<Guid?> GetDocumentRetentionPolicyIdAsync(Guid documentId)
    {
        await using var command = _factory.DataSource.CreateCommand(
            """
            SELECT retention_policy_id
            FROM documents.documents
            WHERE document_id = @document_id;
            """);
        command.Parameters.AddWithValue("document_id", documentId);
        var result = await command.ExecuteScalarAsync();
        return result is DBNull or null ? null : (Guid)result;
    }

    private async Task<Guid> SeedDocumentRowAsync(
        Guid tenantId,
        Guid actorUserId,
        string title,
        DateTimeOffset createdAtUtc,
        Guid? retentionPolicyId)
    {
        var documentId = Guid.NewGuid();
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
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("retention_policy_id", (object?)retentionPolicyId ?? DBNull.Value);
        command.Parameters.AddWithValue("title", title);
        command.Parameters.AddWithValue("created_by_user_id", actorUserId);
        command.Parameters.AddWithValue("created_at_utc", createdAtUtc);
        await command.ExecuteNonQueryAsync();
        return documentId;
    }
}
