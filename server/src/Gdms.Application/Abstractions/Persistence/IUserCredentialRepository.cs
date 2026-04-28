using Gdms.Application.Identity;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines credential-specific persistence operations for organization users.
/// </summary>
public interface IUserCredentialRepository
{
    /// <summary>
    /// Returns the authentication snapshot for an organization user by email.
    /// </summary>
    Task<UserCredentialSnapshot?> GetByEmailAsync(Guid tenantId, string email, CancellationToken cancellationToken);

    /// <summary>
    /// Resets failure counters and records the last successful login.
    /// </summary>
    Task RecordSuccessfulLoginAsync(Guid tenantId, Guid userId, CancellationToken cancellationToken);

    /// <summary>
    /// Increments failure counters and optionally applies a lockout deadline.
    /// </summary>
    Task RecordFailedLoginAsync(
        Guid tenantId,
        Guid userId,
        DateTimeOffset? lockedUntilUtc,
        CancellationToken cancellationToken);
}
