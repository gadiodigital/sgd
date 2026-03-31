namespace Gdms.Application.Abstractions.Storage;

/// <summary>
/// Defines the binary storage operations required by the document workflow.
/// </summary>
public interface IDocumentBinaryStore
{
    /// <summary>
    /// Stores a binary payload and returns the generated storage descriptor.
    /// </summary>
    Task<StoredBinaryObject> SaveAsync(
        Guid tenantId,
        string fileName,
        string mimeType,
        Stream content,
        CancellationToken cancellationToken);

    /// <summary>
    /// Opens an existing binary payload for read-only download.
    /// </summary>
    Task<StoredBinaryContent?> OpenReadAsync(
        string objectKey,
        CancellationToken cancellationToken);
}
