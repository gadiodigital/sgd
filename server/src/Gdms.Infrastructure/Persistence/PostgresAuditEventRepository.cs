using Gdms.Application.Abstractions.Persistence;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists immutable audit events in PostgreSQL.
/// </summary>
public sealed class PostgresAuditEventRepository : IAuditEventRepository
{
    private readonly NpgsqlDataSource _dataSource;
    private const string SelectProjection = """
        SELECT
            ae.audit_event_id,
            ae.tenant_id,
            t.code,
            ae.actor_user_id,
            ae.document_id,
            ae.event_type,
            ae.severity,
            ae.occurred_at_utc
        FROM audit.audit_events ae
        INNER JOIN platform.tenants t ON t.tenant_id = ae.tenant_id
        """;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresAuditEventRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<AuditEventEntry>> ListRecentAsync(
        int limit,
        CancellationToken cancellationToken)
    {
        var sql = $"{SelectProjection} ORDER BY ae.occurred_at_utc DESC LIMIT @limit;";
        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("limit", limit);
        return await ReadEntriesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByTenantAsync(
        Guid tenantId,
        int limit,
        CancellationToken cancellationToken)
    {
        var sql = $"{SelectProjection} WHERE ae.tenant_id = @tenant_id ORDER BY ae.occurred_at_utc DESC LIMIT @limit;";
        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("limit", limit);
        return await ReadEntriesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<AuditEventEntry>> ListRecentByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        int limit,
        CancellationToken cancellationToken)
    {
        var sql = $"{SelectProjection} WHERE ae.tenant_id = @tenant_id AND ae.document_id = @document_id ORDER BY ae.occurred_at_utc DESC LIMIT @limit;";
        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("limit", limit);
        return await ReadEntriesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task WriteAsync(
        Guid tenantId,
        Guid? actorUserId,
        Guid? documentId,
        string eventType,
        string severity,
        string payloadJson,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO audit.audit_events
                (tenant_id, actor_user_id, document_id, event_type, severity, payload, occurred_at_utc)
            VALUES
                (@tenant_id, @actor_user_id, @document_id, @event_type, @severity, CAST(@payload AS jsonb), @occurred_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("actor_user_id", (object?)actorUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("document_id", (object?)documentId ?? DBNull.Value);
        command.Parameters.AddWithValue("event_type", eventType.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue("severity", severity.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue("payload", payloadJson);
        command.Parameters.AddWithValue("occurred_at_utc", DateTimeOffset.UtcNow);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<AuditEventEntry>> ReadEntriesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<AuditEventEntry>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new AuditEventEntry(
                reader.GetInt64(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.IsDBNull(3) ? null : reader.GetGuid(3),
                reader.IsDBNull(4) ? null : reader.GetGuid(4),
                reader.GetString(5),
                reader.GetString(6),
                reader.GetFieldValue<DateTimeOffset>(7)));
        }

        return result;
    }
}
