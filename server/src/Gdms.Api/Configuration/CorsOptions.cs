namespace Gdms.Api.Configuration;

/// <summary>
/// Represents the allowed origins configuration for browser-based clients.
/// </summary>
public sealed class CorsOptions
{
    /// <summary>
    /// Gets or sets the logical policy name applied to HTTP requests.
    /// </summary>
    public string PolicyName { get; set; } = "GdmsClient";

    /// <summary>
    /// Gets or sets the list of explicit origins allowed outside development.
    /// </summary>
    public string[] AllowedOrigins { get; set; } = [];

    /// <summary>
    /// Gets or sets whether any origin should be allowed in development.
    /// </summary>
    public bool AllowAnyOriginInDevelopment { get; set; } = true;
}
