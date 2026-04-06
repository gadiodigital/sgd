using Gdms.UnitTests.TestDoubles;

namespace Gdms.UnitTests;

public sealed class AuthServiceTests
{
    [Fact]
    public async Task BootstrapTenantAdminAsync_Should_Create_User_Issue_Token_And_Audit()
    {
        var tenant = new Tenant(Guid.NewGuid(), "ACME", "Acme Corp", "LEGAL", "AR", DateTimeOffset.UtcNow);
        var role = new Role(Guid.NewGuid(), "TENANT_ADMIN", "Tenant Admin", "Administra el tenant.");
        var tenantRepository = new TenantRepositoryStub { TenantByCode = tenant };
        var userRepository = new UserRepositoryStub();
        var credentialRepository = new UserCredentialRepositoryStub();
        var roleRepository = new RoleRepositoryStub { RoleByCode = role };
        var passwordHashingService = new PasswordHashingServiceStub { HashResult = "hash::secure" };
        var accessTokenIssuer = new AccessTokenIssuerStub();
        var auditEventRepository = new AuditEventRepositoryStub();
        var service = new AuthService(
            tenantRepository,
            userRepository,
            credentialRepository,
            roleRepository,
            passwordHashingService,
            accessTokenIssuer,
            auditEventRepository);

        var session = await service.BootstrapTenantAdminAsync(
            " acme ",
            "  admin@acme.com ",
            "Admin Acme",
            "SecurePass!123",
            CancellationToken.None);

        Assert.Equal(tenant.Id, session.Tenant.Id);
        Assert.Equal("admin@acme.com", session.User.Email);
        Assert.Single(session.User.Roles);
        Assert.Equal("TENANT_ADMIN", session.User.Roles.Single().Code);
        Assert.Equal("hash::secure", userRepository.AddedPasswordHash);
        Assert.False(userRepository.AddedMustChangePassword);
        Assert.Equal("TENANT_ADMIN_BOOTSTRAPPED", auditEventRepository.Writes.Single().EventType);
        Assert.Same(session.User, accessTokenIssuer.IssuedUser);
    }

    [Fact]
    public async Task LoginAsync_Should_Record_Failed_Login_And_Apply_Lockout_On_Fifth_Attempt()
    {
        var tenant = new Tenant(Guid.NewGuid(), "ACME", "Acme Corp", "LEGAL", "AR", DateTimeOffset.UtcNow);
        var user = User.Create(tenant.Id, "user@acme.com", "User Acme", UserStatus.Active, DateTimeOffset.UtcNow);
        var tenantRepository = new TenantRepositoryStub { TenantByCode = tenant };
        var userRepository = new UserRepositoryStub();
        var credentialRepository = new UserCredentialRepositoryStub
        {
            Snapshot = new UserCredentialSnapshot(user, "stored-hash", false, 4, null)
        };
        var passwordHashingService = new PasswordHashingServiceStub { VerifyResult = false };
        var auditEventRepository = new AuditEventRepositoryStub();
        var service = new AuthService(
            tenantRepository,
            userRepository,
            credentialRepository,
            new RoleRepositoryStub(),
            passwordHashingService,
            new AccessTokenIssuerStub(),
            auditEventRepository);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            service.LoginAsync("ACME", "user@acme.com", "bad-pass", CancellationToken.None));

        var failedLogin = Assert.Single(credentialRepository.FailedLogins);
        Assert.Equal(tenant.Id, failedLogin.TenantId);
        Assert.Equal(user.Id, failedLogin.UserId);
        Assert.NotNull(failedLogin.LockedUntilUtc);
        Assert.Equal("LOGIN_FAILED", auditEventRepository.Writes.Single().EventType);
    }

    [Fact]
    public async Task LoginAsync_Should_Reset_Failures_And_Return_Session_When_Credentials_Are_Valid()
    {
        var tenant = new Tenant(Guid.NewGuid(), "ACME", "Acme Corp", "LEGAL", "AR", DateTimeOffset.UtcNow);
        var user = User.Create(tenant.Id, "user@acme.com", "User Acme", UserStatus.Active, DateTimeOffset.UtcNow);
        var accessToken = new AuthenticatedAccessToken("jwt-token", "Bearer", DateTimeOffset.UtcNow.AddMinutes(30), 1800);
        var credentialRepository = new UserCredentialRepositoryStub
        {
            Snapshot = new UserCredentialSnapshot(user, "stored-hash", true, 2, null)
        };
        var accessTokenIssuer = new AccessTokenIssuerStub { TokenToReturn = accessToken };
        var auditEventRepository = new AuditEventRepositoryStub();
        var service = new AuthService(
            new TenantRepositoryStub { TenantByCode = tenant },
            new UserRepositoryStub(),
            credentialRepository,
            new RoleRepositoryStub(),
            new PasswordHashingServiceStub { VerifyResult = true },
            accessTokenIssuer,
            auditEventRepository);

        var session = await service.LoginAsync("ACME", "user@acme.com", "valid-pass", CancellationToken.None);

        Assert.True(session.MustChangePassword);
        Assert.Equal(accessToken, session.AccessToken);
        Assert.Single(credentialRepository.SuccessfulLogins);
        Assert.Equal("LOGIN_SUCCEEDED", auditEventRepository.Writes.Single().EventType);
        Assert.Same(user, accessTokenIssuer.IssuedUser);
    }
}
