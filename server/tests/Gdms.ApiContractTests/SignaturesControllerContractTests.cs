namespace Gdms.ApiContractTests;

public sealed class SignaturesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public SignaturesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_sig_unauth", "API Sig Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/signature/envelopes");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_sig_forbid", "API Sig Forbid");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/signature/envelopes");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_sig_role", "API Sig Role");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento firma rol");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/signature/envelopes",
            new CreateSignatureEnvelopeRequest(
                document.Id,
                "Firmante Rol",
                "rol@tenant.ar",
                "ELECTRONIC",
                null,
                null));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Signature_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_sig_ok", "API Sig OK");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var existingDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento listado firmas");
        var createDocument = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento nueva firma");
        var existingEnvelope = await SeedPendingEnvelopeAsync(tenant.Id, existingDocument.Id, actor.Id);

        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        tenantClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        tenantClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        using var platformClient = _factory.CreateClientForPlatformAdmin();
        platformClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        platformClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/signature/envelopes?documentId={existingDocument.Id}");
        var createResponse = await platformClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/signature/envelopes",
            new CreateSignatureEnvelopeRequest(
                createDocument.Id,
                " Firmante Nuevo ",
                "NEW.SIGNER@TENANT.AR",
                "digital",
                null,
                DateTimeOffset.UtcNow.AddDays(2)));

        listResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<SignatureEnvelopeResponse[]>();
        var createdPayload = await createResponse.Content.ReadFromJsonAsync<SignatureEnvelopeResponse>();

        Assert.NotNull(listPayload);
        Assert.Single(listPayload!);
        Assert.Equal(existingEnvelope.Id, listPayload[0].Id);
        Assert.Equal("PENDING", listPayload[0].Status);
        Assert.Equal(existingDocument.Id, listPayload[0].DocumentId);

        Assert.NotNull(createdPayload);
        Assert.Equal(createDocument.Id, createdPayload!.DocumentId);
        Assert.Equal("Firmante Nuevo", createdPayload.SignerDisplayName);
        Assert.Equal("new.signer@tenant.ar", createdPayload.SignerEmail);
        Assert.Equal("DIGITAL", createdPayload.SignatureLevel);
        Assert.Equal("INTERNAL", createdPayload.ProviderCode);
        Assert.Equal("PENDING", createdPayload.Status);
        Assert.Equal(actor.Id, createdPayload.RequestedByUserId);
    }

    [PostgresContractFact]
    public async Task Complete_And_Cancel_Should_Return_Updated_Envelope_Payloads()
    {
        var tenant = await CreateTenantAsync("api_sig_mutate", "API Sig Mutate");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var documentA = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento completar firma");
        var documentB = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento cancelar firma");
        var envelopeToComplete = await SeedPendingEnvelopeAsync(tenant.Id, documentA.Id, actor.Id);
        var envelopeToCancel = await SeedPendingEnvelopeAsync(tenant.Id, documentB.Id, actor.Id);

        using var client = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var completeResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/signature/envelopes/{envelopeToComplete.Id}/complete",
            new CompleteSignatureEnvelopeRequest(" signed-ref-123 "));
        var cancelResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/signature/envelopes/{envelopeToCancel.Id}/cancel",
            new CancelSignatureEnvelopeRequest("Solicitud reemplazada"));

        completeResponse.EnsureSuccessStatusCode();
        cancelResponse.EnsureSuccessStatusCode();

        var completedPayload = await completeResponse.Content.ReadFromJsonAsync<SignatureEnvelopeResponse>();
        var cancelledPayload = await cancelResponse.Content.ReadFromJsonAsync<SignatureEnvelopeResponse>();

        Assert.NotNull(completedPayload);
        Assert.Equal(envelopeToComplete.Id, completedPayload!.Id);
        Assert.Equal("SIGNED", completedPayload.Status);
        Assert.Equal(actor.Id, completedPayload.CompletedByUserId);
        Assert.Equal("signed-ref-123", completedPayload.ExternalReference);
        Assert.NotNull(completedPayload.CompletedAtUtc);

        Assert.NotNull(cancelledPayload);
        Assert.Equal(envelopeToCancel.Id, cancelledPayload!.Id);
        Assert.Equal("CANCELLED", cancelledPayload.Status);
        Assert.Equal(actor.Id, cancelledPayload.CancelledByUserId);
        Assert.Equal("Solicitud reemplazada", cancelledPayload.CancellationReason);
        Assert.NotNull(cancelledPayload.CancelledAtUtc);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var user = User.Create(tenantId, email, "API Signature Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/api-signature/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_factory.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private async Task<SignatureEnvelope> SeedPendingEnvelopeAsync(Guid tenantId, Guid documentId, Guid actorUserId)
    {
        var envelope = SignatureEnvelope.Create(
            tenantId,
            documentId,
            "Firmante Existente",
            "existing@tenant.ar",
            "ELECTRONIC",
            null,
            "existing-ref",
            actorUserId,
            DateTimeOffset.UtcNow,
            null);
        return await new PostgresSignatureEnvelopeRepository(_factory.DataSource)
            .AddAsync(envelope, CancellationToken.None);
    }
}
