using Gdms.Domain.Cases;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines read and write operations for case files.
/// </summary>
public interface ICaseFileRepository
{
    /// <summary>
    /// Lists case files that belong to a tenant.
    /// </summary>
    Task<IReadOnlyCollection<CaseFile>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);

    /// <summary>
    /// Retrieves a case file by tenant and identifier.
    /// </summary>
    Task<CaseFile?> GetByIdAsync(Guid tenantId, Guid caseFileId, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new case file.
    /// </summary>
    Task<CaseFile> AddAsync(CaseFile caseFile, CancellationToken cancellationToken);

    /// <summary>
    /// Lists documents linked to the case file.
    /// </summary>
    Task<IReadOnlyCollection<CaseFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid caseFileId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Creates a new relationship between a case file and a document.
    /// </summary>
    Task AttachDocumentAsync(
        Guid tenantId,
        Guid caseFileId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken);
}
