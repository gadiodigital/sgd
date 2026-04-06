namespace Gdms.IntegrationTests;

public sealed class PostgresDocumentRepositoryIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public PostgresDocumentRepositoryIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task AddAsync_And_GetByIdAsync_Should_Persist_Document_With_First_Version()
    {
        var tenant = await CreateTenantAsync("docs_ar", "Docs AR");
        var user = await CreateUserAsync(tenant.Id, "operator@docs.ar");
        var repository = new PostgresDocumentRepository(_fixture.DataSource);
        var document = Document.Create(tenant.Id, "CONTRACT", "Contrato Marco", DateTimeOffset.UtcNow);
        document.AddVersion(
            "docs/contracts/001.pdf",
            "application/pdf",
            "aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899",
            512,
            user.Id,
            DateTimeOffset.UtcNow);

        await repository.AddAsync(document, CancellationToken.None);
        var reloaded = await repository.GetByIdAsync(document.Id, CancellationToken.None);

        Assert.NotNull(reloaded);
        Assert.Equal(document.Id, reloaded!.Id);
        Assert.Equal("CONTRACT", reloaded.DocumentTypeCode);
        Assert.Equal("Contrato Marco", reloaded.Title);
        Assert.Single(reloaded.Versions);
        Assert.Equal(1, reloaded.Versions.Single().VersionNumber);
        Assert.Equal(user.Id, reloaded.Versions.Single().UploadedByUserId);
    }

    [PostgresIntegrationFact]
    public async Task AddVersionAsync_Should_Persist_Second_Version_And_Update_Current_Version_Number()
    {
        var tenant = await CreateTenantAsync("docs_ver", "Docs Version");
        var user = await CreateUserAsync(tenant.Id, "versioner@docs.ar");
        var repository = new PostgresDocumentRepository(_fixture.DataSource);
        var document = Document.Create(tenant.Id, "CONTRACT", "Contrato con Versiones", DateTimeOffset.UtcNow);
        document.AddVersion(
            "docs/contracts/base.pdf",
            "application/pdf",
            "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff",
            256,
            user.Id,
            DateTimeOffset.UtcNow);

        await repository.AddAsync(document, CancellationToken.None);

        var version2 = document.AddVersion(
            "docs/contracts/v2.pdf",
            "application/pdf",
            "ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100",
            384,
            user.Id,
            DateTimeOffset.UtcNow);

        await repository.AddVersionAsync(document, version2, CancellationToken.None);
        var reloaded = await repository.GetByIdAsync(document.Id, CancellationToken.None);
        var listed = await repository.ListByTenantAsync(tenant.Id, CancellationToken.None);

        Assert.NotNull(reloaded);
        Assert.Equal([1, 2], reloaded!.Versions.Select(version => version.VersionNumber).ToArray());
        Assert.Single(listed);
        Assert.Equal(2, listed.Single().Versions.Count);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        var tenantRepository = new PostgresTenantRepository(_fixture.DataSource);
        return await tenantRepository.AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email)
    {
        var userRepository = new PostgresUserRepository(_fixture.DataSource);
        var user = User.Create(tenantId, email, "Document Operator", UserStatus.Active, DateTimeOffset.UtcNow);
        return await userRepository.AddAsync(user, "hashed-password", false, CancellationToken.None);
    }
}
