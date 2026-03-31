namespace Gdms.Contracts.Cases;

/// <summary>
/// Represents a case file returned by the API.
/// </summary>
public sealed record CaseFileResponse(
    Guid Id,
    Guid TenantId,
    string Code,
    string Title,
    string Category,
    string Status,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
