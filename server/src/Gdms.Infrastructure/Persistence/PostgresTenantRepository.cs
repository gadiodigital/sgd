using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Tenancy;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists tenant aggregates in PostgreSQL.
/// </summary>
public sealed class PostgresTenantRepository : ITenantRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresTenantRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<Tenant>> ListAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT tenant_id, code, name, sector, primary_country_code, created_at_utc
            FROM platform.tenants
            ORDER BY name;
            """;

        var tenants = new List<Tenant>();
        await using var command = _dataSource.CreateCommand(sql);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            tenants.Add(Map(reader));
        }

        return tenants;
    }

    /// <inheritdoc />
    public async Task<Tenant?> GetByIdAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT tenant_id, code, name, sector, primary_country_code, created_at_utc
            FROM platform.tenants
            WHERE tenant_id = @tenant_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? Map(reader) : null;
    }

    /// <inheritdoc />
    public async Task<Tenant?> GetByCodeAsync(string tenantCode, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT tenant_id, code, name, sector, primary_country_code, created_at_utc
            FROM platform.tenants
            WHERE code = @code
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("code", tenantCode.Trim().ToUpperInvariant());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? Map(reader) : null;
    }

    /// <inheritdoc />
    public async Task<Tenant> AddAsync(Tenant tenant, CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO platform.tenants
                (tenant_id, code, name, sector, primary_country_code, is_active, created_at_utc)
            VALUES
                (@tenant_id, @code, @name, @sector, @primary_country_code, TRUE, @created_at_utc)
            RETURNING tenant_id, code, name, sector, primary_country_code, created_at_utc;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenant.Id);
        command.Parameters.AddWithValue("code", tenant.Code);
        command.Parameters.AddWithValue("name", tenant.Name);
        command.Parameters.AddWithValue("sector", tenant.Sector);
        command.Parameters.AddWithValue("primary_country_code", tenant.PrimaryCountryCode);
        command.Parameters.AddWithValue("created_at_utc", tenant.CreatedAtUtc);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return Map(reader);
    }

    private static Tenant Map(NpgsqlDataReader reader)
    {
        return new Tenant(
            reader.GetGuid(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetString(3),
            reader.GetString(4),
            reader.GetFieldValue<DateTimeOffset>(5));
    }
}
