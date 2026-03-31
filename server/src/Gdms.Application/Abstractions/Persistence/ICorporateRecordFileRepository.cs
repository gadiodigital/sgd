using Gdms.Domain.Corporate;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Persists corporate record files and their document links.
/// </summary>
public interface ICorporateRecordFileRepository
{
    Task<IReadOnlyCollection<CorporateRecordFile>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);
    Task<CorporateRecordFile?> GetByIdAsync(Guid tenantId, Guid corporateRecordFileId, CancellationToken cancellationToken);
    Task<CorporateRecordFile> AddAsync(CorporateRecordFile corporateRecordFile, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<CorporateRecordFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        CancellationToken cancellationToken);
    Task AttachDocumentAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken);
}
