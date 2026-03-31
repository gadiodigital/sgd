using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;

namespace Gdms.Application.Documents;

/// <summary>
/// Coordinates tenant-scoped access to document type catalog definitions.
/// </summary>
public sealed class DocumentTypeCatalogService
{
    private readonly IDocumentTypeRepository _documentTypeRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with required repositories.
    /// </summary>
    public DocumentTypeCatalogService(
        IDocumentTypeRepository documentTypeRepository,
        ITenantRepository tenantRepository)
    {
        _documentTypeRepository = documentTypeRepository;
        _tenantRepository = tenantRepository;
    }

    /// <summary>
    /// Lists the document types visible within a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<DocumentTypeDefinition>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _documentTypeRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Resolves a single document type visible within a tenant or throws when missing.
    /// </summary>
    public async Task<DocumentTypeDefinition> GetRequiredByCodeAsync(
        Guid tenantId,
        string documentTypeCode,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var documentType = await _documentTypeRepository.GetByCodeAsync(
            tenantId,
            documentTypeCode,
            cancellationToken);
        if (documentType is not null)
        {
            return documentType;
        }

        throw new DomainRuleException(
            $"No existe un tipo documental activo para el código '{documentTypeCode}'.");
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para consultar tipos documentales.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para consultar tipos documentales.");
        }
    }
}
