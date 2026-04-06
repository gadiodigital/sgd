namespace Gdms.E2eSmokeTests;

public sealed class ScanEditableSessionSmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public ScanEditableSessionSmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Editable_Local_Scan_Session_Should_Support_Merge_And_Upload_After_Page_Mutations()
    {
        var tenant = await CreateTenantAsync("e2e_scan_edit", "E2E Scan Edit");
        using var backendClient = _factory.CreateClient();

        var session = await BootstrapTenantAdminAsync(
            backendClient,
            tenant,
            "scan.edit.admin@tenant.ar",
            "ScanEditAdmin123!");
        backendClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            session.TokenType,
            session.AccessToken);

        var primarySessionId = $"scan{Guid.NewGuid():N}"[..24];
        var secondarySessionId = $"scan{Guid.NewGuid():N}"[..24];
        await using var scanHost = new WindowsTwainHostHarness(
            [
                new WindowsTwainHostHarness.SeededSession(primarySessionId, 2),
                new WindowsTwainHostHarness.SeededSession(secondarySessionId, 1)
            ]);
        await scanHost.StartAsync();
        using var scanClient = new HttpClient();

        var previewResponse = await scanClient.GetAsync(
            $"{scanHost.BaseUrl}/api/scans/{primarySessionId}/pages/1/preview");
        previewResponse.EnsureSuccessStatusCode();
        Assert.Equal("image/jpeg", previewResponse.Content.Headers.ContentType?.MediaType);

        var mergeResponse = await scanClient.PostAsJsonAsync(
            $"{scanHost.BaseUrl}/api/scans/{primarySessionId}/merge",
            new
            {
                sourceSessionId = secondarySessionId,
                insertAfterPageNumber = 1
            });
        mergeResponse.EnsureSuccessStatusCode();

        var mergedSession = await mergeResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(3, mergedSession.GetProperty("pageCount").GetInt32());

        var moveResponse = await scanClient.PostAsJsonAsync(
            $"{scanHost.BaseUrl}/api/scans/{primarySessionId}/pages/3/move",
            new
            {
                targetPageNumber = 1
            });
        moveResponse.EnsureSuccessStatusCode();

        var movedSession = await moveResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, movedSession.GetProperty("pages")[0].GetProperty("pageNumber").GetInt32());
        Assert.Equal(3, movedSession.GetProperty("pageCount").GetInt32());

        var deleteResponse = await scanClient.DeleteAsync(
            $"{scanHost.BaseUrl}/api/scans/{primarySessionId}/pages/2");
        deleteResponse.EnsureSuccessStatusCode();

        var editedSession = await deleteResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(2, editedSession.GetProperty("pageCount").GetInt32());
        Assert.Equal(2, editedSession.GetProperty("pages").GetArrayLength());

        var pdfResponse = await scanClient.GetAsync($"{scanHost.BaseUrl}/api/scans/{primarySessionId}/pdf");
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

        var downloadResponse = await backendClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/download");
        downloadResponse.EnsureSuccessStatusCode();
        var storedPdfBytes = await downloadResponse.Content.ReadAsByteArrayAsync();

        Assert.Equal("application/pdf", downloadResponse.Content.Headers.ContentType?.MediaType);
        Assert.True(pdfBytes.Length > 0);
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
                FullName = "Scan Edit Admin",
                Password = password
            });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>())!;
    }

    private static MultipartFormDataContent BuildUploadContent(byte[] pdfBytes)
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato desde sesion editable"), "Title");
        multipart.Add(
            new StringContent(
                """{"counterparty":"Acme Edit SA","contractNumber":"SCAN-EDIT-001","effectiveDate":"2026-04-06"}""",
                Encoding.UTF8,
                "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(pdfBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "scan-editable-session.pdf");
        return multipart;
    }
}
