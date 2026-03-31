using Gdms.Domain.Tenancy;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines read and write operations for tenant persistence.
/// </summary>
public interface ITenantRepository
{
    /// <summary>
    /// Lists all known tenants.
    /// </summary>
    Task<IReadOnlyCollection<Tenant>> ListAsync(CancellationToken cancellationToken);

    /// <summary>
    /// Retrieves a tenant by its identifier.
    /// </summary>
    Task<Tenant?> GetByIdAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Retrieves a tenant by its normalized code.
    /// </summary>
    Task<Tenant?> GetByCodeAsync(string tenantCode, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new tenant aggregate.
    /// </summary>
    Task<Tenant> AddAsync(Tenant tenant, CancellationToken cancellationToken);
}
