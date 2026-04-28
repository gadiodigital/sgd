using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Abstractions.Security;
using Gdms.Domain.Common;
using Gdms.Domain.Identity;
using System.Text.Json;

namespace Gdms.Application.Identity;

/// <summary>
/// Coordinates bootstrap and local authentication workflows.
/// </summary>
public sealed class AuthService
{
    private const int LockoutMinutes = 15;
    private const int MaxFailedAttempts = 5;
    private readonly IAccessTokenIssuer _accessTokenIssuer;
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IPasswordHashingService _passwordHashingService;
    private readonly IRoleRepository _roleRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IUserCredentialRepository _userCredentialRepository;
    private readonly IUserRepository _userRepository;

    /// <summary>
    /// Initializes the service with identity persistence and token services.
    /// </summary>
    public AuthService(
        ITenantRepository tenantRepository,
        IUserRepository userRepository,
        IUserCredentialRepository userCredentialRepository,
        IRoleRepository roleRepository,
        IPasswordHashingService passwordHashingService,
        IAccessTokenIssuer accessTokenIssuer,
        IAuditEventRepository auditEventRepository)
    {
        _tenantRepository = tenantRepository;
        _userRepository = userRepository;
        _userCredentialRepository = userCredentialRepository;
        _roleRepository = roleRepository;
        _passwordHashingService = passwordHashingService;
        _accessTokenIssuer = accessTokenIssuer;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Bootstraps the first tenant administrator when a tenant has no users.
    /// </summary>
    public async Task<AuthenticatedSession> BootstrapTenantAdminAsync(
        string tenantCode,
        string email,
        string fullName,
        string password,
        CancellationToken cancellationToken)
    {
        var tenant = await GetTenantByCodeAsync(tenantCode, cancellationToken);
        if (await _userRepository.TenantHasUsersAsync(tenant.Id, cancellationToken))
        {
            throw new DomainRuleException("El bootstrap inicial solo está disponible cuando el tenant no tiene usuarios.");
        }

        var adminRole = await _roleRepository.GetByCodeAsync("TENANT_ADMIN", cancellationToken)
            ?? throw new DomainRuleException("No existe el rol TENANT_ADMIN configurado en la plataforma.");

        var user = User.Create(tenant.Id, email, fullName, UserStatus.Active, DateTimeOffset.UtcNow);
        user.AssignRole(adminRole);

        var persistedUser = await _userRepository.AddAsync(
            user,
            _passwordHashingService.HashPassword(password),
            mustChangePassword: false,
            cancellationToken);

        var accessToken = await _accessTokenIssuer.IssueAsync(tenant, persistedUser, cancellationToken);
        await _auditEventRepository.WriteAsync(
            tenant.Id,
            persistedUser.Id,
            null,
            "TENANT_ADMIN_BOOTSTRAPPED",
            "WARNING",
            JsonSerializer.Serialize(new
            {
                UserId = persistedUser.Id,
                persistedUser.Email,
                TenantId = tenant.Id,
                TenantCode = tenant.Code
            }),
            cancellationToken);

        return new AuthenticatedSession(tenant, persistedUser, false, accessToken);
    }

    /// <summary>
    /// Bootstraps the first platform administrator when no platform admin exists yet.
    /// </summary>
    public async Task<AuthenticatedSession> BootstrapPlatformAdminAsync(
        string tenantCode,
        string email,
        string fullName,
        string password,
        CancellationToken cancellationToken)
    {
        if (await _userRepository.AnyUserInRoleAsync("PLATFORM_ADMIN", cancellationToken))
        {
            throw new DomainRuleException("Ya existe al menos un PLATFORM_ADMIN en la plataforma.");
        }

        var tenant = await GetTenantByCodeAsync(tenantCode, cancellationToken);
        var platformAdminRole = await _roleRepository.GetByCodeAsync("PLATFORM_ADMIN", cancellationToken)
            ?? throw new DomainRuleException("No existe el rol PLATFORM_ADMIN configurado en la plataforma.");

        var user = User.Create(tenant.Id, email, fullName, UserStatus.Active, DateTimeOffset.UtcNow);
        user.AssignRole(platformAdminRole);

        var persistedUser = await _userRepository.AddAsync(
            user,
            _passwordHashingService.HashPassword(password),
            mustChangePassword: false,
            cancellationToken);

        var accessToken = await _accessTokenIssuer.IssueAsync(tenant, persistedUser, cancellationToken);
        await _auditEventRepository.WriteAsync(
            tenant.Id,
            persistedUser.Id,
            null,
            "PLATFORM_ADMIN_BOOTSTRAPPED",
            "CRITICAL",
            JsonSerializer.Serialize(new
            {
                UserId = persistedUser.Id,
                persistedUser.Email,
                TenantId = tenant.Id,
                TenantCode = tenant.Code
            }),
            cancellationToken);

        return new AuthenticatedSession(tenant, persistedUser, false, accessToken);
    }

    /// <summary>
    /// Returns whether the platform already has a global platform administrator.
    /// </summary>
    public Task<bool> PlatformAdminExistsAsync(CancellationToken cancellationToken)
    {
        return _userRepository.AnyUserInRoleAsync("PLATFORM_ADMIN", cancellationToken);
    }

    /// <summary>
    /// Authenticates an organization user using local credentials and issues a JWT bearer token.
    /// </summary>
    public async Task<AuthenticatedSession> LoginAsync(
        string tenantCode,
        string email,
        string password,
        CancellationToken cancellationToken)
    {
        var tenant = await GetTenantByCodeAsync(tenantCode, cancellationToken);
        var snapshot = await _userCredentialRepository.GetByEmailAsync(tenant.Id, email, cancellationToken);
        if (snapshot is null || string.IsNullOrWhiteSpace(snapshot.PasswordHash))
        {
            await _auditEventRepository.WriteAsync(
                tenant.Id,
                null,
                null,
                "LOGIN_FAILED",
                "WARNING",
                JsonSerializer.Serialize(new
                {
                    tenant.Id,
                    tenant.Code,
                    Email = email.Trim().ToLowerInvariant(),
                    Reason = "UNKNOWN_USER"
                }),
                cancellationToken);

            throw new UnauthorizedAccessException("Credenciales inválidas.");
        }

        if (snapshot.User.Status != UserStatus.Active)
        {
            await _auditEventRepository.WriteAsync(
                tenant.Id,
                snapshot.User.Id,
                null,
                "LOGIN_REJECTED",
                "WARNING",
                JsonSerializer.Serialize(new
                {
                    snapshot.User.Id,
                    snapshot.User.Email,
                    Status = snapshot.User.Status.ToString().ToUpperInvariant()
                }),
                cancellationToken);

            throw new UnauthorizedAccessException("Solo los usuarios activos pueden iniciar sesión.");
        }

        var now = DateTimeOffset.UtcNow;
        if (snapshot.LockedUntilUtc is { } lockedUntilUtc && lockedUntilUtc > now)
        {
            await _auditEventRepository.WriteAsync(
                tenant.Id,
                snapshot.User.Id,
                null,
                "LOGIN_BLOCKED",
                "WARNING",
                JsonSerializer.Serialize(new
                {
                    snapshot.User.Id,
                    snapshot.User.Email,
                    LockedUntilUtc = lockedUntilUtc
                }),
                cancellationToken);

            throw new DomainRuleException($"La cuenta se encuentra bloqueada temporalmente hasta {lockedUntilUtc:O}.");
        }

        if (!_passwordHashingService.VerifyPassword(snapshot.PasswordHash, password))
        {
            var lockedUntil = snapshot.FailedLoginCount + 1 >= MaxFailedAttempts
                ? now.AddMinutes(LockoutMinutes)
                : (DateTimeOffset?)null;

            await _userCredentialRepository.RecordFailedLoginAsync(
                tenant.Id,
                snapshot.User.Id,
                lockedUntil,
                cancellationToken);

            await _auditEventRepository.WriteAsync(
                tenant.Id,
                snapshot.User.Id,
                null,
                "LOGIN_FAILED",
                "WARNING",
                JsonSerializer.Serialize(new
                {
                    snapshot.User.Id,
                    snapshot.User.Email,
                    LockedUntilUtc = lockedUntil
                }),
                cancellationToken);

            throw new UnauthorizedAccessException("Credenciales inválidas.");
        }

        await _userCredentialRepository.RecordSuccessfulLoginAsync(tenant.Id, snapshot.User.Id, cancellationToken);

        var accessToken = await _accessTokenIssuer.IssueAsync(tenant, snapshot.User, cancellationToken);
        await _auditEventRepository.WriteAsync(
            tenant.Id,
            snapshot.User.Id,
            null,
            "LOGIN_SUCCEEDED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                UserId = snapshot.User.Id,
                snapshot.User.Email,
                TenantId = tenant.Id,
                TenantCode = tenant.Code
            }),
            cancellationToken);

        return new AuthenticatedSession(tenant, snapshot.User, snapshot.MustChangePassword, accessToken);
    }

    private async Task<Domain.Tenancy.Tenant> GetTenantByCodeAsync(string tenantCode, CancellationToken cancellationToken)
    {
        var tenant = await _tenantRepository.GetByCodeAsync(tenantCode, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe un tenant activo para el código informado.");
        }

        return tenant;
    }
}
