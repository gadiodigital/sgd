namespace Gdms.ApiContractTests;

public sealed class DocumentStructureControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public DocumentStructureControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Structure_Endpoints_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_structure_unauth", "API Structure Unauth");
        using var client = _factory.CreateClient();

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/structure/projects");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects",
            new CreateStructureProjectRequest("ARCH", "Archivo", null));

        Assert.Equal(HttpStatusCode.Unauthorized, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Structure_Endpoints_Should_Create_Hierarchy_And_Attach_Document()
    {
        var tenant = await CreateTenantAsync("api_structure_ok", "API Structure OK");
        var actor = await CreateUserAsync(tenant.Id, $"structure.actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento para estructura");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var projectResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects",
            new CreateStructureProjectRequest(" archivo ", " Archivo central ", "Demo"));
        projectResponse.EnsureSuccessStatusCode();
        var project = await projectResponse.Content.ReadFromJsonAsync<StructureProjectResponse>();
        Assert.NotNull(project);
        Assert.Equal("ARCHIVO", project!.Code);

        var rootTypeResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/container-types",
            new
            {
                Code = " caja ",
                Name = "Caja",
                IconKey = "inventory_2",
                IsRootAllowed = true,
                AcceptsDocuments = false,
                MetadataSchema = new
                {
                    boxNumber = new { type = "string", required = true, label = "Caja", maxLength = 20 }
                }
            });
        rootTypeResponse.EnsureSuccessStatusCode();
        var rootType = await rootTypeResponse.Content.ReadFromJsonAsync<ContainerTypeResponse>();
        Assert.NotNull(rootType);
        Assert.Equal("CAJA", rootType!.Code);

        var folderTypeResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/container-types",
            new
            {
                Code = " carpeta ",
                Name = "Carpeta",
                IconKey = "folder",
                IsRootAllowed = false,
                AcceptsDocuments = true,
                MetadataSchema = new
                {
                    owner = new { type = "string", required = false, label = "Responsable", maxLength = 80 }
                }
            });
        folderTypeResponse.EnsureSuccessStatusCode();
        var folderType = await folderTypeResponse.Content.ReadFromJsonAsync<ContainerTypeResponse>();
        Assert.NotNull(folderType);
        Assert.True(folderType!.AcceptsDocuments);

        var ruleResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/container-type-rules",
            new CreateContainerTypeRuleRequest(rootType.Id, folderType.Id));
        ruleResponse.EnsureSuccessStatusCode();

        var rootContainerResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/containers",
            new
            {
                ContainerTypeId = rootType.Id,
                ParentContainerId = (Guid?)null,
                Code = " caja-001 ",
                Name = "Caja 001",
                Metadata = new { boxNumber = "001" }
            });
        rootContainerResponse.EnsureSuccessStatusCode();
        var rootContainer = await rootContainerResponse.Content.ReadFromJsonAsync<ContainerResponse>();
        Assert.NotNull(rootContainer);
        Assert.Equal("CAJA-001", rootContainer!.Code);

        var folderContainerResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/containers",
            new
            {
                ContainerTypeId = folderType.Id,
                ParentContainerId = rootContainer.Id,
                Code = " carpeta-001 ",
                Name = "Carpeta 001",
                Metadata = new { owner = "Mesa de entradas" }
            });
        folderContainerResponse.EnsureSuccessStatusCode();
        var folderContainer = await folderContainerResponse.Content.ReadFromJsonAsync<ContainerResponse>();
        Assert.NotNull(folderContainer);
        Assert.Equal(rootContainer.Id, folderContainer!.ParentContainerId);

        var treeResponse = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/tree");
        treeResponse.EnsureSuccessStatusCode();
        var tree = await treeResponse.Content.ReadFromJsonAsync<ContainerTreeNodeResponse[]>();
        Assert.NotNull(tree);
        Assert.Single(tree!);
        Assert.Single(tree[0].Children);

        var attachResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/containers/{folderContainer.Id}/documents",
            new AttachDocumentToContainerRequest(document.Id));
        Assert.Equal(HttpStatusCode.NoContent, attachResponse.StatusCode);

        var linkedDocumentsResponse = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/structure/projects/{project.Id}/containers/{folderContainer.Id}/documents");
        linkedDocumentsResponse.EnsureSuccessStatusCode();
        var linkedDocuments = await linkedDocumentsResponse.Content.ReadFromJsonAsync<ContainerDocumentResponse[]>();
        Assert.NotNull(linkedDocuments);
        Assert.Single(linkedDocuments!);
        Assert.Equal(document.Id, linkedDocuments[0].DocumentId);
        Assert.Equal("CONTRACT", linkedDocuments[0].DocumentTypeCode);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "LEGAL", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Structure Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-structure/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);
        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }
}
