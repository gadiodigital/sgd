namespace Gdms.E2eSmokeTests;

public sealed class DocumentAclMultiUserSmokeTests : IClassFixture<E2eSmokeTestFactory>
{
    private readonly E2eSmokeTestFactory _factory;

    public DocumentAclMultiUserSmokeTests(E2eSmokeTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresE2eFact]
    public async Task Admin_Granting_Acl_Should_Enable_Read_And_Download_For_Another_User()
    {
        var tenant = await CreateTenantAsync("e2e_acl", "E2E ACL");
        using var adminClient = _factory.CreateClient();

        var adminSession = await BootstrapTenantAdminAsync(adminClient, tenant, "acl.admin@tenant.ar", "AclAdmin123!");
        adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            adminSession.TokenType,
            adminSession.AccessToken);

        var createUserResponse = await adminClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users",
            new CreateUserRequest
            {
                Email = "operator.acl@tenant.ar",
                FullName = "Operator ACL",
                TemporaryPassword = "OperatorAcl123!",
                InitialStatus = "ACTIVE",
                RoleCodes = ["DOCUMENT_OPERATOR"],
                RequirePasswordChange = false
            });

        Assert.Equal(HttpStatusCode.Created, createUserResponse.StatusCode);

        var createdUser = await createUserResponse.Content.ReadFromJsonAsync<UserResponse>();
        Assert.NotNull(createdUser);

        using var uploadContent = BuildUploadContent();
        var createDocumentResponse = await adminClient.PostAsync(
            $"/api/tenants/{tenant.Id}/documents/upload",
            uploadContent);

        Assert.Equal(HttpStatusCode.Created, createDocumentResponse.StatusCode);

        var document = await createDocumentResponse.Content.ReadFromJsonAsync<DocumentResponse>();
        Assert.NotNull(document);

        using var operatorClient = _factory.CreateClient();
        var operatorLogin = await operatorClient.PostAsJsonAsync(
            "/api/auth/token",
            new LoginRequest
            {
                TenantCode = tenant.Code,
                Email = "operator.acl@tenant.ar",
                Password = "OperatorAcl123!"
            });

        operatorLogin.EnsureSuccessStatusCode();

        var operatorSession = await operatorLogin.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        Assert.NotNull(operatorSession);
        operatorClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            operatorSession!.TokenType,
            operatorSession.AccessToken);

        var openGet = await operatorClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document!.Id}");
        var openDownload = await operatorClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/download");

        openGet.EnsureSuccessStatusCode();
        openDownload.EnsureSuccessStatusCode();

        var grantReadResponse = await adminClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries",
            new GrantDocumentAccessRequest(createdUser!.Id, "READ"));

        Assert.Equal(HttpStatusCode.Created, grantReadResponse.StatusCode);

        var allowedGet = await operatorClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}");
        var forbiddenDownload = await operatorClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/download");

        allowedGet.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Forbidden, forbiddenDownload.StatusCode);

        var grantDownloadResponse = await adminClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/access-entries",
            new GrantDocumentAccessRequest(createdUser.Id, "DOWNLOAD"));
        var allowedDownload = await operatorClient.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{document.Id}/download");

        Assert.Equal(HttpStatusCode.Created, grantDownloadResponse.StatusCode);
        allowedDownload.EnsureSuccessStatusCode();

        var documentPayload = await allowedGet.Content.ReadFromJsonAsync<DocumentResponse>();
        var downloadBytes = await allowedDownload.Content.ReadAsByteArrayAsync();

        Assert.NotNull(documentPayload);
        Assert.Equal(document.Id, documentPayload!.Id);
        Assert.Equal("Contrato ACL multiusuario", documentPayload.Title);
        Assert.Equal("application/pdf", allowedDownload.Content.Headers.ContentType?.MediaType);
        Assert.Equal("acl-multiuser-pdf-content", Encoding.UTF8.GetString(downloadBytes));
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
                FullName = "ACL Admin",
                Password = password
            });
        response.EnsureSuccessStatusCode();

        return (await response.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>())!;
    }

    private static MultipartFormDataContent BuildUploadContent()
    {
        var multipart = new MultipartFormDataContent();
        multipart.Add(new StringContent("CONTRACT"), "DocumentTypeCode");
        multipart.Add(new StringContent("Contrato ACL multiusuario"), "Title");
        multipart.Add(
            new StringContent("""
                {"counterparty":"Acme ACL SA","contractNumber":"ACL-001","effectiveDate":"2026-04-06"}
                """, Encoding.UTF8, "application/json"),
            "MetadataJson");

        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes("acl-multiuser-pdf-content"));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        multipart.Add(fileContent, "File", "acl-multiuser.pdf");
        return multipart;
    }
}
