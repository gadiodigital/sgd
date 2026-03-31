namespace Gdms.Contracts.Cases;

/// <summary>
/// Represents a document linked to a case file.
/// </summary>
public sealed record CaseFileDocumentResponse(
    Guid CaseFileId,
    Guid DocumentId,
    Guid TenantId,
    string DocumentTitle,
    string DocumentTypeCode,
    string DocumentStatus,
    DateTimeOffset LinkedAtUtc,
    Guid? LinkedByUserId);
