namespace Gdms.ApiContractTests;

public sealed class DocumentsControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public DocumentsControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetById_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_docs_unauth", "API Docs Unauth");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento sin auth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetById_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_docs_tenant", "API Docs Tenant");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento otro tenant");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetById_Should_Return_403_When_DocumentAcl_Denies_Read()
    {
        var tenant = await CreateTenantAsync("api_docs_acl", "API Docs ACL");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var outsider = await CreateUserAsync(tenant.Id, $"outsider.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento con ACL");
        await GrantReadAccessAsync(tenant.Id, document.Id, reader.Id, owner.Id);
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, outsider.Id.ToString());

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Documents_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_docs_ok", "API Docs OK");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento visible por ACL");
        await GrantReadAccessAsync(tenant.Id, document.Id, reader.Id, owner.Id);

        using var aclClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        aclClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        aclClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, reader.Id.ToString());

        using var adminClient = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN");
        adminClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        adminClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, owner.Id.ToString());

        var getByIdResponse = await aclClient.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}");
        var getAllResponse = await adminClient.GetAsync($"/api/tenants/{tenant.Id}/documents");

        getByIdResponse.EnsureSuccessStatusCode();
        getAllResponse.EnsureSuccessStatusCode();

        var documentPayload = await getByIdResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        var listPayload = await getAllResponse.Content.ReadFromJsonAsync<DocumentResponse[]>();

        Assert.NotNull(documentPayload);
        Assert.Equal(document.Id, documentPayload!.Id);
        Assert.Equal("CONTRACT", documentPayload.DocumentTypeCode);
        Assert.Equal("Documento visible por ACL", documentPayload.Title);
        Assert.Equal("Active", documentPayload.Status);
        Assert.Equal(1, documentPayload.VersionCount);

        Assert.NotNull(listPayload);
        Assert.Contains(listPayload!, item => item.Id == document.Id && item.Title == "Documento visible por ACL");
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_docs_create_role", "API Docs Create Role");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents",
            CreateDocumentRequest("Documento bloqueado por rol"));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_201_And_Persist_New_Document_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_docs_create_ok", "API Docs Create OK");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents",
            CreateDocumentRequest("  Documento creado por contrato  "));

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var createdPayload = await createResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        Assert.NotNull(createdPayload);
        Assert.Equal(tenant.Id, createdPayload!.TenantId);
        Assert.Equal("CONTRACT", createdPayload.DocumentTypeCode);
        Assert.Equal("Documento creado por contrato", createdPayload.Title);
        Assert.Equal("Active", createdPayload.Status);
        Assert.Equal(1, createdPayload.VersionCount);

        var persistedDocument = await new PostgresDocumentRepository(_factory.DataSource)
            .GetByIdAsync(createdPayload.Id, CancellationToken.None);

        Assert.NotNull(persistedDocument);
        Assert.Equal("Documento creado por contrato", persistedDocument!.Title);
        Assert.Single(persistedDocument.Versions);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Docs Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-docs/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            1024,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task GrantReadAccessAsync(Guid tenantId, Guid documentId, Guid userId, Guid grantedByUserId)
    {
        var entry = DocumentAccessEntry.Create(
            tenantId,
            documentId,
            userId,
            DocumentAccessPermission.Read,
            grantedByUserId,
            DateTimeOffset.UtcNow);
        await new PostgresDocumentAccessRepository(_factory.DataSource)
            .GrantAsync(entry, CancellationToken.None);
    }

    private static CreateDocumentRequest CreateDocumentRequest(string title)
    {
        return new CreateDocumentRequest
        {
            DocumentTypeCode = " contract ",
            Title = title,
            StorageObjectKey = $"docs/api-create/{Guid.NewGuid():N}.pdf",
            MimeType = "application/pdf",
            FileHashSha256 = "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            FileSizeBytes = 2048,
            MetadataJson = """{"counterparty":"Acme SA","contractNumber":"CTR-2026-001","effectiveDate":"2026-04-06"}"""
        };
    }
}
