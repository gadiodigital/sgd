using Gdms.Contracts.Notifications;

namespace Gdms.ApiContractTests;

public sealed class NotificationsControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public NotificationsControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_notifications_unauth", "API Notifications Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/notifications");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_notifications_forbid", "API Notifications Forbid");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "AUDITOR");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/notifications");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_Aggregated_Notifications_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_notifications_ok", "API Notifications OK");
        var actor = await CreateUserAsync(tenant.Id, $"notify.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento notificaciones");
        await SeedOpenWorkflowTaskAsync(tenant.Id, document.Id, actor.Id);
        await SeedPendingSignatureAsync(tenant.Id, document.Id, actor.Id);
        await SeedDueDispositionDocumentAsync(tenant.Id, actor.Id, "Documento vencido notificaciones");
        await SeedLoginFailedAuditAsync(tenant.Id, actor.Id, DateTimeOffset.UtcNow.AddMinutes(-5));

        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        using var platformClient = _factory.CreateClientForPlatformAdmin();
        tenantClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        tenantClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());
        platformClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        platformClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var tenantResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/notifications");
        var platformResponse = await platformClient.GetAsync($"/api/tenants/{tenant.Id}/notifications");

        tenantResponse.EnsureSuccessStatusCode();
        platformResponse.EnsureSuccessStatusCode();

        var tenantPayload = await tenantResponse.Content.ReadFromJsonAsync<NotificationResponse[]>();
        var platformPayload = await platformResponse.Content.ReadFromJsonAsync<NotificationResponse[]>();

        Assert.NotNull(tenantPayload);
        Assert.NotNull(platformPayload);
        Assert.True(tenantPayload!.Length >= 4);
        Assert.Equal(
            tenantPayload.Select(item => (item.Category, item.Title, item.Severity)).OrderBy(item => item.Category).ThenBy(item => item.Title),
            platformPayload!.Select(item => (item.Category, item.Title, item.Severity)).OrderBy(item => item.Category).ThenBy(item => item.Title));

        Assert.Contains(tenantPayload, item =>
            item.Category == "WORKFLOW" &&
            item.Title == "Revisar contrato urgente" &&
            item.Severity == "WARNING" &&
            item.Detail.Contains("vencimiento", StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Category == "SIGNATURE" &&
            item.Title == "Firma pendiente: Firmante Notificaciones" &&
            item.Severity == "INFO" &&
            item.Detail.Contains("Solicitud DIGITAL pendiente de cierre.", StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Category == "RECORDS" &&
            item.Title == "Disposición pendiente: Documento vencido notificaciones" &&
            item.Severity == "WARNING" &&
            item.Detail.Contains("ARCHIVE", StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Category == "SECURITY" &&
            item.Title == "Intento fallido de inicio de sesión" &&
            item.Severity == "WARNING");

        Assert.True(tenantPayload.Zip(tenantPayload.Skip(1)).All(pair => pair.First.OccurredAtUtc >= pair.Second.OccurredAtUtc));
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Notifications Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-notifications/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task SeedOpenWorkflowTaskAsync(Guid tenantId, Guid documentId, Guid actorUserId)
    {
        var task = WorkflowTask.Create(
            tenantId,
            documentId,
            "Revisar contrato urgente",
            "Notas workflow",
            actorUserId,
            actorUserId,
            DateTimeOffset.UtcNow.AddDays(-2),
            DateTimeOffset.UtcNow.AddHours(-3));

        await new PostgresWorkflowTaskRepository(_factory.DataSource).AddAsync(task, CancellationToken.None);
    }

    private async Task SeedPendingSignatureAsync(Guid tenantId, Guid documentId, Guid actorUserId)
    {
        var envelope = SignatureEnvelope.Create(
            tenantId,
            documentId,
            "Firmante Notificaciones",
            "notify.signer@tenant.ar",
            "DIGITAL",
            null,
            null,
            actorUserId,
            DateTimeOffset.UtcNow.AddMinutes(-20),
            null);

        await new PostgresSignatureEnvelopeRepository(_factory.DataSource).AddAsync(envelope, CancellationToken.None);
    }

    private async Task SeedDueDispositionDocumentAsync(Guid tenantId, Guid actorUserId, string title)
    {
        var retentionPolicyId = await GetRetentionPolicyIdAsync("CONTRACT_10Y");
        await using var command = _factory.DataSource.CreateCommand(
            """
            INSERT INTO documents.documents
                (document_id, tenant_id, document_type_id, retention_policy_id, title, status, confidentiality_level, current_version_number, created_by_user_id, created_at_utc)
            SELECT
                @document_id,
                @tenant_id,
                document_type_id,
                @retention_policy_id,
                @title,
                'ACTIVE',
                1,
                0,
                @created_by_user_id,
                @created_at_utc
            FROM configuration.document_types
            WHERE code = 'CONTRACT'
            ORDER BY tenant_id NULLS FIRST
            LIMIT 1;
            """);
        command.Parameters.AddWithValue("document_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("retention_policy_id", retentionPolicyId);
        command.Parameters.AddWithValue("title", title);
        command.Parameters.AddWithValue("created_by_user_id", actorUserId);
        command.Parameters.AddWithValue("created_at_utc", DateTimeOffset.UtcNow.AddDays(-4000));
        await command.ExecuteNonQueryAsync();
    }

    private async Task<Guid> GetRetentionPolicyIdAsync(string policyCode)
    {
        await using var command = _factory.DataSource.CreateCommand(
            """
            SELECT retention_policy_id
            FROM records.retention_policies
            WHERE code = @code
            LIMIT 1;
            """);
        command.Parameters.AddWithValue("code", policyCode);
        var result = await command.ExecuteScalarAsync();
        return (Guid)result!;
    }

    private async Task SeedLoginFailedAuditAsync(Guid tenantId, Guid actorUserId, DateTimeOffset occurredAtUtc)
    {
        await using var command = _factory.DataSource.CreateCommand(
            """
            INSERT INTO audit.audit_events
                (tenant_id, actor_user_id, document_id, event_type, severity, payload, occurred_at_utc)
            VALUES
                (@tenant_id, @actor_user_id, NULL, 'LOGIN_FAILED', 'WARNING', CAST(@payload AS jsonb), @occurred_at_utc);
            """);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("actor_user_id", actorUserId);
        command.Parameters.AddWithValue("payload", """{"source":"notifications-contract"}""");
        command.Parameters.AddWithValue("occurred_at_utc", occurredAtUtc);
        await command.ExecuteNonQueryAsync();
    }
}
