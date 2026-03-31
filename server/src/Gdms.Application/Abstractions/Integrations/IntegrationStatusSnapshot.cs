namespace Gdms.Application.Abstractions.Integrations;

/// <summary>
/// Represents the current status of an external or infrastructural integration.
/// </summary>
public sealed record IntegrationStatusSnapshot(
    string Code,
    string DisplayName,
    string Category,
    string Status,
    string Detail);
