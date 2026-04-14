namespace Gdms.Contracts.Structure;

/// <summary>
/// Document linked to a hierarchy node.
/// </summary>
public sealed record ContainerDocumentResponse(
    Guid ContainerId,
    Guid DocumentId,
    Guid TenantId,
    string DocumentTitle,
    string DocumentTypeCode,
    string DocumentStatus,
    DateTimeOffset LinkedAtUtc,
    Guid? LinkedByUserId);
