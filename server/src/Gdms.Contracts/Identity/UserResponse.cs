namespace Gdms.Contracts.Identity;

/// <summary>
/// Represents a tenant user returned by the public API.
/// </summary>
public sealed record UserResponse(
    Guid Id,
    Guid TenantId,
    string Email,
    string FullName,
    string Status,
    DateTimeOffset CreatedAtUtc,
    RoleResponse[] Roles);
