namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Represents one persisted audit event projected for read operations.
/// </summary>
public sealed record AuditEventEntry(
    long Id,
    Guid TenantId,
    string TenantCode,
    Guid? ActorUserId,
    Guid? DocumentId,
    string EventType,
    string Severity,
    DateTimeOffset OccurredAtUtc);
