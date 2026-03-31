using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Identity;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists and queries platform roles in PostgreSQL.
/// </summary>
public sealed class PostgresRoleRepository : IRoleRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresRoleRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<Role>> ListAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT role_id, code, name, description
            FROM identity.roles
            ORDER BY name;
            """;

        var roles = new List<Role>();
        await using var command = _dataSource.CreateCommand(sql);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            roles.Add(Map(reader));
        }

        return roles;
    }

    /// <inheritdoc />
    public async Task<Role?> GetByCodeAsync(string roleCode, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT role_id, code, name, description
            FROM identity.roles
            WHERE code = @code
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("code", roleCode.Trim().ToUpperInvariant());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await reader.ReadAsync(cancellationToken) ? Map(reader) : null;
    }

    private static Role Map(NpgsqlDataReader reader)
    {
        return new Role(
            reader.GetGuid(0),
            reader.GetString(1),
            reader.GetString(2),
            reader.GetString(3));
    }
}
