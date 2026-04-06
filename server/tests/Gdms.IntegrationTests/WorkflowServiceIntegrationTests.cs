namespace Gdms.IntegrationTests;

public sealed class WorkflowServiceIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public WorkflowServiceIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task CreateAsync_Should_Persist_Task_And_Audit_Event()
    {
        var tenant = await CreateTenantAsync("wf_create", "Workflow Create");
        var actor = await CreateUserAsync(tenant.Id, "creator@wf.ar");
        var assignee = await CreateUserAsync(tenant.Id, "assignee@wf.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato Workflow");
        var service = CreateWorkflowService();

        var task = await service.CreateAsync(
            tenant.Id,
            document.Id,
            " Revisar metadata contractual ",
            " Validar integridad y version actual ",
            assignee.Id,
            DateTimeOffset.UtcNow.AddDays(2),
            actor.Id,
            CancellationToken.None);

        var reloaded = await new PostgresWorkflowTaskRepository(_fixture.DataSource)
            .GetByIdAsync(task.Id, CancellationToken.None);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.NotNull(reloaded);
        Assert.Equal("Revisar metadata contractual", reloaded!.Title);
        Assert.Equal("Validar integridad y version actual", reloaded.Notes);
        Assert.Equal(assignee.Id, reloaded.AssignedToUserId);
        Assert.Equal(WorkflowTaskStatus.Open, reloaded.Status);
        Assert.Contains(auditEvents, entry => entry.EventType == "WORKFLOW_TASK_CREATED");
    }

    [PostgresIntegrationFact]
    public async Task ListByTenantAsync_Should_Filter_By_Assignee_When_Requested()
    {
        var tenant = await CreateTenantAsync("wf_list", "Workflow List");
        var actor = await CreateUserAsync(tenant.Id, "actor@wf.ar");
        var assigneeA = await CreateUserAsync(tenant.Id, "assignee.a@wf.ar");
        var assigneeB = await CreateUserAsync(tenant.Id, "assignee.b@wf.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato para lista");
        var service = CreateWorkflowService();

        await service.CreateAsync(
            tenant.Id,
            document.Id,
            "Tarea A",
            null,
            assigneeA.Id,
            null,
            actor.Id,
            CancellationToken.None);
        await service.CreateAsync(
            tenant.Id,
            document.Id,
            "Tarea B",
            null,
            assigneeB.Id,
            null,
            actor.Id,
            CancellationToken.None);

        var filtered = await service.ListByTenantAsync(tenant.Id, assigneeA.Id, CancellationToken.None);
        var allTasks = await service.ListByTenantAsync(tenant.Id, null, CancellationToken.None);

        Assert.Single(filtered);
        Assert.Equal("Tarea A", filtered.Single().Title);
        Assert.Equal(2, allTasks.Count);
    }

    [PostgresIntegrationFact]
    public async Task CompleteAsync_Should_Mark_Task_As_Completed_And_Write_Audit()
    {
        var tenant = await CreateTenantAsync("wf_complete", "Workflow Complete");
        var actor = await CreateUserAsync(tenant.Id, "actor.complete@wf.ar");
        var assignee = await CreateUserAsync(tenant.Id, "assignee.complete@wf.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato para completar");
        var service = CreateWorkflowService();
        var task = await service.CreateAsync(
            tenant.Id,
            document.Id,
            "Completar validacion",
            null,
            assignee.Id,
            null,
            actor.Id,
            CancellationToken.None);

        var completed = await service.CompleteAsync(tenant.Id, task.Id, assignee.Id, CancellationToken.None);

        var reloaded = await new PostgresWorkflowTaskRepository(_fixture.DataSource)
            .GetByIdAsync(task.Id, CancellationToken.None);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.Equal(WorkflowTaskStatus.Completed, completed.Status);
        Assert.NotNull(completed.CompletedAtUtc);
        Assert.NotNull(reloaded);
        Assert.Equal(WorkflowTaskStatus.Completed, reloaded!.Status);
        Assert.Equal(assignee.Id, reloaded.CompletedByUserId);
        Assert.Contains(auditEvents, entry => entry.EventType == "WORKFLOW_TASK_COMPLETED");
    }

    private WorkflowService CreateWorkflowService()
    {
        return new WorkflowService(
            new PostgresWorkflowTaskRepository(_fixture.DataSource),
            new PostgresTenantRepository(_fixture.DataSource),
            new PostgresDocumentRepository(_fixture.DataSource),
            new PostgresUserRepository(_fixture.DataSource),
            new PostgresAuditEventRepository(_fixture.DataSource));
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_fixture.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "Workflow Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_fixture.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/workflow/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            512,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_fixture.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }
}
