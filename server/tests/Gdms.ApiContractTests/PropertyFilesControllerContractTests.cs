namespace Gdms.ApiContractTests;

public sealed class PropertyFilesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public PropertyFilesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task PropertyFiles_Endpoints_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_property_unauth", "API Property Unauth");
        var actor = await CreateUserAsync(tenant.Id, $"property.actor.{Guid.NewGuid():N}@tenant.ar");
        var propertyFile = await CreatePropertyFileAsync(tenant.Id, actor.Id, "PROP-UNAUTH");
        using var client = _factory.CreateClient();

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/property-files");
        var documentsResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/property-files/{propertyFile.Id}/documents");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/property-files",
            new CreatePropertyFileRequest("PROP-NEW", "Legajo Nuevo", "Calle 123", "sale"));

        Assert.Equal(HttpStatusCode.Unauthorized, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, documentsResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task PropertyFiles_Endpoints_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_property_forbid", "API Property Forbid");
        var actor = await CreateUserAsync(tenant.Id, $"property.actor.{Guid.NewGuid():N}@tenant.ar");
        var propertyFile = await CreatePropertyFileAsync(tenant.Id, actor.Id, "PROP-FORBID");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/property-files");
        var documentsResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/property-files/{propertyFile.Id}/documents");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/property-files",
            new CreatePropertyFileRequest("PROP-NEW", "Legajo Nuevo", "Calle 123", "sale"));

        Assert.Equal(HttpStatusCode.Forbidden, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, documentsResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task PropertyFiles_Write_Endpoints_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_property_role", "API Property Role");
        var actor = await CreateUserAsync(tenant.Id, $"property.actor.{Guid.NewGuid():N}@tenant.ar");
        var propertyFile = await CreatePropertyFileAsync(tenant.Id, actor.Id, "PROP-ROLE");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento inmobiliario sin permiso");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/property-files",
            new CreatePropertyFileRequest("PROP-ROLE-NEW", "Legajo Nuevo", "Av. Siempre Viva 742", "rent"));
        var attachResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/property-files/{propertyFile.Id}/documents",
            new AttachDocumentToPropertyFileRequest(document.Id));

        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, attachResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task PropertyFiles_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_property_ok", "API Property OK");
        var actor = await CreateUserAsync(tenant.Id, $"property.actor.{Guid.NewGuid():N}@tenant.ar");
        var linkedBy = await CreateUserAsync(tenant.Id, $"property.link.{Guid.NewGuid():N}@tenant.ar");
        var listedPropertyFile = await CreatePropertyFileAsync(tenant.Id, actor.Id, "prop-listed");
        var listedDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento inmueble listado");
        await AttachDocumentAsync(tenant.Id, listedPropertyFile.Id, listedDocument.Id, linkedBy.Id, DateTimeOffset.UtcNow.AddMinutes(-10));

        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        using var platformClient = _factory.CreateClientForPlatformAdmin();
        tenantClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        tenantClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());
        platformClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        platformClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/property-files");
        var documentsResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/property-files/{listedPropertyFile.Id}/documents");
        var createResponse = await platformClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/property-files",
            new CreatePropertyFileRequest(" prop-new ", " Legajo Nuevo ", " Calle 456 ", " sale "));

        listResponse.EnsureSuccessStatusCode();
        documentsResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<PropertyFileResponse[]>();
        var documentsPayload = await documentsResponse.Content.ReadFromJsonAsync<PropertyFileDocumentResponse[]>();
        var createdPayload = await createResponse.Content.ReadFromJsonAsync<PropertyFileResponse>();

        Assert.NotNull(listPayload);
        Assert.Contains(listPayload!, item => item.Id == listedPropertyFile.Id && item.Code == "PROP-LISTED");

        Assert.NotNull(documentsPayload);
        Assert.Single(documentsPayload!);
        Assert.Equal(listedDocument.Id, documentsPayload[0].DocumentId);
        Assert.Equal("CONTRACT", documentsPayload[0].DocumentTypeCode);
        Assert.Equal(linkedBy.Id, documentsPayload[0].LinkedByUserId);

        Assert.NotNull(createdPayload);
        Assert.Equal(tenant.Id, createdPayload!.TenantId);
        Assert.Equal("PROP-NEW", createdPayload.Code);
        Assert.Equal("Legajo Nuevo", createdPayload.Title);
        Assert.Equal("Calle 456", createdPayload.Address);
        Assert.Equal("SALE", createdPayload.OperationType);
        Assert.Equal("ACTIVE", createdPayload.Status);
        Assert.Equal(actor.Id, createdPayload.CreatedByUserId);

        var attachDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento inmueble attach");
        var attachResponse = await tenantClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/property-files/{createdPayload.Id}/documents",
            new AttachDocumentToPropertyFileRequest(attachDocument.Id));

        Assert.Equal(HttpStatusCode.NoContent, attachResponse.StatusCode);

        var attachedDocumentsResponse = await tenantClient.GetAsync(
            $"/api/tenants/{tenant.Id}/property-files/{createdPayload.Id}/documents");
        attachedDocumentsResponse.EnsureSuccessStatusCode();
        var attachedDocuments = await attachedDocumentsResponse.Content.ReadFromJsonAsync<PropertyFileDocumentResponse[]>();

        Assert.NotNull(attachedDocuments);
        Assert.Contains(attachedDocuments!, item => item.DocumentId == attachDocument.Id && item.LinkedByUserId == actor.Id);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "REAL_ESTATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Property Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<PropertyFile> CreatePropertyFileAsync(Guid tenantId, Guid actorUserId, string code)
    {
        var propertyFile = PropertyFile.Create(
            tenantId,
            code,
            $"Titulo {code}",
            $"Direccion {code}",
            "sale",
            actorUserId,
            DateTimeOffset.UtcNow);
        return await new PostgresPropertyFileRepository(_factory.DataSource).AddAsync(propertyFile, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-property/{Guid.NewGuid():N}.pdf",
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
        Guid propertyFileId,
        Guid documentId,
        Guid linkedByUserId,
        DateTimeOffset linkedAtUtc)
    {
        await new PostgresPropertyFileRepository(_factory.DataSource)
            .AttachDocumentAsync(tenantId, propertyFileId, documentId, linkedByUserId, linkedAtUtc, CancellationToken.None);
    }
}
