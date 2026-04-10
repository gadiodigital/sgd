namespace Gdms.E2eSmokeTests;

public sealed class ScanHostRetryRecoverySmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public ScanHostRetryRecoverySmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Rehydrated_Scan_Session_Should_Fail_While_Host_Is_Down_And_Then_Recover_After_Retry()
    {
        var tenant = await CreateTenantAsync("e2e_scan_retry", "E2E Scan Retry Recovery");
        using var backendClient = _factory.CreateClient();

        var authSession = await BootstrapTenantAdminAsync(
            backendClient,
            tenant,
            "scan.retry.admin@tenant.ar",
            "ScanRetryAdmin123!");
        backendClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            authSession.TokenType,
            authSession.AccessToken);

        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(scanSessionId, 2)]);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        var initialSession = await scanClient.GetFromJsonAsync<JsonElement>(
            $"{scanHost.BaseUrl}/api/scans/{scanSessionId}");
        Assert.Equal(scanSessionId, initialSession.GetProperty("sessionId").GetString());
        Assert.Equal(2, initialSession.GetProperty("pageCount").GetInt32());

        await scanHost.StopHostAsync();

        await Assert.ThrowsAnyAsync<HttpRequestException>(
            () => scanClient.GetStringAsync($"{scanHost.BaseUrl}/api/scans/{scanSessionId}"));

        await scanHost.StartAsync();

        var recoveredSession = await scanClient.GetFromJsonAsync<JsonElement>(
            $"{scanHost.BaseUrl}/api/scans/{scanSessionId}");
        Assert.Equal(scanSessionId, recoveredSession.GetProperty("sessionId").GetString());
        Assert.Equal(2, recoveredSession.GetProperty("pageCount").GetInt32());
        Assert.Equal("completed", recoveredSession.GetProperty("status").GetString(), ignoreCase: true);

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

        var downloadResponse = await backendClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document!.Id}/download");
        downloadResponse.EnsureSuccessStatusCode();
        var storedPdfBytes = await downloadResponse.Content.ReadAsByteArrayAsync();

        Assert.Equal("application/pdf", downloadResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal(pdfBytes, storedPdfBytes);
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
                FullName = "Scan Retry Admin",
                Password = password
            });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>())!;
    }

    private static MultipartFormDataContent BuildUploadContent(byte[] pdfBytes)
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato desde retry recovery"), "Title");
        multipart.Add(
            new StringContent(
                """{"counterparty":"Acme Retry SA","contractNumber":"SCAN-RETRY-001","effectiveDate":"2026-04-08"}""",
                Encoding.UTF8,
                "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(pdfBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "scan-retry-recovery.pdf");
        return multipart;
    }
}
