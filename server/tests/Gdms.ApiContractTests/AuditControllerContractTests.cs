using Gdms.Contracts.Audit;

namespace Gdms.ApiContractTests;

public sealed class AuditControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public AuditControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Audit_Endpoints_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_audit_unauth", "API Audit Unauth");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento audit unauth");
        using var client = _factory.CreateClient();

        var platformResponse = await client.GetAsync("/api/audit/events/recent");
        var tenantResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/audit/events/recent");
        var currentOrganizationResponse = await client.GetAsync("/api/organization/audit/events/recent");
        var documentResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/audit-events");
        var currentOrganizationDocumentResponse = await client.GetAsync($"/api/organization/documents/{document.Id}/audit-events");

        Assert.Equal(HttpStatusCode.Unauthorized, platformResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, tenantResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, currentOrganizationResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, documentResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, currentOrganizationDocumentResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Platform_Recent_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");

        var response = await client.GetAsync("/api/audit/events/recent");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Current_Organization_Audit_Should_Return_401_When_Organization_Claim_Is_Missing()
    {
        using var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add(TestAuthHandler.EnabledHeader, "true");
        client.DefaultRequestHeaders.Add(TestAuthHandler.RolesHeader, "AUDITOR");

        var tenantResponse = await client.GetAsync("/api/organization/audit/events/recent");
        var documentResponse = await client.GetAsync($"/api/organization/documents/{Guid.NewGuid()}/audit-events");

        Assert.Equal(HttpStatusCode.Unauthorized, tenantResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, documentResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Tenant_And_Document_Audit_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_audit_forbid", "API Audit Forbid");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento audit otro tenant");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var tenantResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/audit/events/recent");
        var documentResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/audit-events");

        Assert.Equal(HttpStatusCode.Forbidden, tenantResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, documentResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Document_Audit_Should_Return_400_When_Document_Does_Not_Exist()
    {
        var tenant = await CreateTenantAsync("api_audit_missing", "API Audit Missing");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{Guid.NewGuid()}/audit-events");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Audit_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenantA = await CreateTenantAsync("api_audit_ok_a", "API Audit OK A");
        var tenantB = await CreateTenantAsync("api_audit_ok_b", "API Audit OK B");
        var actorA = await CreateUserAsync(tenantA.Id, $"actor.a.{Guid.NewGuid():N}@tenant.ar");
        var actorB = await CreateUserAsync(tenantB.Id, $"actor.b.{Guid.NewGuid():N}@tenant.ar");
        var documentA = await CreateDocumentAsync(tenantA.Id, actorA.Id, "Documento audit A");
        var documentB = await CreateDocumentAsync(tenantB.Id, actorB.Id, "Documento audit B");
        await SeedAuditEventAsync(tenantA.Id, actorA.Id, documentA.Id, "DOCUMENT_CREATED");
        await SeedAuditEventAsync(tenantA.Id, actorA.Id, documentA.Id, "DOCUMENT_METADATA_UPDATED");
        await SeedAuditEventAsync(tenantB.Id, actorB.Id, documentB.Id, "TENANT_CREATED");

        using var platformClient = _factory.CreateClientForPlatformAdmin();
        using var tenantClient = _factory.CreateClientForTenant(tenantA.Id, "AUDITOR");
        using var documentClient = _factory.CreateClientForTenant(tenantA.Id, "DOCUMENT_OPERATOR");
        tenantClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        tenantClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actorA.Id.ToString());
        documentClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        documentClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actorA.Id.ToString());

        var platformResponse = await platformClient.GetAsync("/api/audit/events/recent?limit=1");
        var tenantResponse = await tenantClient.GetAsync($"/api/tenants/{tenantA.Id}/audit/events/recent?limit=1");
        var currentOrganizationResponse = await tenantClient.GetAsync("/api/organization/audit/events/recent?limit=1");
        var documentResponse = await documentClient.GetAsync($"/api/tenants/{tenantA.Id}/documents/{documentA.Id}/audit-events?limit=0");
        var currentOrganizationDocumentResponse = await documentClient.GetAsync($"/api/organization/documents/{documentA.Id}/audit-events?limit=0");

        platformResponse.EnsureSuccessStatusCode();
        tenantResponse.EnsureSuccessStatusCode();
        currentOrganizationResponse.EnsureSuccessStatusCode();
        documentResponse.EnsureSuccessStatusCode();
        currentOrganizationDocumentResponse.EnsureSuccessStatusCode();

        var platformPayload = await platformResponse.Content.ReadFromJsonAsync<AuditEventResponse[]>();
        var tenantPayload = await tenantResponse.Content.ReadFromJsonAsync<AuditEventResponse[]>();
        var currentOrganizationPayload = await currentOrganizationResponse.Content.ReadFromJsonAsync<AuditEventResponse[]>();
        var documentPayload = await documentResponse.Content.ReadFromJsonAsync<AuditEventResponse[]>();
        var currentOrganizationDocumentPayload =
            await currentOrganizationDocumentResponse.Content.ReadFromJsonAsync<AuditEventResponse[]>();

        Assert.NotNull(platformPayload);
        Assert.Single(platformPayload!);

        Assert.NotNull(tenantPayload);
        Assert.Single(tenantPayload!);
        Assert.Equal(tenantA.Id, tenantPayload[0].TenantId);
        Assert.Equal("DOCUMENT_METADATA_UPDATED", tenantPayload[0].EventType);

        Assert.NotNull(currentOrganizationPayload);
        Assert.Single(currentOrganizationPayload!);
        Assert.Equal(tenantA.Id, currentOrganizationPayload[0].TenantId);
        Assert.Equal("DOCUMENT_METADATA_UPDATED", currentOrganizationPayload[0].EventType);

        Assert.NotNull(documentPayload);
        Assert.Equal(2, documentPayload!.Length);
        Assert.All(documentPayload, item => Assert.Equal(documentA.Id, item.DocumentId));
        Assert.Contains(documentPayload, item => item.EventType == "DOCUMENT_CREATED");
        Assert.Contains(documentPayload, item => item.EventType == "DOCUMENT_METADATA_UPDATED");

        Assert.NotNull(currentOrganizationDocumentPayload);
        Assert.Equal(2, currentOrganizationDocumentPayload!.Length);
        Assert.All(currentOrganizationDocumentPayload, item => Assert.Equal(documentA.Id, item.DocumentId));
        Assert.Contains(currentOrganizationDocumentPayload, item => item.EventType == "DOCUMENT_CREATED");
        Assert.Contains(currentOrganizationDocumentPayload, item => item.EventType == "DOCUMENT_METADATA_UPDATED");
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Audit Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-audit/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);
        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task SeedAuditEventAsync(Guid tenantId, Guid actorUserId, Guid? documentId, string eventType)
    {
        await new PostgresAuditEventRepository(_factory.DataSource)
            .WriteAsync(tenantId, actorUserId, documentId, eventType, "INFO", """{"source":"audit-contract"}""", CancellationToken.None);
    }
}
