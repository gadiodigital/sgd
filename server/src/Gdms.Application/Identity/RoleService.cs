using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Identity;

namespace Gdms.Application.Identity;

/// <summary>
/// Coordinates role lookup use cases.
/// </summary>
public sealed class RoleService
{
    private readonly IRoleRepository _roleRepository;

    /// <summary>
    /// Initializes the service with the role repository.
    /// </summary>
    public RoleService(IRoleRepository roleRepository)
    {
        _roleRepository = roleRepository;
    }

    /// <summary>
    /// Lists the roles available in the platform.
    /// </summary>
    public Task<IReadOnlyCollection<Role>> ListAsync(CancellationToken cancellationToken)
    {
        return _roleRepository.ListAsync(cancellationToken);
    }
}
