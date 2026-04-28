using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Cases;
using Gdms.Domain.Common;

namespace Gdms.Application.Cases;

/// <summary>
/// Coordinates creation and lookup of case files.
/// </summary>
public sealed class CaseFileService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly ICaseFileRepository _caseFileRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with case file dependencies.
    /// </summary>
    public CaseFileService(
        ICaseFileRepository caseFileRepository,
        IDocumentRepository documentRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository)
    {
        _caseFileRepository = caseFileRepository;
        _documentRepository = documentRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists case files of an organization.
    /// </summary>
    public async Task<IReadOnlyCollection<CaseFile>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _caseFileRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Lists documents linked to a case file.
    /// </summary>
    public async Task<IReadOnlyCollection<CaseFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid caseFileId,
        CancellationToken cancellationToken)
    {
        await EnsureCaseFileExistsAsync(tenantId, caseFileId, cancellationToken);
        return await _caseFileRepository.ListDocumentsAsync(tenantId, caseFileId, cancellationToken);
    }

    /// <summary>
    /// Creates a new case file inside an organization.
    /// </summary>
    public async Task<CaseFile> CreateAsync(
        Guid tenantId,
        string code,
        string title,
        string category,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var caseFile = CaseFile.Create(
            tenantId,
            code,
            title,
            category,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persistedCaseFile = await _caseFileRepository.AddAsync(caseFile, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            "CASE_FILE_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedCaseFile.Id,
                persistedCaseFile.Code,
                persistedCaseFile.Title,
                persistedCaseFile.Category
            }),
            cancellationToken);

        return persistedCaseFile;
    }

    /// <summary>
    /// Links an existing document to an existing case file.
    /// </summary>
    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid caseFileId,
        Guid documentId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var caseFile = await EnsureCaseFileExistsAsync(tenantId, caseFileId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant del expediente.");
        }

        await _caseFileRepository.AttachDocumentAsync(
            tenantId,
            caseFileId,
            documentId,
            actorUserId,
            DateTimeOffset.UtcNow,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "CASE_FILE_DOCUMENT_ATTACHED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                caseFile.Id,
                caseFile.Code,
                DocumentId = document.Id,
                document.Title
            }),
            cancellationToken);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para expedientes.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para expedientes.");
        }
    }

    private async Task<CaseFile> EnsureCaseFileExistsAsync(
        Guid tenantId,
        Guid caseFileId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        if (caseFileId == Guid.Empty)
        {
            throw new DomainRuleException("El expediente informado es obligatorio.");
        }

        var caseFile = await _caseFileRepository.GetByIdAsync(tenantId, caseFileId, cancellationToken);
        if (caseFile is null)
        {
            throw new DomainRuleException("No existe el expediente informado para el tenant.");
        }

        return caseFile;
    }
}
