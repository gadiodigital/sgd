using Gdms.Application.Abstractions.Persistence;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists the current metadata object associated with a document.
/// </summary>
public sealed class PostgresDocumentMetadataRepository : IDocumentMetadataRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresDocumentMetadataRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<string?> GetByDocumentIdAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT metadata::text
            FROM documents.document_metadata
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result as string;
    }

    /// <inheritdoc />
    public async Task UpsertAsync(
        Guid tenantId,
        Guid documentId,
        string metadataJson,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.document_metadata
                (document_id, tenant_id, metadata, updated_at_utc)
            VALUES
                (@document_id, @tenant_id, CAST(@metadata_json AS jsonb), timezone('utc', now()))
            ON CONFLICT (document_id) DO UPDATE
            SET metadata = EXCLUDED.metadata,
                updated_at_utc = EXCLUDED.updated_at_utc,
                tenant_id = EXCLUDED.tenant_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("metadata_json", metadataJson);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
