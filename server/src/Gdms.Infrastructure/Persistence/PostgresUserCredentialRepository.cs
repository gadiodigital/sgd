using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Identity;
using Gdms.Domain.Identity;
using Npgsql;

namespace Gdms.Infrastructure.Persistence;

/// <summary>
/// Persists credential, lockout and login-tracking data for local authentication.
/// </summary>
public sealed class PostgresUserCredentialRepository : IUserCredentialRepository
{
    private readonly NpgsqlDataSource _dataSource;

    /// <summary>
    /// Initializes the repository with a PostgreSQL data source.
    /// </summary>
    public PostgresUserCredentialRepository(NpgsqlDataSource dataSource)
    {
        _dataSource = dataSource;
    }

    /// <inheritdoc />
    public async Task<UserCredentialSnapshot?> GetByEmailAsync(
        Guid tenantId,
        string email,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                u.user_id,
                u.tenant_id,
                u.email::text,
                u.full_name,
                u.status,
                u.created_at_utc,
                u.password_hash,
                u.must_change_password,
                u.failed_login_count,
                u.locked_until_utc,
                r.role_id,
                r.code,
                r.name,
                r.description
            FROM identity.users u
            LEFT JOIN identity.user_roles ur ON ur.user_id = u.user_id
            LEFT JOIN identity.roles r ON r.role_id = ur.role_id
            WHERE u.tenant_id = @tenant_id
              AND u.email = @email
            ORDER BY r.name;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("email", email.Trim().ToLowerInvariant());

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        CredentialBuilder? builder = null;

        while (await reader.ReadAsync(cancellationToken))
        {
            builder ??= new CredentialBuilder(
                reader.GetGuid(0),
                reader.GetGuid(1),
                reader.GetString(2),
                reader.GetString(3),
                Enum.Parse<UserStatus>(reader.GetString(4), ignoreCase: true),
                reader.GetFieldValue<DateTimeOffset>(5),
                reader.IsDBNull(6) ? string.Empty : reader.GetString(6),
                reader.GetBoolean(7),
                reader.GetInt16(8),
                reader.IsDBNull(9) ? null : reader.GetFieldValue<DateTimeOffset>(9));

            if (!reader.IsDBNull(10))
            {
                builder.Roles.Add(new Role(
                    reader.GetGuid(10),
                    reader.GetString(11),
                    reader.GetString(12),
                    reader.GetString(13)));
            }
        }

        return builder?.ToSnapshot();
    }

    /// <inheritdoc />
    public async Task RecordSuccessfulLoginAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE identity.users
            SET failed_login_count = 0,
                locked_until_utc = NULL,
                last_login_at_utc = @last_login_at_utc
            WHERE tenant_id = @tenant_id
              AND user_id = @user_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("user_id", userId);
        command.Parameters.AddWithValue("last_login_at_utc", DateTimeOffset.UtcNow);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    /// <inheritdoc />
    public async Task RecordFailedLoginAsync(
        Guid tenantId,
        Guid userId,
        DateTimeOffset? lockedUntilUtc,
        CancellationToken cancellationToken)
    {
        const string sql = """
            UPDATE identity.users
            SET failed_login_count = LEAST(failed_login_count + 1, 20),
                locked_until_utc = @locked_until_utc
            WHERE tenant_id = @tenant_id
              AND user_id = @user_id;
            """;

        await using var command = _dataSource.CreateCommand(sql);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("user_id", userId);
        command.Parameters.AddWithValue("locked_until_utc", (object?)lockedUntilUtc ?? DBNull.Value);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private sealed class CredentialBuilder
    {
        public CredentialBuilder(
            Guid userId,
            Guid tenantId,
            string email,
            string fullName,
            UserStatus status,
            DateTimeOffset createdAtUtc,
            string passwordHash,
            bool mustChangePassword,
            int failedLoginCount,
            DateTimeOffset? lockedUntilUtc)
        {
            UserId = userId;
            TenantId = tenantId;
            Email = email;
            FullName = fullName;
            Status = status;
            CreatedAtUtc = createdAtUtc;
            PasswordHash = passwordHash;
            MustChangePassword = mustChangePassword;
            FailedLoginCount = failedLoginCount;
            LockedUntilUtc = lockedUntilUtc;
        }

        public Guid UserId { get; }

        public Guid TenantId { get; }

        public string Email { get; }

        public string FullName { get; }

        public UserStatus Status { get; }

        public DateTimeOffset CreatedAtUtc { get; }

        public string PasswordHash { get; }

        public bool MustChangePassword { get; }

        public int FailedLoginCount { get; }

        public DateTimeOffset? LockedUntilUtc { get; }

        public List<Role> Roles { get; } = [];

        public UserCredentialSnapshot ToSnapshot()
        {
            var user = User.Rehydrate(UserId, TenantId, Email, FullName, Status, CreatedAtUtc, Roles);
            return new UserCredentialSnapshot(user, PasswordHash, MustChangePassword, FailedLoginCount, LockedUntilUtc);
        }
    }
}
