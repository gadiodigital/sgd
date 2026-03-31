using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Documents;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Executes tenant-scoped document searches in PostgreSQL.
/// </summary>
public sealed class PostgresDocumentSearchRepository : IDocumentSearchRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresDocumentSearchRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<Document>> SearchAsync(
        Guid tenantId,
        string? query,
        string? documentTypeCode,
        DocumentStatus? status,
        bool? onLegalHold,
        int limit,
        CancellationToken cancellationToken)
    {
        const string sql = """
            WITH matched_documents AS (
                SELECT d.document_id
                FROM documents.documents d
                INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
                WHERE d.tenant_id = @tenant_id
                  AND (
                    @query IS NULL
                    OR d.title ILIKE '%' || @query || '%'
                    OR dt.code ILIKE '%' || @query || '%'
                  )
                  AND (@document_type_code IS NULL OR dt.code = @document_type_code)
                  AND (@status IS NULL OR d.status = @status)
                  AND (
                    @on_legal_hold IS NULL
                    OR (@on_legal_hold = TRUE AND EXISTS (
                        SELECT 1
                        FROM records.legal_holds lh
                        WHERE lh.document_id = d.document_id
                          AND lh.is_active = TRUE))
                    OR (@on_legal_hold = FALSE AND NOT EXISTS (
                        SELECT 1
                        FROM records.legal_holds lh
                        WHERE lh.document_id = d.document_id
                          AND lh.is_active = TRUE))
                  )
                ORDER BY d.created_at_utc DESC
                LIMIT @limit
            )
            SELECT
                d.document_id,
                d.tenant_id,
                dt.code,
                d.title,
                d.status,
                d.created_at_utc,
                dv.document_version_id,
                dv.version_number,
                dv.storage_object_key,
                dv.mime_type,
                dv.file_hash_sha256,
                dv.file_size_bytes,
                dv.uploaded_by_user_id,
                dv.uploaded_at_utc
            FROM matched_documents md
            INNER JOIN documents.documents d ON d.document_id = md.document_id
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            LEFT JOIN documents.document_versions dv ON dv.document_id = d.document_id
            ORDER BY d.created_at_utc DESC, dv.version_number;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("query", string.IsNullOrWhiteSpace(query) ? DBNull.Value : query.Trim());
        command.Parameters.AddWithValue(
            "document_type_code",
            string.IsNullOrWhiteSpace(documentTypeCode)
                ? DBNull.Value
                : documentTypeCode.Trim().ToUpperInvariant());
        command.Parameters.AddWithValue(
            "status",
            status is null ? DBNull.Value : status.Value.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("on_legal_hold", onLegalHold is null ? DBNull.Value : onLegalHold.Value);
        command.Parameters.AddWithValue("limit", Math.Clamp(limit, 1, 100));

        return await ReadDocumentsAsync(command, cancellationToken);
    }

    private static async Task<IReadOnlyCollection<Document>> ReadDocumentsAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var documents = new Dictionary<Guid, DocumentBuilder>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            var documentId = reader.GetGuid(0);
            if (!documents.TryGetValue(documentId, out var builder))
            {
                builder = new DocumentBuilder(
                    documentId,
                    reader.GetGuid(1),
                    reader.GetString(2),
                    reader.GetString(3),
                    Enum.Parse<DocumentStatus>(reader.GetString(4), ignoreCase: true),
                    reader.GetFieldValue<DateTimeOffset>(5));

                documents.Add(documentId, builder);
            }

            if (!reader.IsDBNull(6))
            {
                builder.Versions.Add(new DocumentVersion(
                    reader.GetGuid(6),
                    reader.GetInt32(7),
                    reader.GetString(8),
                    reader.GetString(9),
                    reader.GetString(10),
                    reader.GetInt64(11),
                    reader.IsDBNull(12) ? null : reader.GetGuid(12),
                    reader.GetFieldValue<DateTimeOffset>(13)));
            }
        }

        return documents.Values.Select(builder => builder.ToDomain()).ToArray();
    }

    private sealed class DocumentBuilder
    {
        public DocumentBuilder(
            Guid id,
            Guid tenantId,
            string documentTypeCode,
            string title,
            DocumentStatus status,
            DateTimeOffset createdAtUtc)
        {
            Id = id;
            TenantId = tenantId;
            DocumentTypeCode = documentTypeCode;
            Title = title;
            Status = status;
            CreatedAtUtc = createdAtUtc;
        }

        public Guid Id { get; }

        public Guid TenantId { get; }

        public string DocumentTypeCode { get; }

        public string Title { get; }

        public DocumentStatus Status { get; }

        public DateTimeOffset CreatedAtUtc { get; }

        public List<DocumentVersion> Versions { get; } = [];

        public Document ToDomain()
        {
            return Document.Rehydrate(Id, TenantId, DocumentTypeCode, Title, Status, CreatedAtUtc, Versions);
        }
    }
}
