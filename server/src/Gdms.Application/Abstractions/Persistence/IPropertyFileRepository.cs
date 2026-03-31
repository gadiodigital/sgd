using Gdms.Domain.RealEstate;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Persists property files and their document links.
/// </summary>
public interface IPropertyFileRepository
{
    Task<IReadOnlyCollection<PropertyFile>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken);
    Task<PropertyFile?> GetByIdAsync(Guid tenantId, Guid propertyFileId, CancellationToken cancellationToken);
    Task<PropertyFile> AddAsync(PropertyFile propertyFile, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<PropertyFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid propertyFileId,
        CancellationToken cancellationToken);
    Task AttachDocumentAsync(
        Guid tenantId,
        Guid propertyFileId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken);
}
