namespace Gdms.Infrastructure.Configuration;

/// <summary>
/// Represents the signature provider settings required by the platform.
/// </summary>
public sealed class SignatureProviderOptions
{
    /// <summary>
    /// Gets or sets the current provider operating mode.
    /// </summary>
    public string Mode { get; set; } = "INTERNAL";

    /// <summary>
    /// Gets or sets the provider code exposed to the application.
    /// </summary>
    public string ProviderCode { get; set; } = "INTERNAL";

    /// <summary>
    /// Gets or sets whether provider references should be generated.
    /// </summary>
    public bool GenerateReferences { get; set; } = true;
}
