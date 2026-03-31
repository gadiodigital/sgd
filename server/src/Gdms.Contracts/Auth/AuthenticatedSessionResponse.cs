namespace Gdms.Contracts.Auth;

/// <summary>
/// Represents the response returned after a successful authentication workflow.
/// </summary>
public sealed record AuthenticatedSessionResponse(
    string AccessToken,
    string TokenType,
    DateTimeOffset ExpiresAtUtc,
    long ExpiresInSeconds,
    bool MustChangePassword,
    Guid UserId,
    string Email,
    string FullName,
    string[] Roles,
    Guid TenantId,
    string TenantCode,
    string TenantName);
