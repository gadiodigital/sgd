using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Documents;

namespace Gdms.Application.Documents;

/// <summary>
/// Coordinates explicit per-document ACL entries and authorization checks.
/// </summary>
public sealed class DocumentAccessService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentAccessRepository _documentAccessRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IUserRepository _userRepository;

    /// <summary>
    /// Initializes the service with document access dependencies.
    /// </summary>
    public DocumentAccessService(
        IDocumentAccessRepository documentAccessRepository,
        IDocumentRepository documentRepository,
        IUserRepository userRepository,
        ITenantRepository tenantRepository,
        IAuditEventRepository auditEventRepository)
    {
        _documentAccessRepository = documentAccessRepository;
        _documentRepository = documentRepository;
        _userRepository = userRepository;
        _tenantRepository = tenantRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists the explicit ACL entries configured for a document.
    /// </summary>
    public async Task<IReadOnlyCollection<DocumentAccessEntry>> ListAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        await EnsureDocumentExistsAsync(tenantId, documentId, cancellationToken);
        return await _documentAccessRepository.ListByDocumentAsync(
            tenantId,
            documentId,
            cancellationToken);
    }

    /// <summary>
    /// Grants an explicit ACL permission to a user for a document.
    /// </summary>
    public async Task<DocumentAccessEntry> GrantAsync(
        Guid tenantId,
        Guid documentId,
        Guid userId,
        string permissionCode,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        var document = await EnsureDocumentExistsAsync(tenantId, documentId, cancellationToken);
        var user = await _userRepository.GetByIdAsync(tenantId, userId, cancellationToken);
        if (user is null)
        {
            throw new DomainRuleException("No existe el usuario informado para la ACL documental.");
        }

        var permission = ParsePermission(permissionCode);
        var entry = DocumentAccessEntry.Create(
            tenantId,
            documentId,
            userId,
            permission,
            actorUserId,
            DateTimeOffset.UtcNow);
        var persistedEntry = await _documentAccessRepository.GrantAsync(
            entry,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "DOCUMENT_ACCESS_GRANTED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                document.Id,
                document.Title,
                TargetUserId = user.Id,
                user.Email,
                Permission = permission.ToString().ToUpperInvariant()
            }),
            cancellationToken);

        return persistedEntry;
    }

    /// <summary>
    /// Determines whether explicit ACL rules allow the requested operation.
    /// </summary>
    public async Task<bool> IsAuthorizedAsync(
        Guid tenantId,
        Guid documentId,
        Guid actorUserId,
        DocumentAccessPermission permission,
        CancellationToken cancellationToken)
    {
        await EnsureDocumentExistsAsync(tenantId, documentId, cancellationToken);
        var hasExplicitEntries = await _documentAccessRepository.HasExplicitEntriesAsync(
            tenantId,
            documentId,
            cancellationToken);
        if (!hasExplicitEntries)
        {
            return true;
        }

        return await _documentAccessRepository.UserHasPermissionAsync(
            tenantId,
            documentId,
            actorUserId,
            permission,
            cancellationToken);
    }

    private async Task<Domain.Documents.Document> EnsureDocumentExistsAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
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

        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado dentro del tenant.");
        }

        return document;
    }

    private static DocumentAccessPermission ParsePermission(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new DomainRuleException("El permiso ACL documental es obligatorio.");
        }

        if (Enum.TryParse<DocumentAccessPermission>(value.Trim(), true, out var permission))
        {
            return permission;
        }

        throw new DomainRuleException("El permiso ACL documental informado no es válido.");
    }
}
