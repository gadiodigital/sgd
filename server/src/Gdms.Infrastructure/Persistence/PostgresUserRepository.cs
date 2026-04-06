using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Identity;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists tenant-scoped users and their role assignments in PostgreSQL.
/// </summary>
public sealed class PostgresUserRepository : IUserRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresUserRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<bool> TenantHasUsersAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM identity.users
            WHERE tenant_id = @tenant_id
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    /// <inheritdoc />
    public async Task<bool> AnyUserInRoleAsync(string roleCode, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT 1
            FROM identity.user_roles ur
            INNER JOIN identity.roles r ON r.role_id = ur.role_id
            WHERE r.code = @role_code
            LIMIT 1;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("role_code", roleCode.Trim().ToUpperInvariant());
        return await command.ExecuteScalarAsync(cancellationToken) is not null;
    }

    /// <inheritdoc />
    public async Task<IReadOnlyCollection<User>> ListByTenantAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                u.user_id,
                u.tenant_id,
                u.email::text,
                u.full_name,
                u.status,
                u.created_at_utc,
                r.role_id,
                r.code,
                r.name,
                r.description
            FROM identity.users u
            LEFT JOIN identity.user_roles ur ON ur.user_id = u.user_id
            LEFT JOIN identity.roles r ON r.role_id = ur.role_id
            WHERE u.tenant_id = @tenant_id
            ORDER BY u.full_name, r.name;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);

        return await ReadUsersAsync(command, cancellationToken);
    }

    /// <inheritdoc />
    public async Task<User?> GetByIdAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                u.user_id,
                u.tenant_id,
                u.email::text,
                u.full_name,
                u.status,
                u.created_at_utc,
                r.role_id,
                r.code,
                r.name,
                r.description
            FROM identity.users u
            LEFT JOIN identity.user_roles ur ON ur.user_id = u.user_id
            LEFT JOIN identity.roles r ON r.role_id = ur.role_id
            WHERE u.tenant_id = @tenant_id
              AND u.user_id = @user_id
            ORDER BY r.name;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("user_id", userId);

        return (await ReadUsersAsync(command, cancellationToken)).SingleOrDefault();
    }

    /// <inheritdoc />
    public async Task<User> AddAsync(
        User user,
        string passwordHash,
        bool mustChangePassword,
        CancellationToken cancellationToken)
    {
        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        const string insertUserSql = """
            INSERT INTO identity.users
                (user_id, tenant_id, email, full_name, status, password_hash, must_change_password, failed_login_count, locked_until_utc, last_login_at_utc, created_at_utc)
            VALUES
                (@user_id, @tenant_id, @email, @full_name, @status, @password_hash, @must_change_password, 0, NULL, NULL, @created_at_utc);
            """;

        try
        {
            await using (var insertUser = new NpgsqlCommand(insertUserSql, connection, transaction))
            {
                insertUser.Parameters.AddWithValue("user_id", user.Id);
                insertUser.Parameters.AddWithValue("tenant_id", user.TenantId);
                insertUser.Parameters.AddWithValue("email", user.Email);
                insertUser.Parameters.AddWithValue("full_name", user.FullName);
                insertUser.Parameters.AddWithValue("status", user.Status.ToString().ToUpperInvariant());
                insertUser.Parameters.AddWithValue("password_hash", passwordHash);
                insertUser.Parameters.AddWithValue("must_change_password", mustChangePassword);
                insertUser.Parameters.AddWithValue("created_at_utc", user.CreatedAtUtc);
                await insertUser.ExecuteNonQueryAsync(cancellationToken);
            }

            await InsertRoleAssignmentsAsync(connection, transaction, user.Id, user.Roles, cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        catch (PostgresException exception) when (exception.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            throw new DomainRuleException("Ya existe un usuario con el mismo correo electrónico dentro del tenant.");
        }

        return await GetByIdAsync(user.TenantId, user.Id, cancellationToken)
            ?? throw new DomainRuleException("No fue posible recuperar el usuario luego de persistirlo.");
    }

    /// <inheritdoc />
    public async Task<User> AssignRoleAsync(Guid tenantId, Guid userId, Role role, CancellationToken cancellationToken)
    {
        await using var connection = await _dataSource.OpenConnectionAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        const string ensureUserSql = """
            SELECT 1
            FROM identity.users
            WHERE tenant_id = @tenant_id
              AND user_id = @user_id
            LIMIT 1;
            """;

        await using (var ensureUser = new NpgsqlCommand(ensureUserSql, connection, transaction))
        {
            ensureUser.Parameters.AddWithValue("tenant_id", tenantId);
            ensureUser.Parameters.AddWithValue("user_id", userId);

            if (await ensureUser.ExecuteScalarAsync(cancellationToken) is null)
            {
                throw new DomainRuleException("No existe el usuario informado dentro del tenant.");
            }
        }

        await InsertRoleAssignmentsAsync(connection, transaction, userId, [role], cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return await GetByIdAsync(tenantId, userId, cancellationToken)
            ?? throw new DomainRuleException("No fue posible recuperar el usuario luego de asignar el rol.");
    }

    private static async Task InsertRoleAssignmentsAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid userId,
        IEnumerable<Role> roles,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO identity.user_roles
                (user_role_id, user_id, role_id, assigned_at_utc)
            VALUES
                (@user_role_id, @user_id, @role_id, @assigned_at_utc)
            ON CONFLICT (user_id, role_id) DO NOTHING;
            """;

        foreach (var role in roles)
        {
            await using var command = new NpgsqlCommand(sql, connection, transaction);
            command.Parameters.AddWithValue("user_role_id", Guid.NewGuid());
            command.Parameters.AddWithValue("user_id", userId);
            command.Parameters.AddWithValue("role_id", role.Id);
            command.Parameters.AddWithValue("assigned_at_utc", DateTimeOffset.UtcNow);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
    }

    private static async Task<IReadOnlyCollection<User>> ReadUsersAsync(
        NpgsqlCommand command,
        CancellationToken cancellationToken)
    {
        var users = new Dictionary<Guid, UserBuilder>();
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            var userId = reader.GetGuid(0);
            if (!users.TryGetValue(userId, out var builder))
            {
                builder = new UserBuilder(
                    userId,
                    reader.GetGuid(1),
                    reader.GetString(2),
                    reader.GetString(3),
                    Enum.Parse<UserStatus>(reader.GetString(4), ignoreCase: true),
                    reader.GetFieldValue<DateTimeOffset>(5));

                users.Add(userId, builder);
            }

            if (!reader.IsDBNull(6))
            {
                builder.Roles.Add(new Role(
                    reader.GetGuid(6),
                    reader.GetString(7),
                    reader.GetString(8),
                    reader.GetString(9)));
            }
        }

        return users.Values.Select(builder => builder.ToDomain()).ToArray();
    }

    private sealed class UserBuilder
    {
        public UserBuilder(
            Guid id,
            Guid tenantId,
            string email,
            string fullName,
            UserStatus status,
            DateTimeOffset createdAtUtc)
        {
            Id = id;
            TenantId = tenantId;
            Email = email;
            FullName = fullName;
            Status = status;
            CreatedAtUtc = createdAtUtc;
        }

        public Guid Id { get; }

        public Guid TenantId { get; }

        public string Email { get; }

        public string FullName { get; }

        public UserStatus Status { get; }

        public DateTimeOffset CreatedAtUtc { get; }

        public List<Role> Roles { get; } = [];

        public User ToDomain()
        {
            return User.Rehydrate(Id, TenantId, Email, FullName, Status, CreatedAtUtc, Roles);
        }
    }
}
