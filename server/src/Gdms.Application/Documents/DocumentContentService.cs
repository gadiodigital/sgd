using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Abstractions.Storage;
using Gdms.Domain.Common;
using Gdms.Domain.Documents;

namespace Gdms.Application.Documents;

/// <summary>
/// Coordinates binary upload, versioning and download operations for documents.
/// </summary>
public sealed class DocumentContentService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentBinaryStore _documentBinaryStore;
    private readonly IDocumentRepository _documentRepository;
    private readonly DocumentService _documentService;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with binary storage and document dependencies.
    /// </summary>
    public DocumentContentService(
        IDocumentRepository documentRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository,
        IDocumentBinaryStore documentBinaryStore,
        DocumentService documentService)
    {
        _documentRepository = documentRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
        _documentBinaryStore = documentBinaryStore;
        _documentService = documentService;
    }

    /// <summary>
    /// Stores an uploaded binary and registers the corresponding document aggregate.
    /// </summary>
    public async Task<Document> UploadAsync(
        Guid tenantId,
        string documentTypeCode,
        string title,
        string fileName,
        string mimeType,
        Stream content,
        string? metadataJson,
        Guid uploadedByUserId,
        CancellationToken cancellationToken)
    {
        var storedBinary = await _documentBinaryStore.SaveAsync(
            tenantId,
            fileName,
            mimeType,
            content,
            cancellationToken);

        return await _documentService.CreateAsync(
            tenantId,
            documentTypeCode,
            title,
            storedBinary.ObjectKey,
            mimeType,
            storedBinary.FileHashSha256,
            storedBinary.FileSizeBytes,
            metadataJson,
            uploadedByUserId,
            cancellationToken);
    }

    /// <summary>
    /// Uploads a new immutable version for an existing document.
    /// </summary>
    public async Task<Document> UploadNewVersionAsync(
        Guid tenantId,
        Guid documentId,
        string fileName,
        string mimeType,
        Stream content,
        Guid uploadedByUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant.");
        }

        var storedBinary = await _documentBinaryStore.SaveAsync(
            tenantId,
            fileName,
            mimeType,
            content,
            cancellationToken);

        var version = document.AddVersion(
            storedBinary.ObjectKey,
            mimeType,
            storedBinary.FileHashSha256,
            storedBinary.FileSizeBytes,
            uploadedByUserId,
            DateTimeOffset.UtcNow);
        var persistedDocument = await _documentRepository.AddVersionAsync(
            document,
            version,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            uploadedByUserId,
            document.Id,
            "DOCUMENT_VERSION_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                VersionNumber = version.VersionNumber,
                version.StorageObjectKey,
                version.FileSizeBytes
            }),
            cancellationToken);

        return persistedDocument;
    }

    /// <summary>
    /// Opens the latest binary content of a document for download.
    /// </summary>
    public async Task<DocumentDownloadContent?> OpenDownloadAsync(
        Guid tenantId,
        Guid documentId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            return null;
        }

        var latestVersion = document.Versions.OrderByDescending(version => version.VersionNumber).FirstOrDefault();
        if (latestVersion is null)
        {
            return null;
        }

        var binaryContent = await _documentBinaryStore.OpenReadAsync(
            latestVersion.StorageObjectKey,
            cancellationToken);
        if (binaryContent is null)
        {
            return null;
        }

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            document.Id,
            "DOCUMENT_DOWNLOAD",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                latestVersion.VersionNumber,
                latestVersion.StorageObjectKey
            }),
            cancellationToken);

        var fileExtension = Path.GetExtension(latestVersion.StorageObjectKey);
        var downloadFileName = string.IsNullOrWhiteSpace(fileExtension)
            ? document.Title
            : $"{document.Title}{fileExtension}";

        return new DocumentDownloadContent(
            binaryContent.Content,
            latestVersion.MimeType,
            downloadFileName,
            latestVersion.FileSizeBytes);
    }

    /// <summary>
    /// Opens a specific immutable version of a document for download.
    /// </summary>
    public async Task<DocumentDownloadContent?> OpenVersionDownloadAsync(
        Guid tenantId,
        Guid documentId,
        int versionNumber,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            return null;
        }

        var version = document.Versions.SingleOrDefault(item => item.VersionNumber == versionNumber);
        if (version is null)
        {
            return null;
        }

        var binaryContent = await _documentBinaryStore.OpenReadAsync(
            version.StorageObjectKey,
            cancellationToken);
        if (binaryContent is null)
        {
            return null;
        }

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            document.Id,
            "DOCUMENT_VERSION_DOWNLOAD",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                version.VersionNumber,
                version.StorageObjectKey
            }),
            cancellationToken);

        var fileExtension = Path.GetExtension(version.StorageObjectKey);
        var downloadFileName = string.IsNullOrWhiteSpace(fileExtension)
            ? $"{document.Title}-v{version.VersionNumber}"
            : $"{document.Title}-v{version.VersionNumber}{fileExtension}";

        return new DocumentDownloadContent(
            binaryContent.Content,
            version.MimeType,
            downloadFileName,
            version.FileSizeBytes);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para la operación documental.");
        }
    }
}
