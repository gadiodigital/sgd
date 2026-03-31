namespace Gdms.Contracts.Records;

/// <summary>
/// Represents a retention policy returned by the public API.
/// </summary>
public sealed record RetentionPolicyResponse(
    Guid Id,
    Guid? TenantId,
    string Code,
    string Name,
    int RetentionDays,
    string DispositionAction,
    bool IsActive);
