using Gdms.Application.Abstractions.Integrations;

namespace Gdms.Application.Integrations;

/// <summary>
/// Builds a lightweight overview of configured platform integrations.
/// </summary>
public sealed class IntegrationsService
{
    private readonly IIntegrationStatusCatalogProvider _catalogProvider;

    /// <summary>
    /// Initializes the service with current infrastructure options.
    /// </summary>
    public IntegrationsService(IIntegrationStatusCatalogProvider catalogProvider)
    {
        _catalogProvider = catalogProvider;
    }

    /// <summary>
    /// Lists the current platform integrations visible to operators.
    /// </summary>
    public IReadOnlyCollection<IntegrationStatusSnapshot> List()
    {
        return _catalogProvider.List();
    }
}
