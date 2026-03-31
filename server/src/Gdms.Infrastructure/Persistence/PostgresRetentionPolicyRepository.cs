using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Records;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Queries retention policies from PostgreSQL.
/// </summary>
public sealed class PostgresRetentionPolicyRepository : IRetentionPolicyRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresRetentionPolicyRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<RetentionPolicy>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT retention_policy_id, tenant_id, code, name, retention_days, disposition_action, is_active
            FROM records.retention_policies
            WHERE is_active = TRUE
              AND (tenant_id IS NULL OR tenant_id = @tenant_id)
            ORDER BY tenant_id NULLS FIRST, name;
            """;

        var policies = new List<RetentionPolicy>();
        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            policies.Add(Map(reader));
        }

        return policies;
    }

    /// <inheritdoc />
    public async Task<RetentionPolicy?> GetByCodeAsync(Guid tenantId, string policyCode, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT retention_policy_id, tenant_id, code, name, retention_days, disposition_action, is_active
            FROM records.retention_policies
            WHERE is_active = TRUE
              AND code = @code
              AND (tenant_id IS NULL OR tenant_id = @tenant_id)
            ORDER BY tenant_id NULLS FIRST
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("code", policyCode.Trim().ToUpperInvariant());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? Map(reader) : null;
    }

    private static RetentionPolicy Map(NpgsqlDataReader reader)
    {
        return new RetentionPolicy(
            reader.GetGuid(0),
            reader.IsDBNull(1) ? null : reader.GetGuid(1),
            reader.GetString(2),
            reader.GetString(3),
            reader.GetInt32(4),
            Enum.Parse<RetentionDispositionAction>(reader.GetString(5), ignoreCase: true),
            reader.GetBoolean(6));
    }
}
