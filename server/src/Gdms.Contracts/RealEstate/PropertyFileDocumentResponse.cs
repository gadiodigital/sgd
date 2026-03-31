namespace Gdms.Contracts.RealEstate;

/// <summary>
/// Describes a document linked to a property file.
/// </summary>
public sealed record PropertyFileDocumentResponse(
    Guid PropertyFileId,
    Guid DocumentId,
    Guid TenantId,
    string DocumentTitle,
    string DocumentTypeCode,
    string DocumentStatus,
    DateTimeOffset LinkedAtUtc,
    Guid? LinkedByUserId);
