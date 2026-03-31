using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Cases;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists case files in PostgreSQL.
/// </summary>
public sealed class PostgresCaseFileRepository : ICaseFileRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresCaseFileRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<CaseFile>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                cf.case_file_id,
                cf.tenant_id,
                cf.code,
                cf.title,
                cf.category,
                cf.status,
                cf.created_by_user_id,
                cf.created_at_utc
            FROM documents.case_files cf
            WHERE tenant_id = @tenant_id
            ORDER BY cf.created_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadCaseFilesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<CaseFile?> GetByIdAsync(Guid tenantId, Guid caseFileId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                case_file_id,
                tenant_id,
                code,
                title,
                category,
                status,
                created_by_user_id,
                created_at_utc
            FROM documents.case_files
            WHERE tenant_id = @tenant_id
              AND case_file_id = @case_file_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("case_file_id", caseFileId);
        return (await ReadCaseFilesAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<CaseFile> AddAsync(CaseFile caseFile, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.case_files
                (case_file_id, tenant_id, code, title, category, status, created_by_user_id, created_at_utc)
            VALUES
                (@case_file_id, @tenant_id, @code, @title, @category, @status, @created_by_user_id, @created_at_utc);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("case_file_id", caseFile.Id);
        command.Parameters.AddWithValue("tenant_id", caseFile.TenantId);
        command.Parameters.AddWithValue("code", caseFile.Code);
        command.Parameters.AddWithValue("title", caseFile.Title);
        command.Parameters.AddWithValue("category", caseFile.Category);
        command.Parameters.AddWithValue("status", caseFile.Status.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("created_by_user_id", (object?)caseFile.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", caseFile.CreatedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return caseFile;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<CaseFileDocumentLink>> ListDocumentsAsync(
        Guid tenantId,
        Guid caseFileId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                cfd.case_file_id,
                cfd.document_id,
                d.tenant_id,
                d.title,
                dt.code,
                d.status,
                cfd.linked_at_utc,
                cfd.linked_by_user_id
            FROM documents.case_file_documents cfd
            INNER JOIN documents.documents d ON d.document_id = cfd.document_id
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            WHERE cfd.case_file_id = @case_file_id
              AND d.tenant_id = @tenant_id
            ORDER BY cfd.linked_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("case_file_id", caseFileId);
        return await ReadCaseFileDocumentsAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task AttachDocumentAsync(
        Guid tenantId,
        Guid caseFileId,
        Guid documentId,
        Guid? linkedByUserId,
        DateTimeOffset linkedAtUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO documents.case_file_documents
                (case_file_document_id, case_file_id, document_id, linked_by_user_id, linked_at_utc)
            SELECT
                @case_file_document_id,
                @case_file_id,
                @document_id,
                @linked_by_user_id,
                @linked_at_utc
            WHERE EXISTS (
                SELECT 1
                FROM documents.case_files cf
                WHERE cf.case_file_id = @case_file_id
                  AND cf.tenant_id = @tenant_id)
              AND EXISTS (
                SELECT 1
                FROM documents.documents d
                WHERE d.document_id = @document_id
                  AND d.tenant_id = @tenant_id)
            ON CONFLICT (case_file_id, document_id) DO NOTHING;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("case_file_document_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("case_file_id", caseFileId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("linked_by_user_id", (object?)linkedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("linked_at_utc", linkedAtUtc);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<CaseFile>> ReadCaseFilesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<CaseFile>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(CaseFile.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetString(4),
                Enum.Parse<CaseFileStatus>(reader.GetString(5), ignoreCase: true),
                reader.IsDBNull(6) ? null : reader.GetGuid(6),
                reader.GetFieldValue<DateTimeOffset>(7)));
        }

        return result;
    }

    private static async Task<IReadOnlyCollection<CaseFileDocumentLink>> ReadCaseFileDocumentsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<CaseFileDocumentLink>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(CaseFileDocumentLink.Rehydrate(
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
