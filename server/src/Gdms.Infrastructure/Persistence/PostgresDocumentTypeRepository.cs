using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Documents;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Reads tenant-visible document types and their metadata schema from PostgreSQL.
/// </summary>
public sealed class PostgresDocumentTypeRepository : IDocumentTypeRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresDocumentTypeRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<DocumentTypeDefinition>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            WITH visible_document_types AS
            (
                SELECT DISTINCT ON (code)
                    document_type_id,
                    tenant_id,
                    code,
                    name,
                    sector,
                    is_active,
                    metadata_schema
                FROM configuration.document_types
                WHERE is_active = TRUE
                  AND (tenant_id IS NULL OR tenant_id = @tenant_id)
                ORDER BY
                    code,
                    CASE WHEN tenant_id = @tenant_id THEN 0 ELSE 1 END,
                    created_at_utc DESC
            )
            SELECT
                document_type_id,
                tenant_id,
                code,
                name,
                sector,
                is_active,
                metadata_schema
            FROM visible_document_types
            ORDER BY code;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadDefinitionsAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<DocumentTypeDefinition?> GetByCodeAsync(
        Guid tenantId,
        string documentTypeCode,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                document_type_id,
                tenant_id,
                code,
                name,
                sector,
                is_active,
                metadata_schema
            FROM configuration.document_types
            WHERE is_active = TRUE
              AND code = @code
              AND (tenant_id IS NULL OR tenant_id = @tenant_id)
            ORDER BY
                CASE WHEN tenant_id = @tenant_id THEN 0 ELSE 1 END,
                created_at_utc DESC
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("code", documentTypeCode.Trim().ToUpperInvariant());
        return (await ReadDefinitionsAsync(command, cancellationToken)).SingleOrDefault();
    }

    private static async Task<IReadOnlyCollection<DocumentTypeDefinition>> ReadDefinitionsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var result = new List<DocumentTypeDefinition>();

        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(new DocumentTypeDefinition(
                reader.GetGuid(0),
                reader.IsDBNull(1) ? null : reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetBoolean(5),
                JsonDocument.Parse(reader.GetFieldValue<string>(6))));
        }

        return result;
    }
}
