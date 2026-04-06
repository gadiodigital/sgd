namespace Gdms.E2eSmokeTests;

public sealed class DocumentVersionDownloadSmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public DocumentVersionDownloadSmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Upload_New_Version_And_Download_Should_Keep_Binary_Flow_Operational()
    {
        var tenant = await CreateTenantAsync("e2e_binary", "E2E Binary Flow");
        using var client = _factory.CreateClient();

        var bootstrapResponse = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-tenant-admin",
            new BootstrapTenantAdminRequest
            {
                TenantCode = tenant.Code,
                Email = "binary.admin@tenant.ar",
                FullName = "Binary Admin",
                Password = "BinaryAdmin123!"
            });
        bootstrapResponse.EnsureSuccessStatusCode();

        var session = await bootstrapResponse.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        Assert.NotNull(session);

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            session!.TokenType,
            session.AccessToken);

        using var uploadContent = BuildInitialUploadContent();
        var createResponse = await client.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/upload",
            uploadContent);

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var createdDocument = await createResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        Assert.NotNull(createdDocument);
        Assert.Equal(1, createdDocument!.VersionCount);

        using var versionContent = BuildVersionUploadContent();
        var uploadVersionResponse = await client.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/{createdDocument.Id}/versions/upload",
            versionContent);

        uploadVersionResponse.EnsureSuccessStatusCode();

        var updatedDocument = await uploadVersionResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        Assert.NotNull(updatedDocument);
        Assert.Equal(2, updatedDocument!.VersionCount);

        var latestDownloadResponse = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{createdDocument.Id}/download");
        var firstVersionDownloadResponse = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{createdDocument.Id}/versions/1/download");

        latestDownloadResponse.EnsureSuccessStatusCode();
        firstVersionDownloadResponse.EnsureSuccessStatusCode();

        var latestBytes = await latestDownloadResponse.Content.ReadAsByteArrayAsync();
        var firstVersionBytes = await firstVersionDownloadResponse.Content.ReadAsByteArrayAsync();

        Assert.Equal("application/pdf", latestDownloadResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("application/pdf", firstVersionDownloadResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("binary-v2-pdf-content", Encoding.UTF8.GetString(latestBytes));
        Assert.Equal("binary-v1-pdf-content", Encoding.UTF8.GetString(firstVersionBytes));
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private static MultipartFormDataContent BuildInitialUploadContent()
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato binario inicial"), "Title");
        multipart.Add(
            new StringContent("""
                {"counterparty":"Acme Binary SA","contractNumber":"BIN-001","effectiveDate":"2026-04-06"}
                """, Encoding.UTF8, "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes("binary-v1-pdf-content"));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "binary-v1.pdf");
        return multipart;
    }

    private static MultipartFormDataContent BuildVersionUploadContent()
    {
        var multipart = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes("binary-v2-pdf-content"));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "binary-v2.pdf");
        return multipart;
    }
}
