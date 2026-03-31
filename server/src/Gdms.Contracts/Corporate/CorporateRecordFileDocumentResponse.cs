namespace Gdms.Contracts.Corporate;

/// <summary>
/// Describes a document linked to a corporate record file.
/// </summary>
public sealed record CorporateRecordFileDocumentResponse(
    Guid CorporateRecordFileId,
    Guid DocumentId,
    Guid TenantId,
    string DocumentTitle,
    string DocumentTypeCode,
    string DocumentStatus,
    DateTimeOffset LinkedAtUtc,
    Guid? LinkedByUserId);
