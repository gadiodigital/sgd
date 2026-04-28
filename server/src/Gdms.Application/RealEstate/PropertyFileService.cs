using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.RealEstate;

namespace Gdms.Application.RealEstate;

/// <summary>
/// Coordinates creation and lookup of real-estate property files.
/// </summary>
public sealed class PropertyFileService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly IPropertyFileRepository _propertyFileRepository;
    private readonly ITenantRepository _tenantRepository;

    /// <summary>
    /// Initializes the service with real-estate dependencies.
    /// </summary>
    public PropertyFileService(
        IPropertyFileRepository propertyFileRepository,
        IDocumentRepository documentRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository)
    {
        _propertyFileRepository = propertyFileRepository;
        _documentRepository = documentRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists property files of an organization.
    /// </summary>
    public async Task<IReadOnlyCollection<PropertyFile>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _propertyFileRepository.ListByTenantAsync(tenantId, cancellationToken);
    }

    /// <summary>
    /// Lists documents linked to a property file.
    /// </summary>
    public async Task<IReadOnlyCollection<PropertyFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid propertyFileId,
        CancellationToken cancellationToken)
    {
        await EnsurePropertyFileExistsAsync(tenantId, propertyFileId, cancellationToken);
        return await _propertyFileRepository.ListDocumentsAsync(tenantId, propertyFileId, cancellationToken);
    }

    /// <summary>
    /// Creates a new property file inside an organization.
    /// </summary>
    public async Task<PropertyFile> CreateAsync(
        Guid tenantId,
        string code,
        string title,
        string address,
        string operationType,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var propertyFile = PropertyFile.Create(
            tenantId,
            code,
            title,
            address,
            operationType,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persistedPropertyFile = await _propertyFileRepository.AddAsync(propertyFile, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            null,
            "PROPERTY_FILE_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedPropertyFile.Id,
                persistedPropertyFile.Code,
                persistedPropertyFile.Title,
                persistedPropertyFile.Address,
                persistedPropertyFile.OperationType
            }),
            cancellationToken);

        return persistedPropertyFile;
    }

    /// <summary>
    /// Links an existing document to an existing property file.
    /// </summary>
    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid propertyFileId,
        Guid documentId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var propertyFile = await EnsurePropertyFileExistsAsync(tenantId, propertyFileId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant del legajo inmobiliario.");
        }

        await _propertyFileRepository.AttachDocumentAsync(
            tenantId,
            propertyFileId,
            documentId,
            actorUserId,
            DateTimeOffset.UtcNow,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "PROPERTY_FILE_DOCUMENT_ATTACHED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                propertyFile.Id,
                propertyFile.Code,
                DocumentId = document.Id,
                document.Title
            }),
            cancellationToken);
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para legajos inmobiliarios.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para legajos inmobiliarios.");
        }
    }

    private async Task<PropertyFile> EnsurePropertyFileExistsAsync(
        Guid tenantId,
        Guid propertyFileId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        if (propertyFileId == Guid.Empty)
        {
            throw new DomainRuleException("El legajo inmobiliario informado es obligatorio.");
        }

        var propertyFile = await _propertyFileRepository.GetByIdAsync(tenantId, propertyFileId, cancellationToken);
        if (propertyFile is null)
        {
            throw new DomainRuleException("No existe el legajo inmobiliario informado para el tenant.");
        }

        return propertyFile;
    }
}
