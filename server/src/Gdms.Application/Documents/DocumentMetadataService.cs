using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;

namespace Gdms.Application.Documents;

/// <summary>
/// Coordinates tenant-scoped read access to current document metadata.
/// </summary>
public sealed class DocumentMetadataService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentMetadataRepository _documentMetadataRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly DocumentMetadataSchemaValidator _documentMetadataSchemaValidator;
    private readonly DocumentTypeCatalogService _documentTypeCatalogService;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with document and metadata repositories.
    /// </summary>
    public DocumentMetadataService(
        IDocumentRepository documentRepository,
        IDocumentMetadataRepository documentMetadataRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository,
        DocumentTypeCatalogService documentTypeCatalogService,
        DocumentMetadataSchemaValidator documentMetadataSchemaValidator)
    {
        _documentRepository = documentRepository;
        _documentMetadataRepository = documentMetadataRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
        _documentTypeCatalogService = documentTypeCatalogService;
        _documentMetadataSchemaValidator = documentMetadataSchemaValidator;
    }

    /// <summary>
    /// Returns the current metadata object for a document when it belongs to the tenant.
    /// </summary>
    public async Task<DocumentMetadataSnapshot?> GetByDocumentIdAsync(
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

        var metadataJson = await _documentMetadataRepository.GetByDocumentIdAsync(
            tenantId,
            documentId,
            cancellationToken);
        using var normalizedDocument = JsonDocument.Parse(
            string.IsNullOrWhiteSpace(metadataJson) ? "{}" : metadataJson);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "DOCUMENT_METADATA_READ",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                document.DocumentTypeCode,
                HasMetadata = !string.IsNullOrWhiteSpace(metadataJson)
            }),
            cancellationToken);

        return new DocumentMetadataSnapshot(
            document.Id,
            JsonDocument.Parse(normalizedDocument.RootElement.GetRawText()));
    }

    /// <summary>
    /// Validates and replaces the current metadata object of a document.
    /// </summary>
    public async Task<DocumentMetadataSnapshot?> UpdateAsync(
        Guid tenantId,
        Guid documentId,
        string metadataJson,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);

        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            return null;
        }

        var documentType = await _documentTypeCatalogService.GetRequiredByCodeAsync(
            tenantId,
            document.DocumentTypeCode,
            cancellationToken);
        var normalizedMetadataJson = _documentMetadataSchemaValidator.ValidateAndNormalize(
            metadataJson,
            documentType) ?? "{}";

        await _documentMetadataRepository.UpsertAsync(
            tenantId,
            documentId,
            normalizedMetadataJson,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "DOCUMENT_METADATA_UPDATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                document.DocumentTypeCode,
                MetadataSize = normalizedMetadataJson.Length
            }),
            cancellationToken);

        return new DocumentMetadataSnapshot(
            document.Id,
            JsonDocument.Parse(normalizedMetadataJson));
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
            throw new DomainRuleException("No existe el tenant informado para consultar metadatos.");
        }
    }
}
