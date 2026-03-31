using Gdms.Domain.Documents;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for per-document access control entries.
/// </summary>
public interface IDocumentAccessRepository
{
    /// <summary>
    /// Lists explicit ACL entries configured for a document.
    /// </summary>
    Task<IReadOnlyCollection<DocumentAccessEntry>> ListByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new ACL entry in an idempotent way.
    /// </summary>
    Task<DocumentAccessEntry> GrantAsync(
        DocumentAccessEntry entry,
        CancellationToken cancellationToken);

    /// <summary>
    /// Returns whether a user has a specific explicit permission on the document.
    /// </summary>
    Task<bool> UserHasPermissionAsync(
        Guid tenantId,
        Guid documentId,
        Guid userId,
        DocumentAccessPermission permission,
        CancellationToken cancellationToken);

    /// <summary>
    /// Returns whether a document has at least one explicit ACL entry.
    /// </summary>
    Task<bool> HasExplicitEntriesAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken);
}
