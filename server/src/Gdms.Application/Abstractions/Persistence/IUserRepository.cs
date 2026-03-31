using Gdms.Domain.Identity;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for tenant-scoped users.
/// </summary>
public interface IUserRepository
{
    /// <summary>
    /// Returns whether a tenant already has at least one registered user.
    /// </summary>
    Task<bool> TenantHasUsersAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Returns whether any user in the platform already has the specified role.
    /// </summary>
    Task<bool> AnyUserInRoleAsync(string roleCode, CancellationToken cancellationToken);

    /// <summary>
    /// Lists the users for a tenant.
    /// </summary>
    Task<IReadOnlyCollection<User>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Returns a tenant user by identifier.
    /// </summary>
    Task<User?> GetByIdAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a newly created user aggregate.
    /// </summary>
    Task<User> AddAsync(
        User user,
        string passwordHash,
        bool mustChangePassword,
        CancellationToken cancellationToken);

    /// <summary>
    /// Assigns a role to an existing user and returns the updated aggregate.
    /// </summary>
    Task<User> AssignRoleAsync(Guid tenantId, Guid userId, Role role, CancellationToken cancellationToken);
}
