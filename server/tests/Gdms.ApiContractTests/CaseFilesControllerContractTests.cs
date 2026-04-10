namespace Gdms.ApiContractTests;

public sealed class CaseFilesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public CaseFilesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task CaseFiles_Endpoints_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_cases_unauth", "API Cases Unauth");
        var actor = await CreateUserAsync(tenant.Id, $"cases.actor.{Guid.NewGuid():N}@tenant.ar");
        var caseFile = await CreateCaseFileAsync(tenant.Id, actor.Id, "EXP-UNAUTH");
        using var client = _factory.CreateClient();

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/cases");
        var documentsResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/cases/{caseFile.Id}/documents");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/cases",
            new CreateCaseFileRequest("EXP-NEW", "Expediente Nuevo", "legal"));

        Assert.Equal(HttpStatusCode.Unauthorized, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, documentsResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task CaseFiles_Endpoints_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_cases_forbid", "API Cases Forbid");
        var actor = await CreateUserAsync(tenant.Id, $"cases.actor.{Guid.NewGuid():N}@tenant.ar");
        var caseFile = await CreateCaseFileAsync(tenant.Id, actor.Id, "EXP-FORBID");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/cases");
        var documentsResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/cases/{caseFile.Id}/documents");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/cases",
            new CreateCaseFileRequest("EXP-NEW", "Expediente Nuevo", "legal"));

        Assert.Equal(HttpStatusCode.Forbidden, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, documentsResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task CaseFiles_Write_Endpoints_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_cases_role", "API Cases Role");
        var actor = await CreateUserAsync(tenant.Id, $"cases.actor.{Guid.NewGuid():N}@tenant.ar");
        var caseFile = await CreateCaseFileAsync(tenant.Id, actor.Id, "EXP-ROLE");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento expediente sin permiso");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/cases",
            new CreateCaseFileRequest("EXP-ROLE-NEW", "Expediente Nuevo", "legal"));
        var attachResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/cases/{caseFile.Id}/documents",
            new AttachDocumentToCaseFileRequest(document.Id));

        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, attachResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task CaseFiles_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_cases_ok", "API Cases OK");
        var actor = await CreateUserAsync(tenant.Id, $"cases.actor.{Guid.NewGuid():N}@tenant.ar");
        var linkedBy = await CreateUserAsync(tenant.Id, $"cases.link.{Guid.NewGuid():N}@tenant.ar");
        var listedCaseFile = await CreateCaseFileAsync(tenant.Id, actor.Id, "exp-listed");
        var listedDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento expediente listado");
        await AttachDocumentAsync(tenant.Id, listedCaseFile.Id, listedDocument.Id, linkedBy.Id, DateTimeOffset.UtcNow.AddMinutes(-10));

        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        using var platformClient = _factory.CreateClientForPlatformAdmin();
        tenantClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        tenantClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());
        platformClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        platformClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/cases");
        var documentsResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/cases/{listedCaseFile.Id}/documents");
        var createResponse = await platformClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/cases",
            new CreateCaseFileRequest(" exp-new ", " Expediente Nuevo ", " legal "));

        listResponse.EnsureSuccessStatusCode();
        documentsResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<CaseFileResponse[]>();
        var documentsPayload = await documentsResponse.Content.ReadFromJsonAsync<CaseFileDocumentResponse[]>();
        var createdPayload = await createResponse.Content.ReadFromJsonAsync<CaseFileResponse>();

        Assert.NotNull(listPayload);
        Assert.Contains(listPayload!, item => item.Id == listedCaseFile.Id && item.Code == "EXP-LISTED");

        Assert.NotNull(documentsPayload);
        Assert.Single(documentsPayload!);
        Assert.Equal(listedDocument.Id, documentsPayload[0].DocumentId);
        Assert.Equal("CONTRACT", documentsPayload[0].DocumentTypeCode);
        Assert.Equal(linkedBy.Id, documentsPayload[0].LinkedByUserId);

        Assert.NotNull(createdPayload);
        Assert.Equal(tenant.Id, createdPayload!.TenantId);
        Assert.Equal("EXP-NEW", createdPayload.Code);
        Assert.Equal("Expediente Nuevo", createdPayload.Title);
        Assert.Equal("LEGAL", createdPayload.Category);
        Assert.Equal("OPEN", createdPayload.Status);
        Assert.Equal(actor.Id, createdPayload.CreatedByUserId);

        var attachDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento expediente attach");
        var attachResponse = await tenantClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/cases/{createdPayload.Id}/documents",
            new AttachDocumentToCaseFileRequest(attachDocument.Id));

        Assert.Equal(HttpStatusCode.NoContent, attachResponse.StatusCode);

        var attachedDocumentsResponse = await tenantClient.GetAsync(
            $"/api/tenants/{tenant.Id}/cases/{createdPayload.Id}/documents");
        attachedDocumentsResponse.EnsureSuccessStatusCode();
        var attachedDocuments = await attachedDocumentsResponse.Content.ReadFromJsonAsync<CaseFileDocumentResponse[]>();

        Assert.NotNull(attachedDocuments);
        Assert.Contains(attachedDocuments!, item => item.DocumentId == attachDocument.Id && item.LinkedByUserId == actor.Id);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "LEGAL", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Cases Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<CaseFile> CreateCaseFileAsync(Guid tenantId, Guid actorUserId, string code)
    {
        var caseFile = CaseFile.Create(tenantId, code, $"Titulo {code}", "legal", actorUserId, DateTimeOffset.UtcNow);
        return await new PostgresCaseFileRepository(_factory.DataSource).AddAsync(caseFile, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-cases/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);
        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task AttachDocumentAsync(Guid tenantId, Guid caseFileId, Guid documentId, Guid linkedByUserId, DateTimeOffset linkedAtUtc)
    {
        await new PostgresCaseFileRepository(_factory.DataSource)
            .AttachDocumentAsync(tenantId, caseFileId, documentId, linkedByUserId, linkedAtUtc, CancellationToken.None);
    }
}
