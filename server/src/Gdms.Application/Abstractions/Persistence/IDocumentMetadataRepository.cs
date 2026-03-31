namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for current document metadata values.
/// </summary>
public interface IDocumentMetadataRepository
{
    /// <summary>
    /// Reads the current metadata object associated with a document.
    /// </summary>
    Task<string?> GetByDocumentIdAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Inserts or replaces the current metadata object for a document.
    /// </summary>
    Task UpsertAsync(
        Guid tenantId,
        Guid documentId,
        string metadataJson,
        CancellationToken cancellationToken);
}
