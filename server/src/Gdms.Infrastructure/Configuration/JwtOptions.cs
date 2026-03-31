namespace Gdms.Infrastructure.Configuration;

/// <summary>
/// Represents the configuration used to issue and validate local JWT access tokens.
/// </summary>
public sealed class JwtOptions
{
    /// <summary>
    /// Gets or sets the JWT issuer.
    /// </summary>
    public string Issuer { get; init; } = "gdms-api";

    /// <summary>
    /// Gets or sets the JWT audience.
    /// </summary>
    public string Audience { get; init; } = "gdms-clients";

    /// <summary>
    /// Gets or sets the symmetric signing key.
    /// </summary>
    public string SigningKey { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the access token lifetime in minutes.
    /// </summary>
    public int AccessTokenMinutes { get; init; } = 60;
}
