namespace Gdms.Contracts.Integrations;

/// <summary>
/// Represents the status of a configured integration exposed by the API.
/// </summary>
public sealed record IntegrationStatusResponse(
    string Code,
    string DisplayName,
    string Category,
    string Status,
    string Detail);
