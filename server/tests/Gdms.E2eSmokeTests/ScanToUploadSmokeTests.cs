namespace Gdms.E2eSmokeTests;

public sealed class ScanToUploadSmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public ScanToUploadSmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Rehydrated_WindowsTwain_Session_Should_Export_Pdf_And_Upload_To_Backend()
    {
        var tenant = await CreateTenantAsync("e2e_scan", "E2E Scan Flow");
        using var backendClient = _factory.CreateClient();

        var session = await BootstrapTenantAdminAsync(
            backendClient,
            tenant,
            "scan.admin@tenant.ar",
            "ScanAdmin123!");
        backendClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            session.TokenType,
            session.AccessToken);

        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(scanSessionId);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        var sessionResponse = await scanClient.GetFromJsonAsync<JsonElement>(
            $"{scanHost.BaseUrl}/api/scans/{scanSessionId}");
        Assert.Equal(scanSessionId, sessionResponse.GetProperty("sessionId").GetString());

        var pdfResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{scanSessionId}/pdf");
        pdfResponse.EnsureSuccessStatusCode();
        var pdfBytes = await pdfResponse.Content.ReadAsByteArrayAsync();

        using var uploadContent = BuildUploadContent(pdfBytes);
        var uploadResponse = await backendClient.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/upload",
            uploadContent);

        Assert.Equal(HttpStatusCode.Created, uploadResponse.StatusCode);

        var document = await uploadResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        Assert.NotNull(document);
        Assert.Equal("CONTRACT", document!.DocumentTypeCode);
        Assert.Equal(1, document.VersionCount);

        var downloadResponse = await backendClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/download");
        downloadResponse.EnsureSuccessStatusCode();
        var uploadedBytes = await downloadResponse.Content.ReadAsByteArrayAsync();

        Assert.Equal("application/pdf", downloadResponse.Content.Headers.ContentType?.MediaType);
        Assert.True(pdfBytes.Length > 0);
        Assert.Equal(pdfBytes, uploadedBytes);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private static async Task<AuthenticatedSessionResponse> BootstrapTenantAdminAsync(
        HttpClient client,
        Tenant tenant,
        string email,
        string password)
    {
        var response = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-tenant-admin",
            new BootstrapTenantAdminRequest
            {
                TenantCode = tenant.Code,
                Email = email,
                FullName = "Scan Admin",
                Password = password
            });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>())!;
    }

    private static MultipartFormDataContent BuildUploadContent(byte[] pdfBytes)
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato desde scan host"), "Title");
        multipart.Add(
            new StringContent(
                """{"counterparty":"Acme Scan SA","contractNumber":"SCAN-001","effectiveDate":"2026-04-06"}""",
                Encoding.UTF8,
                "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(pdfBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "scan-session.pdf");
        return multipart;
    }
}
