namespace Gdms.Domain.Identity;

/// <summary>
/// Enumerates the supported lifecycle statuses for an identity user.
/// </summary>
public enum UserStatus
{
    Pending = 0,
    Active = 1,
    Suspended = 2,
    Disabled = 3
}
