using System.Text.Json;

namespace Gdms.ApiContractTests;

public sealed class DocumentMetadataControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public DocumentMetadataControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Get_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_doc_meta_unauth", "API Doc Meta Unauth");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento metadata sin auth");
        await UpsertMetadataAsync(tenant.Id, document.Id, """{"contractNumber":"META-001","signed":false}""");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Metadata_Endpoints_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_doc_meta_forbid", "API Doc Meta Forbid");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento metadata tenant");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, owner.Id.ToString());

        var getResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata");
        var putResponse = await client.PutAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata",
            new { metadata = new { contractNumber = "META-002", effectiveDate = "2026-04-08" } });

        Assert.Equal(HttpStatusCode.Forbidden, getResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, putResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Put_Should_Return_400_When_Metadata_Payload_Is_Not_An_Object()
    {
        var tenant = await CreateTenantAsync("api_doc_meta_badreq", "API Doc Meta BadReq");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento metadata invalida");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PutAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata",
            new { metadata = "texto-plano" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Put_Should_Return_403_When_DocumentAcl_Denies_Metadata_Edit()
    {
        var tenant = await CreateTenantAsync("api_doc_meta_acl", "API Doc Meta ACL");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var outsider = await CreateUserAsync(tenant.Id, $"outsider.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento metadata ACL");
        await UpsertMetadataAsync(tenant.Id, document.Id, """{"contractNumber":"META-003","signed":false}""");
        await GrantPermissionAsync(tenant.Id, document.Id, reader.Id, owner.Id, DocumentAccessPermission.Read);

        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, outsider.Id.ToString());

        var getResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata");
        var putResponse = await client.PutAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata",
            new { metadata = new { contractNumber = "META-004", effectiveDate = "2026-04-08" } });

        Assert.Equal(HttpStatusCode.Forbidden, getResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, putResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Metadata_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_doc_meta_ok", "API Doc Meta OK");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var editor = await CreateUserAsync(tenant.Id, $"editor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, owner.Id, "Documento metadata ok");
        await UpsertMetadataAsync(tenant.Id, document.Id, """{"contractNumber":"META-005","signed":false}""");
        await GrantPermissionAsync(tenant.Id, document.Id, reader.Id, owner.Id, DocumentAccessPermission.Read);
        await GrantPermissionAsync(tenant.Id, document.Id, editor.Id, owner.Id, DocumentAccessPermission.EditMetadata);

        using var readClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        readClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        readClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, reader.Id.ToString());

        using var editClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        editClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        editClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, editor.Id.ToString());

        var getResponse = await readClient.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata");
        var putResponse = await editClient.PutAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata",
            new
            {
                metadata = new
                {
                    contractNumber = " META-006 ",
                    effectiveDate = "2026-04-08",
                    counterparty = " Acme Metadata SA "
                }
            });

        getResponse.EnsureSuccessStatusCode();
        putResponse.EnsureSuccessStatusCode();

        var readPayload = await getResponse.Content.ReadFromJsonAsync<DocumentMetadataResponse>();
        var updatedPayload = await putResponse.Content.ReadFromJsonAsync<DocumentMetadataResponse>();

        Assert.NotNull(readPayload);
        Assert.Equal(document.Id, readPayload!.DocumentId);
        Assert.Equal("META-005", readPayload.Metadata.GetProperty("contractNumber").GetString());
        Assert.False(readPayload.Metadata.GetProperty("signed").GetBoolean());

        Assert.NotNull(updatedPayload);
        Assert.Equal(document.Id, updatedPayload!.DocumentId);
        Assert.Equal("META-006", updatedPayload.Metadata.GetProperty("contractNumber").GetString());
        Assert.Equal("2026-04-08", updatedPayload.Metadata.GetProperty("effectiveDate").GetString());
        Assert.Equal("Acme Metadata SA", updatedPayload.Metadata.GetProperty("counterparty").GetString());

        var persistedMetadata = await new PostgresDocumentMetadataRepository(_factory.DataSource)
            .GetByDocumentIdAsync(tenant.Id, document.Id, CancellationToken.None);
        using var persistedDocument = JsonDocument.Parse(persistedMetadata!);

        Assert.Equal("META-006", persistedDocument.RootElement.GetProperty("contractNumber").GetString());
        Assert.Equal("2026-04-08", persistedDocument.RootElement.GetProperty("effectiveDate").GetString());
        Assert.Equal("Acme Metadata SA", persistedDocument.RootElement.GetProperty("counterparty").GetString());
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Metadata Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-metadata/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            640,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task UpsertMetadataAsync(Guid tenantId, Guid documentId, string metadataJson)
    {
        await new PostgresDocumentMetadataRepository(_factory.DataSource)
            .UpsertAsync(tenantId, documentId, metadataJson, CancellationToken.None);
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
