namespace Gdms.IntegrationTests;

public sealed class PostgresTenantRepositoryIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public PostgresTenantRepositoryIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task AddAsync_And_GetByCodeAsync_Should_Persist_Normalized_Tenant()
    {
        var repository = new PostgresTenantRepository(_fixture.DataSource);
        var tenant = Tenant.Create(" legal_ar ", "Estudio Perez", "LEGAL", "ar", DateTimeOffset.UtcNow);

        var persisted = await repository.AddAsync(tenant, CancellationToken.None);
        var reloaded = await repository.GetByCodeAsync("LEGAL_AR", CancellationToken.None);

        Assert.Equal(tenant.Id, persisted.Id);
        Assert.Equal("LEGAL_AR", persisted.Code);
        Assert.NotNull(reloaded);
        Assert.Equal(persisted.Id, reloaded!.Id);
        Assert.Equal("AR", reloaded.PrimaryCountryCode);
    }

    [PostgresIntegrationFact]
    public async Task ListAsync_Should_Return_Inserted_Tenants_Sorted_By_Name()
    {
        var repository = new PostgresTenantRepository(_fixture.DataSource);

        await repository.AddAsync(Tenant.Create("beta", "Beta Legal", "LEGAL", "AR", DateTimeOffset.UtcNow), CancellationToken.None);
        await repository.AddAsync(Tenant.Create("acme", "Acme Legal", "LEGAL", "AR", DateTimeOffset.UtcNow), CancellationToken.None);

        var tenants = await repository.ListAsync(CancellationToken.None);

        Assert.Contains(tenants, tenant => tenant.Code == "ACME");
        Assert.Contains(tenants, tenant => tenant.Code == "BETA");
        Assert.Equal(
            tenants.OrderBy(tenant => tenant.Name, StringComparer.Ordinal).Select(tenant => tenant.Name),
            tenants.Select(tenant => tenant.Name));
    }
}
