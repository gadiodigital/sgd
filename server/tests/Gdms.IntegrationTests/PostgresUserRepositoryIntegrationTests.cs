namespace Gdms.IntegrationTests;

public sealed class PostgresUserRepositoryIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public PostgresUserRepositoryIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task AddAsync_Should_Persist_User_With_Assigned_Role()
    {
        var tenantRepository = new PostgresTenantRepository(_fixture.DataSource);
        var roleRepository = new PostgresRoleRepository(_fixture.DataSource);
        var userRepository = new PostgresUserRepository(_fixture.DataSource);
        var tenant = await tenantRepository.AddAsync(
            Tenant.Create("corp_ar", "Corp AR", "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
        var role = await roleRepository.GetByCodeAsync("TENANT_ADMIN", CancellationToken.None);
        var user = User.Create(tenant.Id, "admin@corp.ar", "Admin Corp", UserStatus.Active, DateTimeOffset.UtcNow);
        user.AssignRole(role!);

        var persisted = await userRepository.AddAsync(user, "hashed-password", false, CancellationToken.None);

        Assert.Equal(user.Id, persisted.Id);
        Assert.Equal("admin@corp.ar", persisted.Email);
        Assert.Single(persisted.Roles);
        Assert.Equal("TENANT_ADMIN", persisted.Roles.Single().Code);
    }

    [PostgresIntegrationFact]
    public async Task AddAsync_Should_Reject_Duplicate_Email_Inside_Same_Tenant()
    {
        var tenantRepository = new PostgresTenantRepository(_fixture.DataSource);
        var userRepository = new PostgresUserRepository(_fixture.DataSource);
        var tenant = await tenantRepository.AddAsync(
            Tenant.Create("dup_ar", "Duplicate AR", "LEGAL", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
        var firstUser = User.Create(tenant.Id, "dup@corp.ar", "First User", UserStatus.Active, DateTimeOffset.UtcNow);
        var secondUser = User.Create(tenant.Id, " DUP@corp.ar ", "Second User", UserStatus.Active, DateTimeOffset.UtcNow);

        await userRepository.AddAsync(firstUser, "hash-1", false, CancellationToken.None);

        var exception = await Assert.ThrowsAsync<DomainRuleException>(() =>
            userRepository.AddAsync(secondUser, "hash-2", false, CancellationToken.None));

        Assert.Contains("mismo correo electrónico", exception.Message);
    }
}
