namespace Gdms.Infrastructure.Configuration;

/// <summary>
/// Represents the Firebase settings required by the platform.
/// </summary>
public sealed class FirebaseOptions
{
    /// <summary>
    /// Gets or sets the Firebase project identifier.
    /// </summary>
    public string ProjectId { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets whether the local emulator is enabled.
    /// </summary>
    public bool UseEmulator { get; set; }

    /// <summary>
    /// Gets or sets the default remote config template name.
    /// </summary>
    public string RemoteConfigTemplateName { get; set; } = "gdms-default";
}
