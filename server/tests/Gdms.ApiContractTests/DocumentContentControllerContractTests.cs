using System.Net.Http.Headers;
using System.Text;

namespace Gdms.ApiContractTests;

public sealed class DocumentContentControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public DocumentContentControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Upload_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_doc_bin_unauth", "API Doc Bin Unauth");
        using var client = _factory.CreateClient();
        using var content = BuildUploadContent("Contrato sin auth", PdfBytes("unauth"));

        var response = await client.PostAsync($"/api/tenants/{tenant.Id}/documents/upload", content);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Upload_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_doc_bin_role", "API Doc Bin Role");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());
        using var content = BuildUploadContent("Contrato rol", PdfBytes("role"));

        var response = await client.PostAsync($"/api/tenants/{tenant.Id}/documents/upload", content);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Download_And_UploadVersion_Should_Return_403_When_DocumentAcl_Denies_Binary_Access()
    {
        var tenant = await CreateTenantAsync("api_doc_bin_acl", "API Doc Bin ACL");
        var owner = await CreateUserAsync(tenant.Id, $"owner.{Guid.NewGuid():N}@tenant.ar");
        var reader = await CreateUserAsync(tenant.Id, $"reader.{Guid.NewGuid():N}@tenant.ar");
        var outsider = await CreateUserAsync(tenant.Id, $"outsider.{Guid.NewGuid():N}@tenant.ar");

        using var adminClient = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN");
        adminClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        adminClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, owner.Id.ToString());

        var document = await UploadDocumentAsync(
            adminClient,
            tenant.Id,
            "Contrato ACL binario",
            PdfBytes("acl-v1"));

        await GrantPermissionAsync(tenant.Id, document.Id, reader.Id, owner.Id, DocumentAccessPermission.Download);
        await GrantPermissionAsync(tenant.Id, document.Id, reader.Id, owner.Id, DocumentAccessPermission.UploadVersion);

        using var operatorClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        operatorClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        operatorClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, outsider.Id.ToString());

        var downloadResponse = await operatorClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/download");
        using var versionUploadContent = BuildVersionUploadContent(PdfBytes("acl-v2"));
        var uploadVersionResponse = await operatorClient.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/versions/upload",
            versionUploadContent);

        Assert.Equal(HttpStatusCode.Forbidden, downloadResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, uploadVersionResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Binary_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_doc_bin_ok", "API Doc Bin OK");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var version1Bytes = PdfBytes("version-1");
        var created = await UploadDocumentAsync(client, tenant.Id, " Contrato binario ", version1Bytes);

        using var rangeRequest = new HttpRequestMessage(
            HttpMethod.Get,
            $"/api/tenants/{tenant.Id}/documents/{created.Id}/download");
        rangeRequest.Headers.Range = new RangeHeaderValue(0, 15);
        var rangeResponse = await client.SendAsync(rangeRequest);

        using var uploadVersionContent = BuildVersionUploadContent(PdfBytes("version-2"));
        var versionUploadResponse = await client.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/{created.Id}/versions/upload",
            uploadVersionContent);
        var latestDownloadResponse = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{created.Id}/download");
        var firstVersionResponse = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{created.Id}/versions/1/download");

        Assert.Equal(HttpStatusCode.PartialContent, rangeResponse.StatusCode);
        Assert.Equal(HttpStatusCode.OK, versionUploadResponse.StatusCode);
        latestDownloadResponse.EnsureSuccessStatusCode();
        firstVersionResponse.EnsureSuccessStatusCode();

        var versionedPayload = await versionUploadResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        var rangeBytes = await rangeResponse.Content.ReadAsByteArrayAsync();
        var latestBytes = await latestDownloadResponse.Content.ReadAsByteArrayAsync();
        var firstVersionBytes = await firstVersionResponse.Content.ReadAsByteArrayAsync();

        Assert.NotNull(versionedPayload);
        Assert.Equal(created.Id, versionedPayload!.Id);
        Assert.Equal(2, versionedPayload.VersionCount);
        Assert.Equal("Contrato binario", versionedPayload.Title);

        Assert.Equal("application/pdf", rangeResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("application/pdf", latestDownloadResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("application/pdf", firstVersionResponse.Content.Headers.ContentType?.MediaType);
        Assert.NotNull(rangeResponse.Content.Headers.ContentRange);
        Assert.Equal(0, rangeResponse.Content.Headers.ContentRange!.From);
        Assert.Equal(15, rangeResponse.Content.Headers.ContentRange.To);
        Assert.Equal(version1Bytes.Length, rangeResponse.Content.Headers.ContentRange.Length);
        Assert.Equal(version1Bytes.Take(16), rangeBytes);
        Assert.Equal(PdfBytes("version-2"), latestBytes);
        Assert.Equal(version1Bytes, firstVersionBytes);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Content Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<DocumentResponse> UploadDocumentAsync(
        HttpClient client,
        Guid tenantId,
        string title,
        byte[] pdfBytes)
    {
        using var content = BuildUploadContent(title, pdfBytes);
        var response = await client.PostAsync($"/api/tenants/{tenantId}/documents/upload", content);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<DocumentResponse>())!;
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

    private static MultipartFormDataContent BuildUploadContent(string title, byte[] pdfBytes)
    {
        var content = new MultipartFormDataContent();
        content.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        content.Add(new StringContent(title, Encoding.UTF8), "Title");
        content.Add(
            new StringContent(
                """{"counterparty":"Acme Binary SA","contractNumber":"BIN-001","effectiveDate":"2026-04-08"}""",
                Encoding.UTF8,
                "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(pdfBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        content.Add(fileContent, "File", "scan-binary.pdf");
        return content;
    }

    private static MultipartFormDataContent BuildVersionUploadContent(byte[] pdfBytes)
    {
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(pdfBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        content.Add(fileContent, "File", "scan-binary-v2.pdf");
        return content;
    }

    private static byte[] PdfBytes(string marker)
    {
        return Encoding.UTF8.GetBytes($"%PDF-1.7\n{marker}\n%%EOF");
    }
}
