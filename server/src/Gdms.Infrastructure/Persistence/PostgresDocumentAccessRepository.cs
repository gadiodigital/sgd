using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Documents;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists explicit per-document ACL entries in PostgreSQL.
/// </summary>
public sealed class PostgresDocumentAccessRepository : IDocumentAccessRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresDocumentAccessRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<DocumentAccessEntry>> ListByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                document_access_entry_id,
                tenant_id,
                document_id,
                user_id,
                permission_code,
                granted_by_user_id,
                granted_at_utc
            FROM documents.document_access_entries
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id
            ORDER BY granted_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        return await ReadEntriesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<DocumentAccessEntry> GrantAsync(
        DocumentAccessEntry entry,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.document_access_entries
                (document_access_entry_id, tenant_id, document_id, user_id, permission_code, granted_by_user_id, granted_at_utc)
            VALUES
                (@document_access_entry_id, @tenant_id, @document_id, @user_id, @permission_code, @granted_by_user_id, @granted_at_utc)
            ON CONFLICT (document_id, user_id, permission_code) DO UPDATE
            SET granted_by_user_id = EXCLUDED.granted_by_user_id,
                granted_at_utc = EXCLUDED.granted_at_utc
            RETURNING document_access_entry_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("document_access_entry_id", entry.Id);
        command.Parameters.AddWithValue("tenant_id", entry.TenantId);
        command.Parameters.AddWithValue("document_id", entry.DocumentId);
        command.Parameters.AddWithValue("user_id", entry.UserId);
        command.Parameters.AddWithValue("permission_code", entry.Permission.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("granted_by_user_id", (object?)entry.GrantedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("granted_at_utc", entry.GrantedAtUtc);
        await command.ExecuteScalarAsync(cancellationToken);
        return entry;
    }

    /// <inheritdoc />
    public async Task<bool> UserHasPermissionAsync(
        Guid tenantId,
        Guid documentId,
        Guid userId,
        DocumentAccessPermission permission,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM documents.document_access_entries
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id
              AND user_id = @user_id
              AND permission_code = @permission_code
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("user_id", userId);
        command.Parameters.AddWithValue("permission_code", permission.ToString().ToUpperInvariant());
        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    /// <inheritdoc />
    public async Task<bool> HasExplicitEntriesAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM documents.document_access_entries
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    private static async Task<IReadOnlyCollection<DocumentAccessEntry>> ReadEntriesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<DocumentAccessEntry>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(DocumentAccessEntry.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetGuid(3),
                Enum.Parse<DocumentAccessPermission>(reader.GetString(4), true),
                reader.IsDBNull(5) ? null : reader.GetGuid(5),
                reader.GetFieldValue<DateTimeOffset>(6)));
        }

        return result;
    }
}
