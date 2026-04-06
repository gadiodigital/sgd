namespace Gdms.UnitTests.TestDoubles;

internal sealed class TenantRepositoryStub : ITenantRepository
{
    public IReadOnlyCollection<Tenant> ListResult { get; set; } = [];
    public Tenant? TenantById { get; set; }
    public Tenant? TenantByCode { get; set; }
    public Tenant? AddedTenant { get; private set; }

    public Task<IReadOnlyCollection<Tenant>> ListAsync(CancellationToken cancellationToken) => Task.FromResult(ListResult);

    public Task<Tenant?> GetByIdAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        return Task.FromResult(TenantById is { } tenant && tenant.Id == tenantId ? tenant : null);
    }

    public Task<Tenant?> GetByCodeAsync(string tenantCode, CancellationToken cancellationToken)
    {
        return Task.FromResult(TenantByCode is { } tenant &&
            string.Equals(tenant.Code, tenantCode.Trim(), StringComparison.OrdinalIgnoreCase)
                ? tenant
                : null);
    }

    public Task<Tenant> AddAsync(Tenant tenant, CancellationToken cancellationToken)
    {
        AddedTenant = tenant;
        TenantById = tenant;
        TenantByCode = tenant;
        return Task.FromResult(tenant);
    }
}

internal sealed class UserRepositoryStub : IUserRepository
{
    public bool TenantHasUsersResult { get; set; }
    public bool AnyUserInRoleResult { get; set; }
    public User? AddedUser { get; private set; }
    public string? AddedPasswordHash { get; private set; }
    public bool? AddedMustChangePassword { get; private set; }

    public Task<bool> TenantHasUsersAsync(Guid tenantId, CancellationToken cancellationToken) =>
        Task.FromResult(TenantHasUsersResult);

    public Task<bool> AnyUserInRoleAsync(string roleCode, CancellationToken cancellationToken) =>
        Task.FromResult(AnyUserInRoleResult);

    public Task<IReadOnlyCollection<User>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<User>>([]);

    public Task<User?> GetByIdAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken) =>
        Task.FromResult<User?>(null);

    public Task<User> AddAsync(User user, string passwordHash, bool mustChangePassword, CancellationToken cancellationToken)
    {
        AddedUser = user;
        AddedPasswordHash = passwordHash;
        AddedMustChangePassword = mustChangePassword;
        return Task.FromResult(user);
    }

    public Task<User> AssignRoleAsync(Guid tenantId, Guid userId, Role role, CancellationToken cancellationToken)
    {
        throw new NotSupportedException();
    }
}

internal sealed class UserCredentialRepositoryStub : IUserCredentialRepository
{
    public UserCredentialSnapshot? Snapshot { get; set; }
    public List<(Guid TenantId, Guid UserId, DateTimeOffset? LockedUntilUtc)> FailedLogins { get; } = [];
    public List<(Guid TenantId, Guid UserId)> SuccessfulLogins { get; } = [];

    public Task<UserCredentialSnapshot?> GetByEmailAsync(Guid tenantId, string email, CancellationToken cancellationToken)
    {
        return Task.FromResult(Snapshot);
    }

    public Task RecordSuccessfulLoginAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken)
    {
        SuccessfulLogins.Add((tenantId, userId));
        return Task.CompletedTask;
    }

    public Task RecordFailedLoginAsync(
        Guid tenantId,
        Guid userId,
        DateTimeOffset? lockedUntilUtc,
        CancellationToken cancellationToken)
    {
        FailedLogins.Add((tenantId, userId, lockedUntilUtc));
        return Task.CompletedTask;
    }
}

internal sealed class RoleRepositoryStub : IRoleRepository
{
    public Role? RoleByCode { get; set; }

    public Task<IReadOnlyCollection<Role>> ListAsync(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<Role>>([]);

    public Task<Role?> GetByCodeAsync(string roleCode, CancellationToken cancellationToken) =>
        Task.FromResult(RoleByCode);
}

internal sealed class PasswordHashingServiceStub : IPasswordHashingService
{
    public string HashResult { get; set; } = "hashed-password";
    public bool VerifyResult { get; set; }

    public string HashPassword(string password) => HashResult;

    public bool VerifyPassword(string passwordHash, string providedPassword) => VerifyResult;
}

internal sealed class AccessTokenIssuerStub : IAccessTokenIssuer
{
    public AuthenticatedAccessToken TokenToReturn { get; set; } =
        new("token-value", "Bearer", DateTimeOffset.UtcNow.AddHours(1), 3600);

    public Tenant? IssuedTenant { get; private set; }
    public User? IssuedUser { get; private set; }

    public Task<AuthenticatedAccessToken> IssueAsync(Tenant tenant, User user, CancellationToken cancellationToken)
    {
        IssuedTenant = tenant;
        IssuedUser = user;
        return Task.FromResult(TokenToReturn);
    }
}
