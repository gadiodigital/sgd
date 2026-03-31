namespace Gdms.Contracts.Auth;

/// <summary>
/// Represents the authenticated principal currently attached to the HTTP request.
/// </summary>
public sealed record CurrentIdentityResponse(
    Guid UserId,
    Guid TenantId,
    string TenantCode,
    string Email,
    string FullName,
    string[] Roles);
