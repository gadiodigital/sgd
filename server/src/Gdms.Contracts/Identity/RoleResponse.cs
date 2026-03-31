namespace Gdms.Contracts.Identity;

/// <summary>
/// Represents an authorization role returned by the public API.
/// </summary>
public sealed record RoleResponse(
    Guid Id,
    string Code,
    string Name,
    string Description);
