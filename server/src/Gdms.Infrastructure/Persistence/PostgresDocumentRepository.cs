using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Documents;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists document aggregates in PostgreSQL.
/// </summary>
public sealed partial class PostgresDocumentRepository : IDocumentRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresDocumentRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<Document>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
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
            FROM documents.documents d
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            LEFT JOIN documents.document_versions dv ON dv.document_id = d.document_id
            WHERE d.tenant_id = @tenant_id
            ORDER BY d.created_at_utc DESC, dv.version_number;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadDocumentsAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<Document?> GetByIdAsync(Guid documentId, CancellationToken cancellationToken)
    {
        const string sql = """
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
            FROM documents.documents d
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            LEFT JOIN documents.document_versions dv ON dv.document_id = d.document_id
            WHERE d.document_id = @document_id
            ORDER BY dv.version_number;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("document_id", documentId);
        return (await ReadDocumentsAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<Document> AddAsync(Document document, CancellationToken cancellationToken)
    {
        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        var documentTypeId = await ResolveDocumentTypeIdAsync(connection, transaction, document.TenantId, document.DocumentTypeCode, cancellationToken);
        var createdByUserId = await ResolveOptionalUserIdAsync(connection, transaction, document.TenantId, document.Versions.LastOrDefault()?.UploadedByUserId, cancellationToken);

        const string insertDocumentSql = """
            INSERT INTO documents.documents
                (document_id, tenant_id, document_type_id, retention_policy_id, title, status, confidentiality_level, current_version_number, created_by_user_id, created_at_utc)
            VALUES
                (@document_id, @tenant_id, @document_type_id, NULL, @title, @status, 1, @current_version_number, @created_by_user_id, @created_at_utc);
            """;

        await using (var insertDocument = new NpgsqlCommand(insertDocumentSql, connection, transaction))
        {
            insertDocument.Parameters.AddWithValue("document_id", document.Id);
            insertDocument.Parameters.AddWithValue("tenant_id", document.TenantId);
            insertDocument.Parameters.AddWithValue("document_type_id", documentTypeId);
            insertDocument.Parameters.AddWithValue("title", document.Title);
            insertDocument.Parameters.AddWithValue("status", document.Status.ToString().ToUpperInvariant());
            insertDocument.Parameters.AddWithValue("current_version_number", document.Versions.Count);
            insertDocument.Parameters.AddWithValue("created_by_user_id", (object?)createdByUserId ?? DBNull.Value);
            insertDocument.Parameters.AddWithValue("created_at_utc", document.CreatedAtUtc);

            await insertDocument.ExecuteNonQueryAsync(cancellationToken);
        }

        const string insertVersionSql = """
            INSERT INTO documents.document_versions
                (document_version_id, document_id, version_number, storage_object_key, mime_type, file_hash_sha256, file_size_bytes, uploaded_by_user_id, uploaded_at_utc)
            VALUES
                (@document_version_id, @document_id, @version_number, @storage_object_key, @mime_type, @file_hash_sha256, @file_size_bytes, @uploaded_by_user_id, @uploaded_at_utc);
            """;

        foreach (var version in document.Versions)
        {
            var uploadedByUserId = await ResolveOptionalUserIdAsync(connection, transaction, document.TenantId, version.UploadedByUserId, cancellationToken);
            await using var insertVersion = new NpgsqlCommand(insertVersionSql, connection, transaction);
            insertVersion.Parameters.AddWithValue("document_version_id", version.Id);
            insertVersion.Parameters.AddWithValue("document_id", document.Id);
            insertVersion.Parameters.AddWithValue("version_number", version.VersionNumber);
            insertVersion.Parameters.AddWithValue("storage_object_key", version.StorageObjectKey);
            insertVersion.Parameters.AddWithValue("mime_type", version.MimeType);
            insertVersion.Parameters.AddWithValue("file_hash_sha256", version.FileHashSha256);
            insertVersion.Parameters.AddWithValue("file_size_bytes", version.FileSizeBytes);
            insertVersion.Parameters.AddWithValue("uploaded_by_user_id", (object?)uploadedByUserId ?? DBNull.Value);
            insertVersion.Parameters.AddWithValue("uploaded_at_utc", version.UploadedAtUtc);

            await insertVersion.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return document;
    }

    /// <inheritdoc />
    public async Task<Document> AddVersionAsync(
        Document document,
        DocumentVersion version,
        CancellationToken cancellationToken)
    {
        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        var uploadedByUserId = await ResolveOptionalUserIdAsync(
            connection,
            transaction,
            document.TenantId,
            version.UploadedByUserId,
            cancellationToken);

        const string insertVersionSql = """
            INSERT INTO documents.document_versions
                (document_version_id, document_id, version_number, storage_object_key, mime_type, file_hash_sha256, file_size_bytes, uploaded_by_user_id, uploaded_at_utc)
            VALUES
                (@document_version_id, @document_id, @version_number, @storage_object_key, @mime_type, @file_hash_sha256, @file_size_bytes, @uploaded_by_user_id, @uploaded_at_utc);
            """;

        await using (var insertVersion = new NpgsqlCommand(insertVersionSql, connection, transaction))
        {
            insertVersion.Parameters.AddWithValue("document_version_id", version.Id);
            insertVersion.Parameters.AddWithValue("document_id", document.Id);
            insertVersion.Parameters.AddWithValue("version_number", version.VersionNumber);
            insertVersion.Parameters.AddWithValue("storage_object_key", version.StorageObjectKey);
            insertVersion.Parameters.AddWithValue("mime_type", version.MimeType);
            insertVersion.Parameters.AddWithValue("file_hash_sha256", version.FileHashSha256);
            insertVersion.Parameters.AddWithValue("file_size_bytes", version.FileSizeBytes);
            insertVersion.Parameters.AddWithValue("uploaded_by_user_id", (object?)uploadedByUserId ?? DBNull.Value);
            insertVersion.Parameters.AddWithValue("uploaded_at_utc", version.UploadedAtUtc);
            await insertVersion.ExecuteNonQueryAsync(cancellationToken);
        }

        const string updateDocumentSql = """
            UPDATE documents.documents
            SET current_version_number = @current_version_number
            WHERE document_id = @document_id
              AND tenant_id = @tenant_id;
            """;

        await using (var updateDocument = new NpgsqlCommand(updateDocumentSql, connection, transaction))
        {
            updateDocument.Parameters.AddWithValue("document_id", document.Id);
            updateDocument.Parameters.AddWithValue("tenant_id", document.TenantId);
            updateDocument.Parameters.AddWithValue("current_version_number", document.Versions.Count);
            await updateDocument.ExecuteNonQueryAsync(cancellationToken);
        }

        await transaction.CommitAsync(cancellationToken);
        return document;
    }

    /// <inheritdoc />
    public async Task AssignRetentionPolicyAsync(
        Guid tenantId,
        Guid documentId,
        Guid retentionPolicyId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE documents.documents
            SET retention_policy_id = @retention_policy_id
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("retention_policy_id", retentionPolicyId);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
