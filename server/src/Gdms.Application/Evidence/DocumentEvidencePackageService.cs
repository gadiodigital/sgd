using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;

namespace Gdms.Application.Evidence;

/// <summary>
/// Builds exportable evidence packages for tenant-scoped documents.
/// </summary>
public sealed class DocumentEvidencePackageService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentMetadataRepository _documentMetadataRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ILegalHoldRepository _legalHoldRepository;
    private readonly ISignatureEnvelopeRepository _signatureEnvelopeRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IWorkflowTaskRepository _workflowTaskRepository;

    /// <summary>
    /// Initializes the service with repositories required by evidence export.
    /// </summary>
    public DocumentEvidencePackageService(
        ITenantRepository tenantRepository,
        IDocumentRepository documentRepository,
        IDocumentMetadataRepository documentMetadataRepository,
        IAuditEventRepository auditEventRepository,
        ILegalHoldRepository legalHoldRepository,
        IWorkflowTaskRepository workflowTaskRepository,
        ISignatureEnvelopeRepository signatureEnvelopeRepository)
    {
        _tenantRepository = tenantRepository;
        _documentRepository = documentRepository;
        _documentMetadataRepository = documentMetadataRepository;
        _auditEventRepository = auditEventRepository;
        _legalHoldRepository = legalHoldRepository;
        _workflowTaskRepository = workflowTaskRepository;
        _signatureEnvelopeRepository = signatureEnvelopeRepository;
    }

    /// <summary>
    /// Builds an evidence package for one document and writes an audit trail entry.
    /// </summary>
    public async Task<DocumentEvidencePackage> ExportAsync(
        Guid tenantId,
        Guid documentId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para exportar evidencia.");
        }

        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado para exportar evidencia.");
        }

        var metadataJson = await _documentMetadataRepository.GetByDocumentIdAsync(
            tenantId,
            documentId,
            cancellationToken);
        var auditEvents = await _auditEventRepository.ListRecentByDocumentAsync(
            tenantId,
            documentId,
            100,
            cancellationToken);
        var legalHolds = await _legalHoldRepository.ListByDocumentAsync(
            tenantId,
            documentId,
            cancellationToken);
        var workflowTasks = (await _workflowTaskRepository.ListByTenantAsync(
                tenantId,
                null,
                cancellationToken))
            .Where(item => item.DocumentId == documentId)
            .OrderBy(item => item.CreatedAtUtc)
            .ToArray();
        var signatures = (await _signatureEnvelopeRepository.ListByTenantAsync(
                tenantId,
                cancellationToken))
            .Where(item => item.DocumentId == documentId)
            .OrderBy(item => item.RequestedAtUtc)
            .ToArray();
        var exportedAtUtc = DateTimeOffset.UtcNow;

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "EVIDENCE_PACKAGE_EXPORTED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                documentId,
                exportedAtUtc
            }),
            cancellationToken);

        return new DocumentEvidencePackage(
            tenantId,
            documentId,
            document.DocumentTypeCode,
            document.Title,
            document.Status.ToString().ToUpperInvariant(),
            document.CreatedAtUtc,
            exportedAtUtc,
            document.Versions
                .Select(version => new DocumentEvidenceVersion(
                    version.Id,
                    version.VersionNumber,
                    version.StorageObjectKey,
                    version.MimeType,
                    version.FileHashSha256,
                    version.FileSizeBytes,
                    version.UploadedByUserId,
                    version.UploadedAtUtc))
                .ToArray(),
            DeserializeMetadata(metadataJson),
            auditEvents
                .Select(item => new DocumentEvidenceAuditEvent(
                    item.Id,
                    item.TenantCode,
                    item.ActorUserId,
                    item.EventType,
                    item.Severity,
                    item.OccurredAtUtc))
                .ToArray(),
            workflowTasks
                .Select(item => new DocumentEvidenceWorkflowTask(
                    item.Id,
                    item.Title,
                    item.Notes,
                    item.Status.ToString().ToUpperInvariant(),
                    item.CreatedByUserId,
                    item.CreatedAtUtc,
                    item.DueAtUtc,
                    item.CompletedByUserId,
                    item.CompletedAtUtc))
                .ToArray(),
            signatures
                .Select(item => new DocumentEvidenceSignature(
                    item.Id,
                    item.SignerDisplayName,
                    item.SignerEmail,
                    item.SignatureLevel,
                    item.ProviderCode,
                    item.ExternalReference,
                    item.Status.ToString().ToUpperInvariant(),
                    item.RequestedByUserId,
                    item.RequestedAtUtc,
                    item.DueAtUtc,
                    item.CompletedByUserId,
                    item.CompletedAtUtc))
                .ToArray(),
            legalHolds
                .Select(item => new DocumentEvidenceLegalHold(
                    item.Id,
                    item.Reason,
                    item.IsActive,
                    item.CreatedByUserId,
                    item.CreatedAtUtc,
                    item.ReleasedByUserId,
                    item.ReleasedAtUtc,
                    item.ReleaseReason))
                .ToArray());
    }

    private static IReadOnlyDictionary<string, object?> DeserializeMetadata(string? metadataJson)
    {
        if (string.IsNullOrWhiteSpace(metadataJson))
        {
            return new Dictionary<string, object?>();
        }

        var parsed = JsonSerializer.Deserialize<Dictionary<string, object?>>(metadataJson);
        return parsed ?? new Dictionary<string, object?>();
    }
}
