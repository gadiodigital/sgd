using Gdms.Domain.Documents;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines read and write operations for document persistence.
/// </summary>
public interface IDocumentRepository
{
    /// <summary>
    /// Lists all document aggregates that belong to a tenant.
    /// </summary>
    Task<IReadOnlyCollection<Document>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Retrieves a document aggregate by identifier.
    /// </summary>
    Task<Document?> GetByIdAsync(Guid documentId, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new document aggregate.
    /// </summary>
    Task<Document> AddAsync(Document document, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new immutable version for an existing document.
    /// </summary>
    Task<Document> AddVersionAsync(
        Document document,
        DocumentVersion version,
        CancellationToken cancellationToken);

    /// <summary>
    /// Applies a retention policy to an existing document.
    /// </summary>
    Task AssignRetentionPolicyAsync(
        Guid tenantId,
        Guid documentId,
        Guid retentionPolicyId,
        CancellationToken cancellationToken);
}
