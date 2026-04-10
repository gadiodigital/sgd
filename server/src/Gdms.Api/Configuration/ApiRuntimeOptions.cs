namespace Gdms.Api.Configuration;

/// <summary>
/// Runtime toggles for local and preproduction-like hosting behavior.
/// </summary>
public sealed class ApiRuntimeOptions
{
    /// <summary>
    /// Enables ASP.NET Core HTTPS redirection middleware.
    /// </summary>
    public bool EnableHttpsRedirection { get; set; } = true;
}
