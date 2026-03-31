using Gdms.Domain.Common;

namespace Gdms.Domain.Documents;

/// <summary>
/// Represents an explicit access entry granted to a tenant user for a document.
/// </summary>
public sealed class DocumentAccessEntry
{
    private DocumentAccessEntry(
        Guid id,
        Guid tenantId,
        Guid documentId,
        Guid userId,
        DocumentAccessPermission permission,
        Guid? grantedByUserId,
        DateTimeOffset grantedAtUtc)
    {
        Id = id == Guid.Empty
            ? throw new DomainRuleException("La entrada ACL del documento debe tener identificador.")
            : id;
        TenantId = tenantId == Guid.Empty
            ? throw new DomainRuleException("El tenant de la ACL documental es obligatorio.")
            : tenantId;
        DocumentId = documentId == Guid.Empty
            ? throw new DomainRuleException("El documento de la ACL es obligatorio.")
            : documentId;
        UserId = userId == Guid.Empty
            ? throw new DomainRuleException("El usuario de la ACL documental es obligatorio.")
            : userId;
        Permission = permission;
        GrantedByUserId = grantedByUserId;
        GrantedAtUtc = grantedAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public Guid DocumentId { get; }
    public Guid UserId { get; }
    public DocumentAccessPermission Permission { get; }
    public Guid? GrantedByUserId { get; }
    public DateTimeOffset GrantedAtUtc { get; }

    /// <summary>
    /// Creates a new document access entry.
    /// </summary>
    public static DocumentAccessEntry Create(
        Guid tenantId,
        Guid documentId,
        Guid userId,
        DocumentAccessPermission permission,
        Guid? grantedByUserId,
        DateTimeOffset grantedAtUtc)
    {
        return new DocumentAccessEntry(
            Guid.NewGuid(),
            tenantId,
            documentId,
            userId,
            permission,
            grantedByUserId,
            grantedAtUtc);
    }

    /// <summary>
    /// Rehydrates a persisted document access entry.
    /// </summary>
    public static DocumentAccessEntry Rehydrate(
        Guid id,
        Guid tenantId,
        Guid documentId,
        Guid userId,
        DocumentAccessPermission permission,
        Guid? grantedByUserId,
        DateTimeOffset grantedAtUtc)
    {
        return new DocumentAccessEntry(
            id,
            tenantId,
            documentId,
            userId,
            permission,
            grantedByUserId,
            grantedAtUtc);
    }
}
