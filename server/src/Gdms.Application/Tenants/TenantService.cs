using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Tenancy;
using System.Text.Json;

namespace Gdms.Application.Tenants;

/// <summary>
/// Coordinates legacy organization use cases for the API layer.
/// </summary>
public sealed class TenantService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with a tenant repository.
    /// </summary>
    public TenantService(ITenantRepository tenantRepository, IAuditEventRepository auditEventRepository)
    {
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Returns all known legacy organization records.
    /// </summary>
    public Task<IReadOnlyCollection<Tenant>> ListAsync(CancellationToken cancellationToken)
    {
        return _tenantRepository.ListAsync(cancellationToken);
    }

    /// <summary>
    /// Returns one organization by identifier.
    /// </summary>
    public Task<Tenant?> GetByIdAsync(Guid organizationId, CancellationToken cancellationToken)
    {
        return _tenantRepository.GetByIdAsync(organizationId, cancellationToken);
    }

    /// <summary>
    /// Creates and persists the initial organization record.
    /// </summary>
    public Task<Tenant> CreateAsync(
        string code,
        string name,
        string sector,
        string primaryCountryCode,
        Guid? actorUserId,
        CancellationToken cancellationToken)
    {
        var tenant = Tenant.Create(code, name, sector, primaryCountryCode, DateTimeOffset.UtcNow);
        return CreateAndAuditAsync(tenant, actorUserId, cancellationToken);
    }

    private async Task<Tenant> CreateAndAuditAsync(
        Tenant tenant,
        Guid? actorUserId,
        CancellationToken cancellationToken)
    {
        var persistedTenant = await _tenantRepository.AddAsync(tenant, cancellationToken);

        await _auditEventRepository.WriteAsync(
            persistedTenant.Id,
            actorUserId,
            null,
            "TENANT_CREATED",
            "CRITICAL",
            JsonSerializer.Serialize(new
            {
                persistedTenant.Id,
                persistedTenant.Code,
                persistedTenant.Name,
                persistedTenant.Sector
            }),
            cancellationToken);

        return persistedTenant;
    }
}
