namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for immutable audit events.
/// </summary>
public interface IAuditEventRepository
{
    /// <summary>
    /// Lists the most recent audit events across the platform.
    /// </summary>
    Task<IReadOnlyCollection<AuditEventEntry>> ListRecentAsync(
        int limit,
        CancellationToken cancellationToken);

    /// <summary>
    /// Lists the most recent audit events for a tenant.
    /// </summary>
    Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByTenantAsync(
        Guid tenantId,
        int limit,
        CancellationToken cancellationToken);

    /// <summary>
    /// Lists the most recent audit events linked to a document.
    /// </summary>
    Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        int limit,
        CancellationToken cancellationToken);

    /// <summary>
    /// Persists an audit event for a tenant-scoped operation.
    /// </summary>
    Task WriteAsync(
        Guid tenantId,
        Guid? actorUserId,
        Guid? documentId,
        string eventType,
        string severity,
        string payloadJson,
        CancellationToken cancellationToken);
}
