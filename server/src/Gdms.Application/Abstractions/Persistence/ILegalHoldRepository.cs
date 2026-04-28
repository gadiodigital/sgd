using Gdms.Domain.Records;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for document legal holds.
/// </summary>
public interface ILegalHoldRepository
{
    /// <summary>
    /// Lists the legal holds associated with a document.
    /// </summary>
    Task<IReadOnlyCollection<LegalHold>> ListByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Returns a legal hold by identifier inside an organization.
    /// </summary>
    Task<LegalHold?> GetByIdAsync(Guid tenantId, Guid legalHoldId, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new legal hold.
    /// </summary>
    Task<LegalHold> AddAsync(LegalHold legalHold, CancellationToken cancellationToken);

    /// <summary>
    /// Releases an existing legal hold.
    /// </summary>
    Task<LegalHold> ReleaseAsync(
        Guid tenantId,
        Guid legalHoldId,
        Guid releasedByUserId,
        string releaseReason,
        CancellationToken cancellationToken);
}
