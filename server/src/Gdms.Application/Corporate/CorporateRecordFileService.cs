using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Corporate;

namespace Gdms.Application.Corporate;

/// <summary>
/// Coordinates creation and lookup of corporate record files.
/// </summary>
public sealed class CorporateRecordFileService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly ICorporateRecordFileRepository _corporateRecordFileRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with corporate dependencies.
    /// </summary>
    public CorporateRecordFileService(
        ICorporateRecordFileRepository corporateRecordFileRepository,
        IDocumentRepository documentRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository)
    {
        _corporateRecordFileRepository = corporateRecordFileRepository;
        _documentRepository = documentRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists corporate record files of an organization.
    /// </summary>
    public async Task<IReadOnlyCollection<CorporateRecordFile>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _corporateRecordFileRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Lists documents linked to a corporate record file.
    /// </summary>
    public async Task<IReadOnlyCollection<CorporateRecordFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        CancellationToken cancellationToken)
    {
        await EnsureCorporateRecordFileExistsAsync(tenantId, corporateRecordFileId, cancellationToken);
        return await _corporateRecordFileRepository.ListDocumentsAsync(tenantId, corporateRecordFileId, cancellationToken);
    }

    /// <summary>
    /// Creates a new corporate record file inside an organization.
    /// </summary>
    public async Task<CorporateRecordFile> CreateAsync(
        Guid tenantId,
        string code,
        string title,
        string category,
        string ownerArea,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var corporateRecordFile = CorporateRecordFile.Create(
            tenantId,
            code,
            title,
            category,
            ownerArea,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persistedCorporateRecordFile = await _corporateRecordFileRepository.AddAsync(corporateRecordFile, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            "CORPORATE_RECORD_FILE_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedCorporateRecordFile.Id,
                persistedCorporateRecordFile.Code,
                persistedCorporateRecordFile.Title,
                persistedCorporateRecordFile.Category,
                persistedCorporateRecordFile.OwnerArea
            }),
            cancellationToken);

        return persistedCorporateRecordFile;
    }

    /// <summary>
    /// Links an existing document to an existing corporate record file.
    /// </summary>
    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        Guid documentId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var corporateRecordFile = await EnsureCorporateRecordFileExistsAsync(tenantId, corporateRecordFileId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant del legajo corporativo.");
        }

        await _corporateRecordFileRepository.AttachDocumentAsync(
            tenantId,
            corporateRecordFileId,
            documentId,
            actorUserId,
            DateTimeOffset.UtcNow,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "CORPORATE_RECORD_FILE_DOCUMENT_ATTACHED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                corporateRecordFile.Id,
                corporateRecordFile.Code,
                DocumentId = document.Id,
                document.Title
            }),
            cancellationToken);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para legajos corporativos.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para legajos corporativos.");
        }
    }

    private async Task<CorporateRecordFile> EnsureCorporateRecordFileExistsAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        if (corporateRecordFileId == Guid.Empty)
        {
            throw new DomainRuleException("El legajo corporativo informado es obligatorio.");
        }

        var corporateRecordFile = await _corporateRecordFileRepository.GetByIdAsync(tenantId, corporateRecordFileId, cancellationToken);
        if (corporateRecordFile is null)
        {
            throw new DomainRuleException("No existe el legajo corporativo informado para el tenant.");
        }

        return corporateRecordFile;
    }
}
