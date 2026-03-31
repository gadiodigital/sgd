using Gdms.Domain.Documents;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines document-search operations optimized for query scenarios.
/// </summary>
public interface IDocumentSearchRepository
{
    /// <summary>
    /// Searches documents within a tenant using a free-text term and result limit.
    /// </summary>
    Task<IReadOnlyCollection<Document>> SearchAsync(
        Guid tenantId,
        string? query,
        string? documentTypeCode,
        DocumentStatus? status,
        bool? onLegalHold,
        int limit,
        CancellationToken cancellationToken);
}
