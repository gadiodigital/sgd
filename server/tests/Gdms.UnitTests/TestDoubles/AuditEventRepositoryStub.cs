namespace Gdms.UnitTests.TestDoubles;

internal sealed class AuditEventRepositoryStub : IAuditEventRepository
{
    public List<AuditWriteCall> Writes { get; } = [];

    public Task<IReadOnlyCollection<AuditEventEntry>> ListRecentAsync(int limit, CancellationToken cancellationToken)
    {
        return Task.FromResult<IReadOnlyCollection<AuditEventEntry>>([]);
    }

    public Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByTenantAsync(
        Guid tenantId,
        int limit,
        CancellationToken cancellationToken)
    {
        return Task.FromResult<IReadOnlyCollection<AuditEventEntry>>([]);
    }

    public Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        int limit,
        CancellationToken cancellationToken)
    {
        return Task.FromResult<IReadOnlyCollection<AuditEventEntry>>([]);
    }

    public Task WriteAsync(
        Guid tenantId,
        Guid? actorUserId,
        Guid? documentId,
        string eventType,
        string severity,
        string payloadJson,
        CancellationToken cancellationToken)
    {
        Writes.Add(new AuditWriteCall(tenantId, actorUserId, documentId, eventType, severity, payloadJson));
        return Task.CompletedTask;
    }
}

internal sealed record AuditWriteCall(
    Guid TenantId,
    Guid? ActorUserId,
    Guid? DocumentId,
    string EventType,
    string Severity,
    string PayloadJson);
