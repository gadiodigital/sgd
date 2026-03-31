namespace Gdms.Application.Identity;

/// <summary>
/// Represents an issued bearer access token.
/// </summary>
public sealed record AuthenticatedAccessToken(
    string AccessToken,
    string TokenType,
    DateTimeOffset ExpiresAtUtc,
    long ExpiresInSeconds);
