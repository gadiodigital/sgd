using Gdms.Application.Records;
using Gdms.Domain.Documents;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for retention-driven disposition workflows.
/// </summary>
public interface IDocumentDispositionRepository
{
    /// <summary>
    /// Lists retention candidates due for disposition.
    /// </summary>
    Task<IReadOnlyCollection<DispositionCandidate>> ListDueAsync(
        Guid tenantId,
        DateTimeOffset asOfUtc,
        CancellationToken cancellationToken);

    /// <summary>
    /// Returns a single retention candidate by document identifier.
    /// </summary>
    Task<DispositionCandidate?> GetDueByIdAsync(
        Guid tenantId,
        Guid documentId,
        DateTimeOffset asOfUtc,
        CancellationToken cancellationToken);

    /// <summary>
    /// Applies the final disposition to a document.
    /// </summary>
    Task ApplyDispositionAsync(
        Guid tenantId,
        Guid documentId,
        string dispositionAction,
        DocumentStatus nextStatus,
        CancellationToken cancellationToken);
}
