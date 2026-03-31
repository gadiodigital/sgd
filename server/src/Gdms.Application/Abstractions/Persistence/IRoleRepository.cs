using Gdms.Domain.Identity;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for authorization roles.
/// </summary>
public interface IRoleRepository
{
    /// <summary>
    /// Lists the roles available in the platform.
    /// </summary>
    Task<IReadOnlyCollection<Role>> ListAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Returns a role by its normalized code.
    /// </summary>
    Task<Role?> GetByCodeAsync(string roleCode, CancellationToken cancellationToken);
}
