namespace Gdms.E2eSmokeTests;

public sealed class DocumentOperationalSmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public DocumentOperationalSmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Bootstrap_Login_And_Operate_Document_Should_Complete_Core_Tenant_Flow()
    {
        var tenant = await CreateTenantAsync("e2e_ops", "E2E Operaciones");
        using var client = _factory.CreateClient();

        var bootstrapResponse = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-tenant-admin",
            new BootstrapTenantAdminRequest
            {
                TenantCode = tenant.Code,
                Email = "admin.e2e@tenant.ar",
                FullName = "Admin E2E",
                Password = "AdminE2E123!"
            });

        Assert.Equal(HttpStatusCode.Created, bootstrapResponse.StatusCode);

        var bootstrapSession = await bootstrapResponse.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        Assert.NotNull(bootstrapSession);
        Assert.Equal(tenant.Id, bootstrapSession!.TenantId);
        Assert.Contains("TENANT_ADMIN", bootstrapSession.Roles);

        var loginResponse = await client.PostAsJsonAsync(
            "/api/auth/token",
            new LoginRequest
            {
                TenantCode = tenant.Code,
                Email = "admin.e2e@tenant.ar",
                Password = "AdminE2E123!"
            });

        loginResponse.EnsureSuccessStatusCode();

        var loginSession = await loginResponse.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        Assert.NotNull(loginSession);

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            loginSession!.TokenType,
            loginSession.AccessToken);

        var meResponse = await client.GetAsync("/api/auth/me");
        meResponse.EnsureSuccessStatusCode();

        var currentIdentity = await meResponse.Content.ReadFromJsonAsync<CurrentIdentityResponse>();
        Assert.NotNull(currentIdentity);
        Assert.Equal(loginSession.UserId, currentIdentity!.UserId);
        Assert.Equal(tenant.Id, currentIdentity.TenantId);

        using var uploadContent = BuildUploadContent();
        var uploadResponse = await client.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/upload",
            uploadContent);

        Assert.Equal(HttpStatusCode.Created, uploadResponse.StatusCode);

        var document = await uploadResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        Assert.NotNull(document);
        Assert.Equal("CONTRACT", document!.DocumentTypeCode);
        Assert.Equal(1, document.VersionCount);

        var metadataPayload = JsonDocument.Parse("""
            {
              "counterparty": "Acme E2E SA",
              "contractNumber": "E2E-2026-001",
              "effectiveDate": "2026-04-06"
            }
            """);
        var metadataResponse = await client.PutAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/metadata",
            new UpdateDocumentMetadataRequest(metadataPayload.RootElement.Clone()));

        metadataResponse.EnsureSuccessStatusCode();

        var metadata = await metadataResponse.Content.ReadFromJsonAsync<DocumentMetadataResponse>();
        Assert.NotNull(metadata);
        Assert.Equal("Acme E2E SA", metadata!.Metadata.GetProperty("counterparty").GetString());

        var workflowResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/workflow/tasks",
            new CreateWorkflowTaskRequest(
                document.Id,
                "Aprobar contrato E2E",
                "Validar metadata y firma",
                loginSession.UserId,
                DateTimeOffset.UtcNow.AddDays(2)));

        Assert.Equal(HttpStatusCode.Created, workflowResponse.StatusCode);

        var workflowTask = await workflowResponse.Content.ReadFromJsonAsync<WorkflowTaskResponse>();
        Assert.NotNull(workflowTask);
        Assert.Equal("OPEN", workflowTask!.Status);

        var signatureResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/signature/envelopes",
            new CreateSignatureEnvelopeRequest(
                document.Id,
                "Firmante E2E",
                "firmante.e2e@tenant.ar",
                "DIGITAL",
                null,
                DateTimeOffset.UtcNow.AddDays(5)));

        Assert.Equal(HttpStatusCode.Created, signatureResponse.StatusCode);

        var signatureEnvelope = await signatureResponse.Content.ReadFromJsonAsync<SignatureEnvelopeResponse>();
        Assert.NotNull(signatureEnvelope);
        Assert.Equal("PENDING", signatureEnvelope!.Status);

        var reportResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/reports/operational-summary");
        reportResponse.EnsureSuccessStatusCode();

        var report = await reportResponse.Content.ReadFromJsonAsync<OperationalReportResponse>();
        Assert.NotNull(report);
        Assert.True(report!.TotalDocuments >= 1);
        Assert.True(report.OpenWorkflowTasks >= 1);
        Assert.True(report.PendingSignatures >= 1);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private static MultipartFormDataContent BuildUploadContent()
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato operativo E2E"), "Title");
        multipart.Add(
            new StringContent("""
                {"counterparty":"Acme Inicial SA","contractNumber":"E2E-INIT-001","effectiveDate":"2026-04-06"}
                """, Encoding.UTF8, "application/json"),
            "MetadataJson");

        var fileBytes = Encoding.UTF8.GetBytes("Contrato operativo E2E - contenido binario simulado.");
        var fileContent = new ByteArrayContent(fileBytes);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "contrato-e2e.pdf");
        return multipart;
    }
}
