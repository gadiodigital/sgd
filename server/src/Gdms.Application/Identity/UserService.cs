using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Abstractions.Security;
using Gdms.Domain.Common;
using Gdms.Domain.Identity;
using System.Text.Json;

namespace Gdms.Application.Identity;

/// <summary>
/// Coordinates user management and role assignment use cases.
/// </summary>
public sealed class UserService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly IPasswordHashingService _passwordHashingService;
    private readonly ITenantRepository _tenantRepository;
    private readonly IUserRepository _userRepository;

    /// <summary>
    /// Initializes the service with required repositories.
    /// </summary>
    public UserService(
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        ITenantRepository tenantRepository,
        IPasswordHashingService passwordHashingService,
        IAuditEventRepository auditEventRepository)
    {
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _tenantRepository = tenantRepository;
        _passwordHashingService = passwordHashingService;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists the users of a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<User>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _userRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Returns a user by identifier inside a tenant.
    /// </summary>
    public async Task<User?> GetByIdAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _userRepository.GetByIdAsync(tenantId, userId, cancellationToken);
    }

    /// <summary>
    /// Creates a user and optionally assigns its initial roles.
    /// </summary>
    public async Task<User> CreateAsync(
        Guid tenantId,
        string email,
        string fullName,
        string temporaryPassword,
        string? initialStatus,
        IEnumerable<string>? roleCodes,
        bool requirePasswordChange,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var user = User.Create(
            tenantId,
            email,
            fullName,
            ParseStatus(initialStatus),
            DateTimeOffset.UtcNow);

        foreach (var role in await ResolveRolesAsync(roleCodes, cancellationToken))
        {
            user.AssignRole(role);
        }

        var persistedUser = await _userRepository.AddAsync(
            user,
            _passwordHashingService.HashPassword(temporaryPassword),
            requirePasswordChange,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            "USER_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedUser.Id,
                persistedUser.Email,
                persistedUser.FullName,
                Roles = persistedUser.Roles.Select(role => role.Code).ToArray()
            }),
            cancellationToken);

        return persistedUser;
    }

    /// <summary>
    /// Assigns a platform role to an existing tenant user.
    /// </summary>
    public async Task<User> AssignRoleAsync(
        Guid tenantId,
        Guid userId,
        string roleCode,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var role = await _roleRepository.GetByCodeAsync(roleCode, cancellationToken);
        if (role is null)
        {
            throw new DomainRuleException($"No existe un rol activo con código '{roleCode}'.");
        }

        var user = await _userRepository.AssignRoleAsync(tenantId, userId, role, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            "USER_ROLE_ASSIGNED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                user.Id,
                user.Email,
                AssignedRole = role.Code
            }),
            cancellationToken);

        return user;
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para la operación de identidad.");
        }
    }

    private async Task<IReadOnlyCollection<Role>> ResolveRolesAsync(
        IEnumerable<string>? roleCodes,
        CancellationToken cancellationToken)
    {
        var resolvedRoles = new List<Role>();
        var normalizedCodes = (roleCodes ?? [])
            .Where(code => !string.IsNullOrWhiteSpace(code))
            .Select(code => code.Trim().ToUpperInvariant())
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        foreach (var code in normalizedCodes)
        {
            var role = await _roleRepository.GetByCodeAsync(code, cancellationToken);
            if (role is null)
            {
                throw new DomainRuleException($"No existe un rol activo con código '{code}'.");
            }

            resolvedRoles.Add(role);
        }

        return resolvedRoles;
    }

    private static UserStatus ParseStatus(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return UserStatus.Pending;
        }

        if (Enum.TryParse<UserStatus>(value.Trim(), ignoreCase: true, out var status))
        {
            return status;
        }

        throw new DomainRuleException("El estado inicial del usuario no es válido.");
    }
}
