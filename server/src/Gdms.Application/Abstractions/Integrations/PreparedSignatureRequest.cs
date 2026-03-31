namespace Gdms.Application.Abstractions.Integrations;

/// <summary>
/// Represents the provider metadata generated when preparing a signature request.
/// </summary>
public sealed record PreparedSignatureRequest(
    string ProviderCode,
    string? ExternalReference);
