using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Records;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists and queries legal holds from PostgreSQL.
/// </summary>
public sealed class PostgresLegalHoldRepository : ILegalHoldRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresLegalHoldRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<LegalHold>> ListByDocumentAsync(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT legal_hold_id, tenant_id, document_id, reason, is_active, created_by_user_id, created_at_utc, released_by_user_id, released_at_utc, release_reason
            FROM records.legal_holds
            WHERE tenant_id = @tenant_id
              AND document_id = @document_id
            ORDER BY created_at_utc DESC;
            """;

        var holds = new List<LegalHold>();
        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_id", documentId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            holds.Add(Map(reader));
        }

        return holds;
    }

    /// <inheritdoc />
    public async Task<LegalHold?> GetByIdAsync(Guid tenantId, Guid legalHoldId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT legal_hold_id, tenant_id, document_id, reason, is_active, created_by_user_id, created_at_utc, released_by_user_id, released_at_utc, release_reason
            FROM records.legal_holds
            WHERE tenant_id = @tenant_id
              AND legal_hold_id = @legal_hold_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("legal_hold_id", legalHoldId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? Map(reader) : null;
    }

    /// <inheritdoc />
    public async Task<LegalHold> AddAsync(LegalHold legalHold, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO records.legal_holds
                (legal_hold_id, tenant_id, document_id, reason, is_active, created_by_user_id, created_at_utc, released_by_user_id, released_at_utc, release_reason)
            VALUES
                (@legal_hold_id, @tenant_id, @document_id, @reason, @is_active, @created_by_user_id, @created_at_utc, NULL, NULL, NULL)
            RETURNING legal_hold_id, tenant_id, document_id, reason, is_active, created_by_user_id, created_at_utc, released_by_user_id, released_at_utc, release_reason;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("legal_hold_id", legalHold.Id);
        command.Parameters.AddWithValue("tenant_id", legalHold.TenantId);
        command.Parameters.AddWithValue("document_id", (object?)legalHold.DocumentId ?? DBNull.Value);
        command.Parameters.AddWithValue("reason", legalHold.Reason);
        command.Parameters.AddWithValue("is_active", legalHold.IsActive);
        command.Parameters.AddWithValue("created_by_user_id", (object?)legalHold.CreatedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("created_at_utc", legalHold.CreatedAtUtc);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return Map(reader);
    }

    /// <inheritdoc />
    public async Task<LegalHold> ReleaseAsync(
        Guid tenantId,
        Guid legalHoldId,
        Guid releasedByUserId,
        string releaseReason,
        CancellationToken cancellationToken)
    {
        var existingLegalHold = await GetByIdAsync(tenantId, legalHoldId, cancellationToken)
            ?? throw new DomainRuleException("No existe el legal hold informado dentro del tenant.");

        if (!existingLegalHold.IsActive)
        {
            throw new DomainRuleException("El legal hold informado ya se encuentra liberado.");
        }

        const string sql = """
            UPDATE records.legal_holds
            SET is_active = FALSE,
                released_by_user_id = @released_by_user_id,
                released_at_utc = @released_at_utc,
                release_reason = @release_reason
            WHERE tenant_id = @tenant_id
              AND legal_hold_id = @legal_hold_id
            RETURNING legal_hold_id, tenant_id, document_id, reason, is_active, created_by_user_id, created_at_utc, released_by_user_id, released_at_utc, release_reason;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("legal_hold_id", legalHoldId);
        command.Parameters.AddWithValue("released_by_user_id", releasedByUserId);
        command.Parameters.AddWithValue("released_at_utc", DateTimeOffset.UtcNow);
        command.Parameters.AddWithValue("release_reason", releaseReason.Trim());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return Map(reader);
    }

    private static LegalHold Map(NpgsqlDataReader reader)
    {
        return new LegalHold(
            reader.GetGuid(0),
            reader.GetGuid(1),
            reader.IsDBNull(2) ? null : reader.GetGuid(2),
            reader.GetString(3),
            reader.GetBoolean(4),
            reader.IsDBNull(5) ? null : reader.GetGuid(5),
            reader.GetFieldValue<DateTimeOffset>(6),
            reader.IsDBNull(7) ? null : reader.GetGuid(7),
            reader.IsDBNull(8) ? null : reader.GetFieldValue<DateTimeOffset>(8),
            reader.IsDBNull(9) ? null : reader.GetString(9));
    }
}
