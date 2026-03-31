namespace Gdms.Contracts.Records;

/// <summary>
/// Represents a legal hold returned by the public API.
/// </summary>
public sealed record LegalHoldResponse(
    Guid Id,
    Guid TenantId,
    Guid? DocumentId,
    string Reason,
    bool IsActive,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc,
    Guid? ReleasedByUserId,
    DateTimeOffset? ReleasedAtUtc,
    string? ReleaseReason);
