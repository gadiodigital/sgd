using Gdms.Domain.Records;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for retention policy lookup.
/// </summary>
public interface IRetentionPolicyRepository
{
    /// <summary>
    /// Lists active retention policies available to a tenant.
    /// </summary>
    Task<IReadOnlyCollection<RetentionPolicy>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Returns a retention policy by code, considering tenant-specific overrides first.
    /// </summary>
    Task<RetentionPolicy?> GetByCodeAsync(Guid tenantId, string policyCode, CancellationToken cancellationToken);
}
