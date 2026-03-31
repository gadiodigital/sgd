using Gdms.Domain.Common;
using Gdms.Domain.Documents;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Holds query and mapping helpers for the PostgreSQL document repository.
/// </summary>
public sealed partial class PostgresDocumentRepository
{
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

    private static async Task<Guid> ResolveDocumentTypeIdAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid tenantId,
        string documentTypeCode,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT document_type_id
            FROM configuration.document_types
            WHERE code = @code
              AND is_active = TRUE
              AND (tenant_id IS NULL OR tenant_id = @tenant_id)
            ORDER BY
                CASE WHEN tenant_id = @tenant_id THEN 0 ELSE 1 END,
                created_at_utc DESC
            LIMIT 1;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("code", documentTypeCode.ToUpperInvariant());
        command.Parameters.AddWithValue("tenant_id", tenantId);

        var result = await command.ExecuteScalarAsync(cancellationToken);
        if (result is Guid documentTypeId)
        {
            return documentTypeId;
        }

        throw new DomainRuleException($"No existe un tipo documental activo para el código '{documentTypeCode}'.");
    }

    private static async Task<Guid?> ResolveOptionalUserIdAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid tenantId,
        Guid? userId,
        CancellationToken cancellationToken)
    {
        if (userId is null || userId == Guid.Empty)
        {
            return null;
        }

        const string sql = """
            SELECT user_id
            FROM identity.users
            WHERE user_id = @user_id
              AND tenant_id = @tenant_id
            LIMIT 1;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("user_id", userId.Value);
        command.Parameters.AddWithValue("tenant_id", tenantId);

        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result as Guid? ?? (result is Guid validUserId ? validUserId : null);
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
            return Document.Rehydrate(
                Id,
                TenantId,
                DocumentTypeCode,
                Title,
                Status,
                CreatedAtUtc,
                Versions);
        }
    }
}
