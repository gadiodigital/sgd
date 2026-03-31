using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.RealEstate;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists property files in PostgreSQL.
/// </summary>
public sealed class PostgresPropertyFileRepository : IPropertyFileRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresPropertyFileRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<PropertyFile>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                pf.property_file_id,
                pf.tenant_id,
                pf.code,
                pf.title,
                pf.address,
                pf.operation_type,
                pf.status,
                pf.created_by_user_id,
                pf.created_at_utc
            FROM documents.property_files pf
            WHERE pf.tenant_id = @tenant_id
            ORDER BY pf.created_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadPropertyFilesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<PropertyFile?> GetByIdAsync(Guid tenantId, Guid propertyFileId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                property_file_id,
                tenant_id,
                code,
                title,
                address,
                operation_type,
                status,
                created_by_user_id,
                created_at_utc
            FROM documents.property_files
            WHERE tenant_id = @tenant_id
              AND property_file_id = @property_file_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("property_file_id", propertyFileId);
        return (await ReadPropertyFilesAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<PropertyFile> AddAsync(PropertyFile propertyFile, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.property_files
                (property_file_id, tenant_id, code, title, address, operation_type, status, created_by_user_id, created_at_utc)
            VALUES
                (@property_file_id, @tenant_id, @code, @title, @address, @operation_type, @status, @created_by_user_id, @created_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("property_file_id", propertyFile.Id);
        command.Parameters.AddWithValue("tenant_id", propertyFile.TenantId);
        command.Parameters.AddWithValue("code", propertyFile.Code);
        command.Parameters.AddWithValue("title", propertyFile.Title);
        command.Parameters.AddWithValue("address", propertyFile.Address);
        command.Parameters.AddWithValue("operation_type", propertyFile.OperationType);
        command.Parameters.AddWithValue("status", propertyFile.Status.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("created_by_user_id", (object?)propertyFile.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", propertyFile.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return propertyFile;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<PropertyFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid propertyFileId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                pfd.property_file_id,
                pfd.document_id,
                d.tenant_id,
                d.title,
                dt.code,
                d.status,
                pfd.linked_at_utc,
                pfd.linked_by_user_id
            FROM documents.property_file_documents pfd
            INNER JOIN documents.documents d ON d.document_id = pfd.document_id
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            WHERE pfd.property_file_id = @property_file_id
              AND d.tenant_id = @tenant_id
            ORDER BY pfd.linked_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("property_file_id", propertyFileId);
        return await ReadPropertyFileDocumentsAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid propertyFileId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.property_file_documents
                (property_file_document_id, property_file_id, document_id, linked_by_user_id, linked_at_utc)
            SELECT
                @property_file_document_id,
                @property_file_id,
                @document_id,
                @linked_by_user_id,
                @linked_at_utc
            WHERE EXISTS (
                SELECT 1
                FROM documents.property_files pf
                WHERE pf.property_file_id = @property_file_id
                  AND pf.tenant_id = @tenant_id)
              AND EXISTS (
                SELECT 1
                FROM documents.documents d
                WHERE d.document_id = @document_id
                  AND d.tenant_id = @tenant_id)
            ON CONFLICT (property_file_id, document_id) DO NOTHING;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("property_file_document_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("property_file_id", propertyFileId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("linked_by_user_id", (object?)linkedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("linked_at_utc", linkedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<PropertyFile>> ReadPropertyFilesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<PropertyFile>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(PropertyFile.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                Enum.Parse<PropertyFileStatus>(reader.GetString(6), ignoreCase: true),
                reader.IsDBNull(7) ? null : reader.GetGuid(7),
                reader.GetFieldValue<DateTimeOffset>(8)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<PropertyFileDocumentLink>> ReadPropertyFileDocumentsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<PropertyFileDocumentLink>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(PropertyFileDocumentLink.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                reader.GetFieldValue<DateTimeOffset>(6),
                reader.IsDBNull(7) ? null : reader.GetGuid(7)));
        }

        return result;
    }
}
