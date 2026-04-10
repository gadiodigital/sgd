namespace Gdms.ApiContractTests;

public sealed class DocumentAccessControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public DocumentAccessControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_doc_acl_unauth", "API Doc ACL Unauth");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento ACL sin auth");
        await GrantPermissionAsync(tenant.Id, document.Id, reader.Id, owner.Id, DocumentAccessPermission.Read);
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Access_Endpoints_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_doc_acl_forbid", "API Doc ACL Forbid");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var targetUser = await CreateUserAsync(tenant.Id, $"target.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento ACL otro tenant");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, owner.Id.ToString());

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries");
        var grantResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries",
            new GrantDocumentAccessRequest(targetUser.Id, "READ"));

        Assert.Equal(HttpStatusCode.Forbidden, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, grantResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Grant_Should_Return_400_When_Permission_Code_Is_Invalid()
    {
        var tenant = await CreateTenantAsync("api_doc_acl_invalid", "API Doc ACL Invalid");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var targetUser = await CreateUserAsync(tenant.Id, $"target.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento ACL invalido");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, owner.Id.ToString());

        var response = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries",
            new GrantDocumentAccessRequest(targetUser.Id, "INVALID_PERMISSION"));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Access_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_doc_acl_ok", "API Doc ACL OK");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var downloader = await CreateUserAsync(tenant.Id, $"downloader.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento ACL ok");
        await GrantPermissionAsync(tenant.Id, document.Id, reader.Id, owner.Id, DocumentAccessPermission.Read);

        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, owner.Id.ToString());

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries");
        var grantResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries",
            new GrantDocumentAccessRequest(downloader.Id, " download "));

        listResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, grantResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<DocumentAccessEntryResponse[]>();
        var grantedPayload = await grantResponse.Content.ReadFromJsonAsync<DocumentAccessEntryResponse>();

        Assert.NotNull(listPayload);
        Assert.Single(listPayload!);
        Assert.Equal(document.Id, listPayload[0].DocumentId);
        Assert.Equal(reader.Id, listPayload[0].UserId);
        Assert.Equal("READ", listPayload[0].PermissionCode);
        Assert.Equal(owner.Id, listPayload[0].GrantedByUserId);

        Assert.NotNull(grantedPayload);
        Assert.Equal(tenant.Id, grantedPayload!.TenantId);
        Assert.Equal(document.Id, grantedPayload.DocumentId);
        Assert.Equal(downloader.Id, grantedPayload.UserId);
        Assert.Equal("DOWNLOAD", grantedPayload.PermissionCode);
        Assert.Equal(owner.Id, grantedPayload.GrantedByUserId);

        var persistedEntries = await new PostgresDocumentAccessRepository(_factory.DataSource)
            .ListByDocumentAsync(tenant.Id, document.Id, CancellationToken.None);

        Assert.Equal(2, persistedEntries.Count);
        Assert.Contains(persistedEntries, entry => entry.UserId == downloader.Id && entry.Permission == DocumentAccessPermission.Download);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Access Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-access/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            512,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task GrantPermissionAsync(
        Guid tenantId,
        Guid documentId,
        Guid userId,
        Guid grantedByUserId,
        DocumentAccessPermission permission)
    {
        var entry = DocumentAccessEntry.Create(
            tenantId,
            documentId,
            userId,
            permission,
            grantedByUserId,
            DateTimeOffset.UtcNow);
        await new PostgresDocumentAccessRepository(_factory.DataSource)
            .GrantAsync(entry, CancellationToken.None);
    }
}
