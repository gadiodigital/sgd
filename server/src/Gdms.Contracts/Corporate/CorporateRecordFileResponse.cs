namespace Gdms.Contracts.Corporate;

/// <summary>
/// Describes a corporate record file returned by the API.
/// </summary>
public sealed record CorporateRecordFileResponse(
    Guid Id,
    Guid TenantId,
    string Code,
    string Title,
    string Category,
    string OwnerArea,
    string Status,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
