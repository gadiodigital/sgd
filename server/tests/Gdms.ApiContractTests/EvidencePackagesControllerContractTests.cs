using System.Text.Json;

namespace Gdms.ApiContractTests;

public sealed class EvidencePackagesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public EvidencePackagesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Download_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_evidence_unauth", "API Evidence Unauth");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento evidencia sin auth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/evidence-package");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Download_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_evidence_forbid", "API Evidence Forbid");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento evidencia tenant");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/evidence-package");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Download_Should_Return_400_When_Document_Does_Not_Exist_In_Tenant()
    {
        var tenant = await CreateTenantAsync("api_evidence_missing", "API Evidence Missing");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.GetAsync(
            $"/api/tenants/{tenant.Id}/documents/{Guid.NewGuid()}/evidence-package");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Download_Should_Return_Json_Evidence_Package_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_evidence_ok", "API Evidence OK");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento evidencia completo");
        await UpsertMetadataAsync(
            tenant.Id,
            document.Id,
            """{"contractNumber":"EV-001","counterparty":"Acme Evidence SA","effectiveDate":"2026-04-08"}""");
        await SeedAuditEventAsync(tenant.Id, actor.Id, document.Id, "DOCUMENT_REVIEWED");
        await SeedWorkflowTaskAsync(tenant.Id, document.Id, actor.Id);
        await SeedSignatureAsync(tenant.Id, document.Id, actor.Id);
        await SeedLegalHoldAsync(tenant.Id, document.Id, actor.Id);

        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/documents/{document.Id}/evidence-package");

        response.EnsureSuccessStatusCode();
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);
        Assert.Equal(
            $"evidence-package-{document.Id:N}.json",
            response.Content.Headers.ContentDisposition?.FileName?.Trim('"'));

        using var payload = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = payload.RootElement;

        Assert.Equal(document.Id, root.GetProperty("DocumentId").GetGuid());
        Assert.Equal(tenant.Id, root.GetProperty("TenantId").GetGuid());
        Assert.Equal("CONTRACT", root.GetProperty("DocumentTypeCode").GetString());
        Assert.Equal("Documento evidencia completo", root.GetProperty("Title").GetString());
        Assert.Equal("ACTIVE", root.GetProperty("Status").GetString());
        Assert.Equal("EV-001", root.GetProperty("Metadata").GetProperty("contractNumber").GetString());
        Assert.Equal("Acme Evidence SA", root.GetProperty("Metadata").GetProperty("counterparty").GetString());
        Assert.Single(root.GetProperty("Versions").EnumerateArray());
        Assert.Contains(
            root.GetProperty("AuditEvents").EnumerateArray(),
            item => item.GetProperty("EventType").GetString() == "DOCUMENT_REVIEWED");
        Assert.Single(root.GetProperty("WorkflowTasks").EnumerateArray());
        Assert.Single(root.GetProperty("Signatures").EnumerateArray());
        Assert.Single(root.GetProperty("LegalHolds").EnumerateArray());

        var persistedAuditEvents = await new PostgresAuditEventRepository(_factory.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.Contains(persistedAuditEvents, item => item.EventType == "EVIDENCE_PACKAGE_EXPORTED");
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Evidence Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-evidence/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            704,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task UpsertMetadataAsync(Guid tenantId, Guid documentId, string metadataJson)
    {
        await new PostgresDocumentMetadataRepository(_factory.DataSource)
            .UpsertAsync(tenantId, documentId, metadataJson, CancellationToken.None);
    }

    private async Task SeedAuditEventAsync(Guid tenantId, Guid actorUserId, Guid documentId, string eventType)
    {
        await new PostgresAuditEventRepository(_factory.DataSource)
            .WriteAsync(tenantId, actorUserId, documentId, eventType, "INFO", """{"source":"contract-test"}""", CancellationToken.None);
    }

    private async Task SeedWorkflowTaskAsync(Guid tenantId, Guid documentId, Guid actorUserId)
    {
        var task = WorkflowTask.Create(
            tenantId,
            documentId,
            "Revisar evidencia",
            "Validar exportación",
            actorUserId,
            actorUserId,
            DateTimeOffset.UtcNow,
            DateTimeOffset.UtcNow.AddDays(2));
        await new PostgresWorkflowTaskRepository(_factory.DataSource).AddAsync(task, CancellationToken.None);
    }

    private async Task SeedSignatureAsync(Guid tenantId, Guid documentId, Guid actorUserId)
    {
        var envelope = SignatureEnvelope.Create(
            tenantId,
            documentId,
            "Firmante Evidencia",
            "evidence.signer@tenant.ar",
            "DIGITAL",
            null,
            "evidence-ref",
            actorUserId,
            DateTimeOffset.UtcNow,
            DateTimeOffset.UtcNow.AddDays(3));
        await new PostgresSignatureEnvelopeRepository(_factory.DataSource)
            .AddAsync(envelope, CancellationToken.None);
    }

    private async Task SeedLegalHoldAsync(Guid tenantId, Guid documentId, Guid actorUserId)
    {
        var hold = LegalHold.Create(
            tenantId,
            documentId,
            "Conservar por revisión de evidencia",
            actorUserId,
            DateTimeOffset.UtcNow);
        await new PostgresLegalHoldRepository(_factory.DataSource).AddAsync(hold, CancellationToken.None);
    }
}
