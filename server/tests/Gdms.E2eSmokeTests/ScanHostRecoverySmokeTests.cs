namespace Gdms.E2eSmokeTests;

public sealed class ScanHostRecoverySmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public ScanHostRecoverySmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Rehydrated_Scan_Session_Should_Survive_Host_Restart_And_Still_Upload_To_Backend()
    {
        var tenant = await CreateTenantAsync("e2e_scan_recover", "E2E Scan Recovery");
        using var backendClient = _factory.CreateClient();

        var authSession = await BootstrapTenantAdminAsync(
            backendClient,
            tenant,
            "scan.recovery.admin@tenant.ar",
            "ScanRecovery123!");
        backendClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            authSession.TokenType,
            authSession.AccessToken);

        var scanSessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [new WindowsTwainHostHarness.SeededSession(scanSessionId, 2)]);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        var initialSessions = await scanClient.GetFromJsonAsync<JsonElement>($"{scanHost.BaseUrl}/api/sessions");
        var initialSummary = FindSessionSummary(initialSessions, scanSessionId);
        Assert.True(initialSummary.GetProperty("isRehydrated").GetBoolean());
        Assert.Equal(2, initialSummary.GetProperty("pageCount").GetInt32());

        var deleteResponse = await scanClient.DeleteAsync(
            $"{scanHost.BaseUrl}/api/scans/{scanSessionId}/pages/2");
        deleteResponse.EnsureSuccessStatusCode();

        var editedSession = await deleteResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, editedSession.GetProperty("pageCount").GetInt32());

        await scanHost.RestartAsync();

        var recoveredSessions = await scanClient.GetFromJsonAsync<JsonElement>($"{scanHost.BaseUrl}/api/sessions");
        var recoveredSummary = FindSessionSummary(recoveredSessions, scanSessionId);
        Assert.True(recoveredSummary.GetProperty("isRehydrated").GetBoolean());
        Assert.Equal(1, recoveredSummary.GetProperty("pageCount").GetInt32());

        var recoveredSession = await scanClient.GetFromJsonAsync<JsonElement>(
            $"{scanHost.BaseUrl}/api/scans/{scanSessionId}");
        Assert.Equal(scanSessionId, recoveredSession.GetProperty("sessionId").GetString());
        Assert.Equal(1, recoveredSession.GetProperty("pageCount").GetInt32());
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
                FullName = "Scan Recovery Admin",
                Password = password
            });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>())!;
    }

    private static MultipartFormDataContent BuildUploadContent(byte[] pdfBytes)
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato desde recovery host"), "Title");
        multipart.Add(
            new StringContent(
                """{"counterparty":"Acme Recovery SA","contractNumber":"SCAN-RECOVERY-001","effectiveDate":"2026-04-06"}""",
                Encoding.UTF8,
                "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(pdfBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "scan-recovery-session.pdf");
        return multipart;
    }

    private static JsonElement FindSessionSummary(JsonElement sessions, string sessionId)
    {
        foreach (var session in sessions.EnumerateArray())
        {
            if (string.Equals(session.GetProperty("sessionId").GetString(), sessionId, StringComparison.Ordinal))
            {
                return session;
            }
        }

        throw new Xunit.Sdk.XunitException($"No se encontro la sesion {sessionId} en /api/sessions.");
    }
}
