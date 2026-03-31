namespace Gdms.Contracts.Audit;

/// <summary>
/// Represents an audit event returned to API clients.
/// </summary>
public sealed record AuditEventResponse(
    long Id,
    Guid TenantId,
    string TenantCode,
    Guid? ActorUserId,
    Guid? DocumentId,
    string EventType,
    string Severity,
    DateTimeOffset OccurredAtUtc);
