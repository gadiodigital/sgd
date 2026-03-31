using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;

namespace Gdms.Application.Audit;

/// <summary>
/// Coordinates read access to recent audit events.
/// </summary>
public sealed class AuditEventService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with audit and tenant repositories.
    /// </summary>
    public AuditEventService(
        IAuditEventRepository auditEventRepository,
        IDocumentRepository documentRepository,
        ITenantRepository tenantRepository)
    {
        _auditEventRepository = auditEventRepository;
        _documentRepository = documentRepository;
        _tenantRepository = tenantRepository;
    }

    /// <summary>
    /// Lists recent audit events across the platform.
    /// </summary>
    public Task<IReadOnlyCollection<AuditEventEntry>> ListRecentAsync(
        int limit,
        CancellationToken cancellationToken)
    {
        return _auditEventRepository.ListRecentAsync(NormalizeLimit(limit), cancellationToken);
    }

    /// <summary>
    /// Lists recent audit events within a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByTenantAsync(
        Guid tenantId,
        int limit,
        CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para consultar auditoría.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para consultar auditoría.");
        }

        return await _auditEventRepository.ListRecentByTenantAsync(
            tenantId,
            NormalizeLimit(limit),
            cancellationToken);
    }

    /// <summary>
    /// Lists recent audit events linked to a document within a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        int limit,
        CancellationToken cancellationToken)
    {
        if (documentId == Guid.Empty)
        {
            throw new DomainRuleException("El documento informado es obligatorio para consultar auditoría.");
        }

        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado para consultar auditoría.");
        }

        return await _auditEventRepository.ListRecentByDocumentAsync(
            tenantId,
            documentId,
            NormalizeLimit(limit),
            cancellationToken);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para consultar auditoría.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para consultar auditoría.");
        }
    }

    private static int NormalizeLimit(int limit)
    {
        if (limit <= 0)
        {
            return 50;
        }

        return Math.Min(limit, 250);
    }
}
