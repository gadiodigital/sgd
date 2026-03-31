using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Corporate;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists corporate record files in PostgreSQL.
/// </summary>
public sealed class PostgresCorporateRecordFileRepository : ICorporateRecordFileRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresCorporateRecordFileRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<CorporateRecordFile>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                crf.corporate_record_file_id,
                crf.tenant_id,
                crf.code,
                crf.title,
                crf.category,
                crf.owner_area,
                crf.status,
                crf.created_by_user_id,
                crf.created_at_utc
            FROM documents.corporate_record_files crf
            WHERE crf.tenant_id = @tenant_id
            ORDER BY crf.created_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadCorporateRecordFilesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<CorporateRecordFile?> GetByIdAsync(Guid tenantId, Guid corporateRecordFileId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                corporate_record_file_id,
                tenant_id,
                code,
                title,
                category,
                owner_area,
                status,
                created_by_user_id,
                created_at_utc
            FROM documents.corporate_record_files
            WHERE tenant_id = @tenant_id
              AND corporate_record_file_id = @corporate_record_file_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("corporate_record_file_id", corporateRecordFileId);
        return (await ReadCorporateRecordFilesAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<CorporateRecordFile> AddAsync(CorporateRecordFile corporateRecordFile, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.corporate_record_files
                (corporate_record_file_id, tenant_id, code, title, category, owner_area, status, created_by_user_id, created_at_utc)
            VALUES
                (@corporate_record_file_id, @tenant_id, @code, @title, @category, @owner_area, @status, @created_by_user_id, @created_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("corporate_record_file_id", corporateRecordFile.Id);
        command.Parameters.AddWithValue("tenant_id", corporateRecordFile.TenantId);
        command.Parameters.AddWithValue("code", corporateRecordFile.Code);
        command.Parameters.AddWithValue("title", corporateRecordFile.Title);
        command.Parameters.AddWithValue("category", corporateRecordFile.Category);
        command.Parameters.AddWithValue("owner_area", corporateRecordFile.OwnerArea);
        command.Parameters.AddWithValue("status", corporateRecordFile.Status.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("created_by_user_id", (object?)corporateRecordFile.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", corporateRecordFile.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return corporateRecordFile;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<CorporateRecordFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                crfd.corporate_record_file_id,
                crfd.document_id,
                d.tenant_id,
                d.title,
                dt.code,
                d.status,
                crfd.linked_at_utc,
                crfd.linked_by_user_id
            FROM documents.corporate_record_file_documents crfd
            INNER JOIN documents.documents d ON d.document_id = crfd.document_id
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            WHERE crfd.corporate_record_file_id = @corporate_record_file_id
              AND d.tenant_id = @tenant_id
            ORDER BY crfd.linked_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("corporate_record_file_id", corporateRecordFileId);
        return await ReadCorporateRecordFileDocumentsAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid corporateRecordFileId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.corporate_record_file_documents
                (corporate_record_file_document_id, corporate_record_file_id, document_id, linked_by_user_id, linked_at_utc)
            SELECT
                @corporate_record_file_document_id,
                @corporate_record_file_id,
                @document_id,
                @linked_by_user_id,
                @linked_at_utc
            WHERE EXISTS (
                SELECT 1
                FROM documents.corporate_record_files crf
                WHERE crf.corporate_record_file_id = @corporate_record_file_id
                  AND crf.tenant_id = @tenant_id)
              AND EXISTS (
                SELECT 1
                FROM documents.documents d
                WHERE d.document_id = @document_id
                  AND d.tenant_id = @tenant_id)
            ON CONFLICT (corporate_record_file_id, document_id) DO NOTHING;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("corporate_record_file_document_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("corporate_record_file_id", corporateRecordFileId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("linked_by_user_id", (object?)linkedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("linked_at_utc", linkedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<CorporateRecordFile>> ReadCorporateRecordFilesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<CorporateRecordFile>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(CorporateRecordFile.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                Enum.Parse<CorporateRecordFileStatus>(reader.GetString(6), ignoreCase: true),
                reader.IsDBNull(7) ? null : reader.GetGuid(7),
                reader.GetFieldValue<DateTimeOffset>(8)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<CorporateRecordFileDocumentLink>> ReadCorporateRecordFileDocumentsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<CorporateRecordFileDocumentLink>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(CorporateRecordFileDocumentLink.Rehydrate(
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
