namespace Gdms.ApiContractTests;

public sealed class WorkflowControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public WorkflowControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_wf_unauth", "API Workflow Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/workflow/tasks");
        var currentOrganizationResponse = await client.GetAsync("/api/organization/workflow/tasks");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, currentOrganizationResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Current_Organization_Workflow_Should_Return_401_When_Organization_Claim_Is_Missing()
    {
        using var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add(TestAuthHandler.EnabledHeader, "true");
        client.DefaultRequestHeaders.Add(TestAuthHandler.RolesHeader, "DOCUMENT_OPERATOR");

        var listResponse = await client.GetAsync("/api/organization/workflow/tasks");
        var createResponse = await client.PostAsJsonAsync(
            "/api/organization/workflow/tasks",
            new CreateWorkflowTaskRequest(
                Guid.NewGuid(),
                "Workflow sin organizacion",
                null,
                null,
                null));
        var completeResponse = await client.PostAsync(
            $"/api/organization/workflow/tasks/{Guid.NewGuid()}/complete",
            content: null);

        Assert.Equal(HttpStatusCode.Unauthorized, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, completeResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_wf_forbid", "API Workflow Forbid");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "DOCUMENT_OPERATOR");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/workflow/tasks");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_wf_role", "API Workflow Role");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento workflow sin permiso");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/workflow/tasks",
            new CreateWorkflowTaskRequest(
                document.Id,
                "Revisar workflow",
                null,
                null,
                null));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Workflow_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_wf_ok", "API Workflow OK");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var assignee = await CreateUserAsync(tenant.Id, $"assignee.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento workflow visible");
        var existingTask = await SeedOpenTaskAsync(tenant.Id, document.Id, actor.Id, assignee.Id, "Tarea existente workflow");

        using var listClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        listClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        listClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, assignee.Id.ToString());

        using var createClient = _factory.CreateClientForPlatformAdmin();
        createClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        createClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await listClient.GetAsync($"/api/tenants/{tenant.Id}/workflow/tasks?mine=true");
        var currentOrganizationListResponse = await listClient.GetAsync("/api/organization/workflow/tasks?mine=true");
        var createResponse = await createClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/workflow/tasks",
            new CreateWorkflowTaskRequest(
                document.Id,
                " Revisar aprobacion final ",
                " Validar notas y fecha limite ",
                assignee.Id,
                DateTimeOffset.UtcNow.AddDays(3)));
        var currentOrganizationCreateResponse = await listClient.PostAsJsonAsync(
            "/api/organization/workflow/tasks",
            new CreateWorkflowTaskRequest(
                document.Id,
                " Revisar por organizacion actual ",
                " Validar ruta sin tenant ",
                assignee.Id,
                DateTimeOffset.UtcNow.AddDays(4)));

        listResponse.EnsureSuccessStatusCode();
        currentOrganizationListResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Created, currentOrganizationCreateResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<WorkflowTaskResponse[]>();
        var currentOrganizationListPayload =
            await currentOrganizationListResponse.Content.ReadFromJsonAsync<WorkflowTaskResponse[]>();
        var createdPayload = await createResponse.Content.ReadFromJsonAsync<WorkflowTaskResponse>();
        var currentOrganizationCreatedPayload =
            await currentOrganizationCreateResponse.Content.ReadFromJsonAsync<WorkflowTaskResponse>();

        Assert.NotNull(listPayload);
        Assert.Single(listPayload!);
        Assert.Equal(existingTask.Id, listPayload[0].Id);
        Assert.Equal("OPEN", listPayload[0].Status);
        Assert.Equal(assignee.Id, listPayload[0].AssignedToUserId);

        Assert.NotNull(currentOrganizationListPayload);
        Assert.Single(currentOrganizationListPayload!);
        Assert.Equal(existingTask.Id, currentOrganizationListPayload[0].Id);
        Assert.Equal("OPEN", currentOrganizationListPayload[0].Status);
        Assert.Equal(assignee.Id, currentOrganizationListPayload[0].AssignedToUserId);

        Assert.NotNull(createdPayload);
        Assert.Equal(document.Id, createdPayload!.DocumentId);
        Assert.Equal("Revisar aprobacion final", createdPayload.Title);
        Assert.Equal("Validar notas y fecha limite", createdPayload.Notes);
        Assert.Equal(assignee.Id, createdPayload.AssignedToUserId);
        Assert.Equal("OPEN", createdPayload.Status);
        Assert.Equal(actor.Id, createdPayload.CreatedByUserId);
        Assert.NotNull(createdPayload.DueAtUtc);

        Assert.NotNull(currentOrganizationCreatedPayload);
        Assert.Equal(document.Id, currentOrganizationCreatedPayload!.DocumentId);
        Assert.Equal("Revisar por organizacion actual", currentOrganizationCreatedPayload.Title);
        Assert.Equal("Validar ruta sin tenant", currentOrganizationCreatedPayload.Notes);
        Assert.Equal(assignee.Id, currentOrganizationCreatedPayload.AssignedToUserId);
        Assert.Equal("OPEN", currentOrganizationCreatedPayload.Status);
        Assert.Equal(assignee.Id, currentOrganizationCreatedPayload.CreatedByUserId);
        Assert.NotNull(currentOrganizationCreatedPayload.DueAtUtc);
    }

    [PostgresContractFact]
    public async Task Complete_Should_Return_Updated_Task_Payload()
    {
        var tenant = await CreateTenantAsync("api_wf_complete", "API Workflow Complete");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var assignee = await CreateUserAsync(tenant.Id, $"assignee.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento workflow completar");
        var task = await SeedOpenTaskAsync(tenant.Id, document.Id, actor.Id, assignee.Id, "Completar workflow");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, assignee.Id.ToString());

        var response = await client.PostAsync(
            $"/api/tenants/{tenant.Id}/workflow/tasks/{task.Id}/complete",
            content: null);
        var currentOrganizationTask = await SeedOpenTaskAsync(
            tenant.Id,
            document.Id,
            actor.Id,
            assignee.Id,
            "Completar workflow organizacion actual");
        var currentOrganizationResponse = await client.PostAsync(
            $"/api/organization/workflow/tasks/{currentOrganizationTask.Id}/complete",
            content: null);

        response.EnsureSuccessStatusCode();
        currentOrganizationResponse.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<WorkflowTaskResponse>();
        var currentOrganizationPayload =
            await currentOrganizationResponse.Content.ReadFromJsonAsync<WorkflowTaskResponse>();
        var persistedTask = await new PostgresWorkflowTaskRepository(_factory.DataSource)
            .GetByIdAsync(task.Id, CancellationToken.None);
        var persistedCurrentOrganizationTask = await new PostgresWorkflowTaskRepository(_factory.DataSource)
            .GetByIdAsync(currentOrganizationTask.Id, CancellationToken.None);

        Assert.NotNull(payload);
        Assert.Equal(task.Id, payload!.Id);
        Assert.Equal("COMPLETED", payload.Status);
        Assert.Equal(assignee.Id, payload.CompletedByUserId);
        Assert.NotNull(payload.CompletedAtUtc);

        Assert.NotNull(persistedTask);
        Assert.Equal(WorkflowTaskStatus.Completed, persistedTask!.Status);
        Assert.Equal(assignee.Id, persistedTask.CompletedByUserId);

        Assert.NotNull(currentOrganizationPayload);
        Assert.Equal(currentOrganizationTask.Id, currentOrganizationPayload!.Id);
        Assert.Equal("COMPLETED", currentOrganizationPayload.Status);
        Assert.Equal(assignee.Id, currentOrganizationPayload.CompletedByUserId);
        Assert.NotNull(currentOrganizationPayload.CompletedAtUtc);

        Assert.NotNull(persistedCurrentOrganizationTask);
        Assert.Equal(WorkflowTaskStatus.Completed, persistedCurrentOrganizationTask!.Status);
        Assert.Equal(assignee.Id, persistedCurrentOrganizationTask.CompletedByUserId);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Workflow Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-workflow/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task<WorkflowTask> SeedOpenTaskAsync(
        Guid tenantId,
        Guid documentId,
        Guid createdByUserId,
        Guid assignedToUserId,
        string title)
    {
        var task = WorkflowTask.Create(
            tenantId,
            documentId,
            title,
            "Notas iniciales workflow",
            assignedToUserId,
            createdByUserId,
            DateTimeOffset.UtcNow,
            DateTimeOffset.UtcNow.AddDays(1));

        return await new PostgresWorkflowTaskRepository(_factory.DataSource)
            .AddAsync(task, CancellationToken.None);
    }
}
