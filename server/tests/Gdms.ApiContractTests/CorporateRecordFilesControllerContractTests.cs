namespace Gdms.ApiContractTests;

public sealed class CorporateRecordFilesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public CorporateRecordFilesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task CorporateRecordFiles_Endpoints_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_corporate_unauth", "API Corporate Unauth");
        var actor = await CreateUserAsync(tenant.Id, $"corporate.actor.{Guid.NewGuid():N}@tenant.ar");
        var corporateFile = await CreateCorporateRecordFileAsync(tenant.Id, actor.Id, "CORP-UNAUTH");
        using var client = _factory.CreateClient();

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/corporate-record-files");
        var documentsResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/corporate-record-files/{corporateFile.Id}/documents");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files",
            new CreateCorporateRecordFileRequest("CORP-NEW", "Legajo Nuevo", "board", "legal"));

        Assert.Equal(HttpStatusCode.Unauthorized, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, documentsResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task CorporateRecordFiles_Endpoints_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_corporate_forbid", "API Corporate Forbid");
        var actor = await CreateUserAsync(tenant.Id, $"corporate.actor.{Guid.NewGuid():N}@tenant.ar");
        var corporateFile = await CreateCorporateRecordFileAsync(tenant.Id, actor.Id, "CORP-FORBID");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/corporate-record-files");
        var documentsResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/corporate-record-files/{corporateFile.Id}/documents");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files",
            new CreateCorporateRecordFileRequest("CORP-NEW", "Legajo Nuevo", "board", "legal"));

        Assert.Equal(HttpStatusCode.Forbidden, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, documentsResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task CorporateRecordFiles_Write_Endpoints_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_corporate_role", "API Corporate Role");
        var actor = await CreateUserAsync(tenant.Id, $"corporate.actor.{Guid.NewGuid():N}@tenant.ar");
        var corporateFile = await CreateCorporateRecordFileAsync(tenant.Id, actor.Id, "CORP-ROLE");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento corporativo sin permiso");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files",
            new CreateCorporateRecordFileRequest("CORP-ROLE-NEW", "Legajo Nuevo", "board", "legal"));
        var attachResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files/{corporateFile.Id}/documents",
            new AttachDocumentToCorporateRecordFileRequest(document.Id));

        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, attachResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task CorporateRecordFiles_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_corporate_ok", "API Corporate OK");
        var actor = await CreateUserAsync(tenant.Id, $"corporate.actor.{Guid.NewGuid():N}@tenant.ar");
        var linkedBy = await CreateUserAsync(tenant.Id, $"corporate.link.{Guid.NewGuid():N}@tenant.ar");
        var listedCorporateFile = await CreateCorporateRecordFileAsync(tenant.Id, actor.Id, "corp-listed");
        var listedDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento corporativo listado");
        await AttachDocumentAsync(tenant.Id, listedCorporateFile.Id, listedDocument.Id, linkedBy.Id, DateTimeOffset.UtcNow.AddMinutes(-10));

        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        using var platformClient = _factory.CreateClientForPlatformAdmin();
        tenantClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        tenantClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());
        platformClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        platformClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/corporate-record-files");
        var documentsResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/corporate-record-files/{listedCorporateFile.Id}/documents");
        var createResponse = await platformClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files",
            new CreateCorporateRecordFileRequest(" corp-new ", " Legajo Nuevo ", " board ", " legal "));

        listResponse.EnsureSuccessStatusCode();
        documentsResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<CorporateRecordFileResponse[]>();
        var documentsPayload = await documentsResponse.Content.ReadFromJsonAsync<CorporateRecordFileDocumentResponse[]>();
        var createdPayload = await createResponse.Content.ReadFromJsonAsync<CorporateRecordFileResponse>();

        Assert.NotNull(listPayload);
        Assert.Contains(listPayload!, item => item.Id == listedCorporateFile.Id && item.Code == "CORP-LISTED");

        Assert.NotNull(documentsPayload);
        Assert.Single(documentsPayload!);
        Assert.Equal(listedDocument.Id, documentsPayload[0].DocumentId);
        Assert.Equal("CONTRACT", documentsPayload[0].DocumentTypeCode);
        Assert.Equal(linkedBy.Id, documentsPayload[0].LinkedByUserId);

        Assert.NotNull(createdPayload);
        Assert.Equal(tenant.Id, createdPayload!.TenantId);
        Assert.Equal("CORP-NEW", createdPayload.Code);
        Assert.Equal("Legajo Nuevo", createdPayload.Title);
        Assert.Equal("BOARD", createdPayload.Category);
        Assert.Equal("LEGAL", createdPayload.OwnerArea);
        Assert.Equal("ACTIVE", createdPayload.Status);
        Assert.Equal(actor.Id, createdPayload.CreatedByUserId);

        var attachDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento corporativo attach");
        var attachResponse = await tenantClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files/{createdPayload.Id}/documents",
            new AttachDocumentToCorporateRecordFileRequest(attachDocument.Id));

        Assert.Equal(HttpStatusCode.NoContent, attachResponse.StatusCode);

        var attachedDocumentsResponse = await tenantClient.GetAsync(
            $"/api/tenants/{tenant.Id}/corporate-record-files/{createdPayload.Id}/documents");
        attachedDocumentsResponse.EnsureSuccessStatusCode();
        var attachedDocuments = await attachedDocumentsResponse.Content.ReadFromJsonAsync<CorporateRecordFileDocumentResponse[]>();

        Assert.NotNull(attachedDocuments);
        Assert.Contains(attachedDocuments!, item => item.DocumentId == attachDocument.Id && item.LinkedByUserId == actor.Id);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Corporate Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<CorporateRecordFile> CreateCorporateRecordFileAsync(Guid tenantId, Guid actorUserId, string code)
    {
        var corporateFile = CorporateRecordFile.Create(
            tenantId,
            code,
            $"Titulo {code}",
            "board",
            "legal",
            actorUserId,
            DateTimeOffset.UtcNow);
        return await new PostgresCorporateRecordFileRepository(_factory.DataSource).AddAsync(corporateFile, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-corporate/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);
        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task AttachDocumentAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        Guid documentId,
        Guid linkedByUserId,
        DateTimeOffset linkedAtUtc)
    {
        await new PostgresCorporateRecordFileRepository(_factory.DataSource)
            .AttachDocumentAsync(tenantId, corporateRecordFileId, documentId, linkedByUserId, linkedAtUtc, CancellationToken.None);
    }
}
