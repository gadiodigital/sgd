namespace Gdms.IntegrationTests;

public sealed class SignatureServiceIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public SignatureServiceIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task CreateAsync_Should_Persist_Envelope_And_Audit_Event()
    {
        var tenant = await CreateTenantAsync("sig_create", "Signature Create");
        var actor = await CreateUserAsync(tenant.Id, "signature.creator@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Contrato para firma");
        var service = CreateSignatureService(new FakeSignatureProviderGateway("provider-ref-001"));

        var envelope = await service.CreateAsync(
            tenant.Id,
            document.Id,
            " Firmante Principal ",
            " SIGNER@TENANT.AR ",
            " electronic ",
            null,
            DateTimeOffset.UtcNow.AddDays(3),
            actor.Id,
            CancellationToken.None);

        var reloaded = await new PostgresSignatureEnvelopeRepository(_fixture.DataSource)
            .GetByIdAsync(envelope.Id, CancellationToken.None);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.NotNull(reloaded);
        Assert.Equal("Firmante Principal", reloaded!.SignerDisplayName);
        Assert.Equal("signer@tenant.ar", reloaded.SignerEmail);
        Assert.Equal("ELECTRONIC", reloaded.SignatureLevel);
        Assert.Equal("INTERNAL", reloaded.ProviderCode);
        Assert.Equal("provider-ref-001", reloaded.ExternalReference);
        Assert.Equal(SignatureEnvelopeStatus.Pending, reloaded.Status);
        Assert.Contains(auditEvents, entry => entry.EventType == "SIGNATURE_REQUESTED");
    }

    [PostgresIntegrationFact]
    public async Task CompleteAsync_Should_Mark_Envelope_As_Signed_And_Write_Audit()
    {
        var tenant = await CreateTenantAsync("sig_complete", "Signature Complete");
        var actor = await CreateUserAsync(tenant.Id, "signature.actor@tenant.ar");
        var signer = await CreateUserAsync(tenant.Id, "signature.signer@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento a completar");
        var service = CreateSignatureService(new FakeSignatureProviderGateway("provider-ref-002"));
        var envelope = await service.CreateAsync(
            tenant.Id,
            document.Id,
            "Operador Firmante",
            "signer.external@tenant.ar",
            "DIGITAL",
            "EXTERNAL_PROVIDER",
            null,
            actor.Id,
            CancellationToken.None);

        var completed = await service.CompleteAsync(
            tenant.Id,
            envelope.Id,
            "signed-ref-789",
            signer.Id,
            CancellationToken.None);

        var reloaded = await new PostgresSignatureEnvelopeRepository(_fixture.DataSource)
            .GetByIdAsync(envelope.Id, CancellationToken.None);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.Equal(SignatureEnvelopeStatus.Signed, completed.Status);
        Assert.NotNull(completed.CompletedAtUtc);
        Assert.NotNull(reloaded);
        Assert.Equal(SignatureEnvelopeStatus.Signed, reloaded!.Status);
        Assert.Equal(signer.Id, reloaded.CompletedByUserId);
        Assert.Equal("signed-ref-789", reloaded.ExternalReference);
        Assert.Contains(auditEvents, entry => entry.EventType == "SIGNATURE_COMPLETED");
    }

    [PostgresIntegrationFact]
    public async Task CancelAsync_And_ListByTenantAsync_Should_Persist_Cancelled_Envelope()
    {
        var tenant = await CreateTenantAsync("sig_cancel", "Signature Cancel");
        var actor = await CreateUserAsync(tenant.Id, "signature.cancel@tenant.ar");
        var document = await CreateDocumentAsync(tenant.Id, actor.Id, "Documento cancelable");
        var service = CreateSignatureService(new FakeSignatureProviderGateway("provider-ref-003"));
        var envelope = await service.CreateAsync(
            tenant.Id,
            document.Id,
            "Firmante Alternativo",
            "alternate@tenant.ar",
            "DIGITAL",
            null,
            null,
            actor.Id,
            CancellationToken.None);

        var cancelled = await service.CancelAsync(
            tenant.Id,
            envelope.Id,
            "Solicitud reemplazada por nueva version",
            actor.Id,
            CancellationToken.None);

        var listed = await service.ListByTenantAsync(tenant.Id, document.Id, CancellationToken.None);
        var auditEvents = await new PostgresAuditEventRepository(_fixture.DataSource)
            .ListRecentByDocumentAsync(tenant.Id, document.Id, 10, CancellationToken.None);

        Assert.Equal(SignatureEnvelopeStatus.Cancelled, cancelled.Status);
        Assert.Equal("Solicitud reemplazada por nueva version", cancelled.CancellationReason);
        Assert.Single(listed);
        Assert.Equal(SignatureEnvelopeStatus.Cancelled, listed.Single().Status);
        Assert.Contains(auditEvents, entry => entry.EventType == "SIGNATURE_CANCELLED");
    }

    private SignatureService CreateSignatureService(ISignatureProviderGateway gateway)
    {
        return new SignatureService(
            new PostgresSignatureEnvelopeRepository(_fixture.DataSource),
            gateway,
            new PostgresTenantRepository(_fixture.DataSource),
            new PostgresDocumentRepository(_fixture.DataSource),
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
        var user = User.Create(tenantId, email, "Signature Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_fixture.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task<Document> CreateDocumentAsync(Guid tenantId, Guid uploadedByUserId, string title)
    {
        var document = Document.Create(tenantId, "CONTRACT", title, DateTimeOffset.UtcNow);
        document.AddVersion(
            $"docs/signature/{Guid.NewGuid():N}.pdf",
            "application/pdf",
            "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            768,
            uploadedByUserId,
            DateTimeOffset.UtcNow);

        await new PostgresDocumentRepository(_fixture.DataSource).AddAsync(document, CancellationToken.None);
        return document;
    }

    private sealed class FakeSignatureProviderGateway : ISignatureProviderGateway
    {
        private readonly string _externalReference;

        public FakeSignatureProviderGateway(string externalReference)
        {
            _externalReference = externalReference;
        }

        public Task<PreparedSignatureRequest> PrepareAsync(
            Guid tenantId,
            Guid documentId,
            string signerDisplayName,
            string signerEmail,
            string signatureLevel,
            CancellationToken cancellationToken)
        {
            return Task.FromResult(new PreparedSignatureRequest("INTERNAL", _externalReference));
        }
    }
}
