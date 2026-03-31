using Gdms.Domain.Identity;

namespace Gdms.Application.Identity;

/// <summary>
/// Represents the credential and lockout state required to authenticate a user.
/// </summary>
public sealed record UserCredentialSnapshot(
    User User,
    string PasswordHash,
    bool MustChangePassword,
    int FailedLoginCount,
    DateTimeOffset? LockedUntilUtc);
