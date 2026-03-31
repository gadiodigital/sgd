namespace Gdms.Application.Abstractions.Integrations;

/// <summary>
/// Defines the port used to resolve configured integration statuses.
/// </summary>
public interface IIntegrationStatusCatalogProvider
{
    /// <summary>
    /// Lists the current configured integrations.
    /// </summary>
    IReadOnlyCollection<IntegrationStatusSnapshot> List();
}
