namespace Gdms.IntegrationTests;

public sealed class PostgresDocumentMetadataRepositoryIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public PostgresDocumentMetadataRepositoryIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task UpsertAsync_Should_Insert_And_Replace_Document_Metadata()
    {
        var tenantRepository = new PostgresTenantRepository(_fixture.DataSource);
        var documentRepository = new PostgresDocumentRepository(_fixture.DataSource);
        var metadataRepository = new PostgresDocumentMetadataRepository(_fixture.DataSource);
        var tenant = await tenantRepository.AddAsync(
            Tenant.Create("meta_ar", "Metadata AR", "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
        var document = Document.Create(tenant.Id, "CONTRACT", "Contrato con Metadata", DateTimeOffset.UtcNow);
        document.AddVersion(
            "docs/contracts/meta.pdf",
            "application/pdf",
            "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            768,
            Guid.Empty,
            DateTimeOffset.UtcNow);

        await documentRepository.AddAsync(document, CancellationToken.None);
        await metadataRepository.UpsertAsync(
            tenant.Id,
            document.Id,
            """{"contractNumber":"CM-001","signed":false}""",
            CancellationToken.None);
        await metadataRepository.UpsertAsync(
            tenant.Id,
            document.Id,
            """{"contractNumber":"CM-002","signed":true}""",
            CancellationToken.None);

        var metadataJson = await metadataRepository.GetByDocumentIdAsync(tenant.Id, document.Id, CancellationToken.None);

        Assert.Equal("""{"signed": true, "contractNumber": "CM-002"}""", metadataJson);
    }
}
