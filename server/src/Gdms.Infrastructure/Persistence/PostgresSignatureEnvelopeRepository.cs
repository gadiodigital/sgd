using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Signatures;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists signature envelopes in PostgreSQL.
/// </summary>
public sealed class PostgresSignatureEnvelopeRepository : ISignatureEnvelopeRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresSignatureEnvelopeRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<SignatureEnvelope>> ListByTenantAsync(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                signature_envelope_id,
                tenant_id,
                document_id,
                signer_display_name,
                signer_email,
                signature_level,
                provider_code,
                external_reference,
                status,
                requested_by_user_id,
                requested_at_utc,
                due_at_utc,
                completed_by_user_id,
                completed_at_utc,
                cancelled_by_user_id,
                cancelled_at_utc,
                cancellation_reason
            FROM signature.signature_envelopes
            WHERE tenant_id = @tenant_id
            ORDER BY
                CASE status WHEN 'PENDING' THEN 0 ELSE 1 END,
                COALESCE(due_at_utc, requested_at_utc),
                requested_at_utc DESC;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await ReadEnvelopesAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<SignatureEnvelope?> GetByIdAsync(Guid envelopeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                signature_envelope_id,
                tenant_id,
                document_id,
                signer_display_name,
                signer_email,
                signature_level,
                provider_code,
                external_reference,
                status,
                requested_by_user_id,
                requested_at_utc,
                due_at_utc,
                completed_by_user_id,
                completed_at_utc,
                cancelled_by_user_id,
                cancelled_at_utc,
                cancellation_reason
            FROM signature.signature_envelopes
            WHERE signature_envelope_id = @signature_envelope_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("signature_envelope_id", envelopeId);
        return (await ReadEnvelopesAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<SignatureEnvelope> AddAsync(SignatureEnvelope envelope, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO signature.signature_envelopes
                (signature_envelope_id, tenant_id, document_id, signer_display_name, signer_email, signature_level,
                 provider_code, external_reference, status, requested_by_user_id, requested_at_utc, due_at_utc,
                 completed_by_user_id, completed_at_utc, cancelled_by_user_id, cancelled_at_utc, cancellation_reason)
            VALUES
                (@signature_envelope_id, @tenant_id, @document_id, @signer_display_name, @signer_email, @signature_level,
                 @provider_code, @external_reference, @status, @requested_by_user_id, @requested_at_utc, @due_at_utc,
                 @completed_by_user_id, @completed_at_utc, @cancelled_by_user_id, @cancelled_at_utc, @cancellation_reason);
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("signature_envelope_id", envelope.Id);
        command.Parameters.AddWithValue("tenant_id", envelope.TenantId);
        command.Parameters.AddWithValue("document_id", envelope.DocumentId);
        command.Parameters.AddWithValue("signer_display_name", envelope.SignerDisplayName);
        command.Parameters.AddWithValue("signer_email", envelope.SignerEmail);
        command.Parameters.AddWithValue("signature_level", envelope.SignatureLevel);
        command.Parameters.AddWithValue("provider_code", envelope.ProviderCode);
        command.Parameters.AddWithValue("external_reference", (object?)envelope.ExternalReference ?? DBNull.Value);
        command.Parameters.AddWithValue("status", envelope.Status.ToString().ToUpperInvariant());
        command.Parameters.AddWithValue("requested_by_user_id", (object?)envelope.RequestedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("requested_at_utc", envelope.RequestedAtUtc);
        command.Parameters.AddWithValue("due_at_utc", (object?)envelope.DueAtUtc ?? DBNull.Value);
        command.Parameters.AddWithValue("completed_by_user_id", (object?)envelope.CompletedByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("completed_at_utc", (object?)envelope.CompletedAtUtc ?? DBNull.Value);
        command.Parameters.AddWithValue("cancelled_by_user_id", (object?)envelope.CancelledByUserId ?? DBNull.Value);
        command.Parameters.AddWithValue("cancelled_at_utc", (object?)envelope.CancelledAtUtc ?? DBNull.Value);
        command.Parameters.AddWithValue("cancellation_reason", (object?)envelope.CancellationReason ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
        return envelope;
    }

    /// <inheritdoc />
    public async Task CompleteAsync(
        Guid tenantId,
        Guid envelopeId,
        Guid completedByUserId,
        DateTimeOffset completedAtUtc,
        string? externalReference,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE signature.signature_envelopes
            SET status = 'SIGNED',
                completed_by_user_id = @completed_by_user_id,
                completed_at_utc = @completed_at_utc,
                external_reference = @external_reference
            WHERE tenant_id = @tenant_id
              AND signature_envelope_id = @signature_envelope_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("signature_envelope_id", envelopeId);
        command.Parameters.AddWithValue("completed_by_user_id", completedByUserId);
        command.Parameters.AddWithValue("completed_at_utc", completedAtUtc);
        command.Parameters.AddWithValue("external_reference", (object?)externalReference ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    /// <inheritdoc />
    public async Task CancelAsync(
        Guid tenantId,
        Guid envelopeId,
        Guid cancelledByUserId,
        DateTimeOffset cancelledAtUtc,
        string cancellationReason,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE signature.signature_envelopes
            SET status = 'CANCELLED',
                cancelled_by_user_id = @cancelled_by_user_id,
                cancelled_at_utc = @cancelled_at_utc,
                cancellation_reason = @cancellation_reason
            WHERE tenant_id = @tenant_id
              AND signature_envelope_id = @signature_envelope_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("signature_envelope_id", envelopeId);
        command.Parameters.AddWithValue("cancelled_by_user_id", cancelledByUserId);
        command.Parameters.AddWithValue("cancelled_at_utc", cancelledAtUtc);
        command.Parameters.AddWithValue("cancellation_reason", cancellationReason);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<IReadOnlyCollection<SignatureEnvelope>> ReadEnvelopesAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var result = new List<SignatureEnvelope>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(SignatureEnvelope.Rehydrate(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetGuid(2),
                reader.GetString(3),
                reader.GetString(4),
                reader.GetString(5),
                reader.GetString(6),
                reader.IsDBNull(7) ? null : reader.GetString(7),
                Enum.Parse<SignatureEnvelopeStatus>(reader.GetString(8), ignoreCase: true),
                reader.IsDBNull(9) ? null : reader.GetGuid(9),
                reader.GetFieldValue<DateTimeOffset>(10),
                reader.IsDBNull(11) ? null : reader.GetFieldValue<DateTimeOffset>(11),
                reader.IsDBNull(12) ? null : reader.GetGuid(12),
                reader.IsDBNull(13) ? null : reader.GetFieldValue<DateTimeOffset>(13),
                reader.IsDBNull(14) ? null : reader.GetGuid(14),
                reader.IsDBNull(15) ? null : reader.GetFieldValue<DateTimeOffset>(15),
                reader.IsDBNull(16) ? null : reader.GetString(16)));
        }

        return result;
    }
}
