using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Documents;
using System.Text.Json;

namespace Gdms.Application.Documents;

/// <summary>
/// Coordinates document registration and query use cases.
/// </summary>
public sealed class DocumentService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentMetadataRepository _documentMetadataRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly IDocumentSearchRepository _documentSearchRepository;
    private readonly DocumentMetadataSchemaValidator _documentMetadataSchemaValidator;
    private readonly DocumentTypeCatalogService _documentTypeCatalogService;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with repositories required by the document workflow.
    /// </summary>
    public DocumentService(
        IDocumentRepository documentRepository,
        IDocumentSearchRepository documentSearchRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository,
        IDocumentMetadataRepository documentMetadataRepository,
        DocumentTypeCatalogService documentTypeCatalogService,
        DocumentMetadataSchemaValidator documentMetadataSchemaValidator)
    {
        _documentRepository = documentRepository;
        _documentSearchRepository = documentSearchRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
        _documentMetadataRepository = documentMetadataRepository;
        _documentTypeCatalogService = documentTypeCatalogService;
        _documentMetadataSchemaValidator = documentMetadataSchemaValidator;
    }

    /// <summary>
    /// Lists the documents that belong to a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<Document>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _documentRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Searches tenant documents using a free-text query.
    /// </summary>
    public async Task<IReadOnlyCollection<Document>> SearchAsync(
        Guid tenantId,
        string? query,
        string? documentTypeCode,
        DocumentStatus? status,
        bool? onLegalHold,
        int limit,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var documents = await _documentSearchRepository.SearchAsync(
            tenantId,
            query,
            documentTypeCode,
            status,
            onLegalHold,
            limit,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            "DOCUMENT_SEARCH",
            "INFO",
            JsonSerializer.Serialize(new
            {
                Query = query,
                DocumentTypeCode = documentTypeCode,
                Status = status?.ToString(),
                OnLegalHold = onLegalHold,
                Limit = limit,
                ResultCount = documents.Count
            }),
            cancellationToken);

        return documents;
    }

    /// <summary>
    /// Retrieves a single document aggregate.
    /// </summary>
    public async Task<Document?> GetByIdAsync(
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

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            document.Id,
            "DOCUMENT_READ",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                document.DocumentTypeCode,
                document.Title
            }),
            cancellationToken);

        return document;
    }

    /// <summary>
    /// Creates a new document with its first version after validating tenant ownership.
    /// </summary>
    public async Task<Document> CreateAsync(
        Guid tenantId,
        string documentTypeCode,
        string title,
        string storageObjectKey,
        string mimeType,
        string fileHashSha256,
        long fileSizeBytes,
        string? metadataJson,
        Guid uploadedByUserId,
        CancellationToken cancellationToken)
    {
        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para registrar el documento.");
        }

        var documentType = await _documentTypeCatalogService.GetRequiredByCodeAsync(
            tenantId,
            documentTypeCode,
            cancellationToken);
        var normalizedMetadataJson = _documentMetadataSchemaValidator.ValidateAndNormalize(
            metadataJson,
            documentType);
        var document = Document.Create(tenantId, documentType.Code, title, DateTimeOffset.UtcNow);
        document.AddVersion(storageObjectKey, mimeType, fileHashSha256, fileSizeBytes, uploadedByUserId, DateTimeOffset.UtcNow);

        var persistedDocument = await _documentRepository.AddAsync(document, cancellationToken);
        if (!string.IsNullOrWhiteSpace(normalizedMetadataJson))
        {
            await _documentMetadataRepository.UpsertAsync(
                tenantId,
                persistedDocument.Id,
                normalizedMetadataJson,
                cancellationToken);
        }

        await _auditEventRepository.WriteAsync(
            tenantId,
            uploadedByUserId,
            persistedDocument.Id,
            "DOCUMENT_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedDocument.Id,
                persistedDocument.DocumentTypeCode,
                persistedDocument.Title,
                persistedDocument.CreatedAtUtc,
                MetadataCaptured = !string.IsNullOrWhiteSpace(normalizedMetadataJson)
            }),
            cancellationToken);

        return persistedDocument;
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
