using Gdms.Application.Documents;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines catalog read operations for document types and metadata schema.
/// </summary>
public interface IDocumentTypeRepository
{
    /// <summary>
    /// Lists the active document types visible for a tenant.
    /// </summary>
    Task<IReadOnlyCollection<DocumentTypeDefinition>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Resolves a single active document type visible for a tenant.
    /// </summary>
    Task<DocumentTypeDefinition?> GetByCodeAsync(
        Guid tenantId,
        string documentTypeCode,
        CancellationToken cancellationToken);
}
