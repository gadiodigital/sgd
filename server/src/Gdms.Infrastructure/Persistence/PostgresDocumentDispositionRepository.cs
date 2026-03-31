using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Records;
using Gdms.Domain.Common;
using Gdms.Domain.Documents;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists and queries retention-driven document disposition workflows.
/// </summary>
public sealed class PostgresDocumentDispositionRepository : IDocumentDispositionRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresDocumentDispositionRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<DispositionCandidate>> ListDueAsync(
        Guid tenantId,
        DateTimeOffset asOfUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.document_id,
                dt.code,
                d.title,
                d.status,
                rp.code,
                rp.retention_days,
                rp.disposition_action,
                d.created_at_utc + make_interval(days => rp.retention_days) AS due_at_utc,
                EXISTS (
                    SELECT 1
                    FROM records.legal_holds lh
                    WHERE lh.tenant_id = d.tenant_id
                      AND lh.document_id = d.document_id
                      AND lh.is_active = TRUE
                ) AS has_active_legal_hold
            FROM documents.documents d
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            INNER JOIN records.retention_policies rp ON rp.retention_policy_id = d.retention_policy_id
            WHERE d.tenant_id = @tenant_id
              AND d.status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')
              AND rp.is_active = TRUE
              AND d.created_at_utc + make_interval(days => rp.retention_days) <= @as_of_utc
            ORDER BY due_at_utc ASC, d.created_at_utc ASC;
            """;

        var candidates = new List<DispositionCandidate>();
        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("as_of_utc", asOfUtc);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            candidates.Add(Map(reader));
        }

        return candidates;
    }

    /// <inheritdoc />
    public async Task<DispositionCandidate?> GetDueByIdAsync(
        Guid tenantId,
        Guid documentId,
        DateTimeOffset asOfUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.document_id,
                dt.code,
                d.title,
                d.status,
                rp.code,
                rp.retention_days,
                rp.disposition_action,
                d.created_at_utc + make_interval(days => rp.retention_days) AS due_at_utc,
                EXISTS (
                    SELECT 1
                    FROM records.legal_holds lh
                    WHERE lh.tenant_id = d.tenant_id
                      AND lh.document_id = d.document_id
                      AND lh.is_active = TRUE
                ) AS has_active_legal_hold
            FROM documents.documents d
            INNER JOIN configuration.document_types dt ON dt.document_type_id = d.document_type_id
            INNER JOIN records.retention_policies rp ON rp.retention_policy_id = d.retention_policy_id
            WHERE d.tenant_id = @tenant_id
              AND d.document_id = @document_id
              AND d.status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')
              AND rp.is_active = TRUE
              AND d.created_at_utc + make_interval(days => rp.retention_days) <= @as_of_utc
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("as_of_utc", asOfUtc);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? Map(reader) : null;
    }

    /// <inheritdoc />
    public async Task ApplyDispositionAsync(
        Guid tenantId,
        Guid documentId,
        string dispositionAction,
        DocumentStatus nextStatus,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE documents.documents
            SET status = @status
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("status", nextStatus.ToString().ToUpperInvariant());

        var affectedRows = await command.ExecuteNonQueryAsync(cancellationToken);
        if (affectedRows == 0)
        {
            throw new DomainRuleException("No fue posible aplicar la disposición al documento indicado.");
        }
    }

    private static DispositionCandidate Map(NpgsqlDataReader reader)
    {
        return new DispositionCandidate(
            reader.GetGuid(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetString(3),
            reader.GetString(4),
            reader.GetInt32(5),
            reader.GetString(6).ToUpperInvariant(),
            reader.GetFieldValue<DateTimeOffset>(7),
            reader.GetBoolean(8));
    }
}
