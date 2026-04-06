namespace Gdms.IntegrationTests;

public sealed class AuthServiceIntegrationTests : IClassFixture<PostgresIntegrationDatabaseFixture>
{
    private readonly PostgresIntegrationDatabaseFixture _fixture;

    public AuthServiceIntegrationTests(PostgresIntegrationDatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [PostgresIntegrationFact]
    public async Task BootstrapTenantAdminAsync_Should_Persist_User_And_Audit_Event()
    {
        var tenant = await CreateTenantAsync("auth_bootstrap", "Auth Bootstrap");
        var service = CreateAuthService();

        var session = await service.BootstrapTenantAdminAsync(
            tenant.Code,
            "admin@bootstrap.ar",
            "Bootstrap Admin",
            "SecurePass!123",
            CancellationToken.None);

        var userRepository = new PostgresUserRepository(_fixture.DataSource);
        var users = await userRepository.ListByTenantAsync(tenant.Id, CancellationToken.None);
        var auditRepository = new PostgresAuditEventRepository(_fixture.DataSource);
        var auditEvents = await auditRepository.ListRecentByTenantAsync(tenant.Id, 10, CancellationToken.None);

        Assert.Equal("admin@bootstrap.ar", session.User.Email);
        Assert.Equal("Bearer", session.AccessToken.TokenType);
        Assert.Single(users);
        Assert.Contains(users.Single().Roles, role => role.Code == "TENANT_ADMIN");
        Assert.Contains(auditEvents, entry => entry.EventType == "TENANT_ADMIN_BOOTSTRAPPED");
    }

    [PostgresIntegrationFact]
    public async Task LoginAsync_Should_Return_Session_And_Reset_Failure_Counters()
    {
        var tenant = await CreateTenantAsync("auth_login", "Auth Login");
        var service = CreateAuthService();
        await service.BootstrapTenantAdminAsync(
            tenant.Code,
            "admin@login.ar",
            "Login Admin",
            "SecurePass!123",
            CancellationToken.None);

        var session = await service.LoginAsync(
            tenant.Code,
            "admin@login.ar",
            "SecurePass!123",
            CancellationToken.None);

        var credentialRepository = new PostgresUserCredentialRepository(_fixture.DataSource);
        var snapshot = await credentialRepository.GetByEmailAsync(tenant.Id, "admin@login.ar", CancellationToken.None);
        var auditRepository = new PostgresAuditEventRepository(_fixture.DataSource);
        var auditEvents = await auditRepository.ListRecentByTenantAsync(tenant.Id, 10, CancellationToken.None);

        Assert.Equal("admin@login.ar", session.User.Email);
        Assert.False(session.MustChangePassword);
        Assert.NotEmpty(session.AccessToken.AccessToken);
        Assert.NotNull(snapshot);
        Assert.Equal(0, snapshot!.FailedLoginCount);
        Assert.Null(snapshot.LockedUntilUtc);
        Assert.Contains(auditEvents, entry => entry.EventType == "LOGIN_SUCCEEDED");
    }

    [PostgresIntegrationFact]
    public async Task LoginAsync_Should_Lock_Account_On_Fifth_Failed_Attempt()
    {
        var tenant = await CreateTenantAsync("auth_lock", "Auth Lock");
        var service = CreateAuthService();
        await service.BootstrapTenantAdminAsync(
            tenant.Code,
            "admin@lock.ar",
            "Lock Admin",
            "SecurePass!123",
            CancellationToken.None);

        for (var attempt = 0; attempt < 4; attempt++)
        {
            await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
                service.LoginAsync(tenant.Code, "admin@lock.ar", "bad-pass", CancellationToken.None));
        }

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            service.LoginAsync(tenant.Code, "admin@lock.ar", "bad-pass", CancellationToken.None));

        var credentialRepository = new PostgresUserCredentialRepository(_fixture.DataSource);
        var snapshot = await credentialRepository.GetByEmailAsync(tenant.Id, "admin@lock.ar", CancellationToken.None);
        Assert.NotNull(snapshot);
        Assert.Equal(5, snapshot!.FailedLoginCount);
        Assert.NotNull(snapshot.LockedUntilUtc);

        var blockedException = await Assert.ThrowsAsync<DomainRuleException>(() =>
            service.LoginAsync(tenant.Code, "admin@lock.ar", "SecurePass!123", CancellationToken.None));

        Assert.Contains("bloqueada temporalmente", blockedException.Message);
    }

    private AuthService CreateAuthService()
    {
        var tenantRepository = new PostgresTenantRepository(_fixture.DataSource);
        var userRepository = new PostgresUserRepository(_fixture.DataSource);
        var credentialRepository = new PostgresUserCredentialRepository(_fixture.DataSource);
        var roleRepository = new PostgresRoleRepository(_fixture.DataSource);
        var passwordHashingService = new LocalPasswordHashingService();
        var jwtOptions = Options.Create(new JwtOptions
        {
            Issuer = "gdms-tests",
            Audience = "gdms-tests",
            SigningKey = "integration-test-signing-key-0123456789abcdef",
            AccessTokenMinutes = 60
        });
        var accessTokenIssuer = new JwtAccessTokenIssuer(
            jwtOptions,
            new JwtSigningKeyProvider(jwtOptions, new TestHostEnvironment()));
        var auditEventRepository = new PostgresAuditEventRepository(_fixture.DataSource);

        return new AuthService(
            tenantRepository,
            userRepository,
            credentialRepository,
            roleRepository,
            passwordHashingService,
            accessTokenIssuer,
            auditEventRepository);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        var tenantRepository = new PostgresTenantRepository(_fixture.DataSource);
        return await tenantRepository.AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }
}
