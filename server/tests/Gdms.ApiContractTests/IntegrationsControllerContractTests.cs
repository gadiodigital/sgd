using Gdms.Contracts.Integrations;

namespace Gdms.ApiContractTests;

public sealed class IntegrationsControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public IntegrationsControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_integrations_unauth", "API Integrations Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/integrations/status");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_integrations_forbid", "API Integrations Forbid");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "AUDITOR");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/integrations/status");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_Configured_Integration_Statuses_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_integrations_ok", "API Integrations OK");
        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        using var platformClient = _factory.CreateClientForPlatformAdmin();

        var tenantResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/integrations/status");
        var platformResponse = await platformClient.GetAsync($"/api/tenants/{tenant.Id}/integrations/status");

        tenantResponse.EnsureSuccessStatusCode();
        platformResponse.EnsureSuccessStatusCode();

        var tenantPayload = await tenantResponse.Content.ReadFromJsonAsync<IntegrationStatusResponse[]>();
        var platformPayload = await platformResponse.Content.ReadFromJsonAsync<IntegrationStatusResponse[]>();

        Assert.NotNull(tenantPayload);
        Assert.NotNull(platformPayload);
        Assert.Equal(5, tenantPayload!.Length);
        Assert.Equal(
            tenantPayload.Select(item => (item.Code, item.Status, item.Detail)).OrderBy(item => item.Code),
            platformPayload!.Select(item => (item.Code, item.Status, item.Detail)).OrderBy(item => item.Code));

        Assert.Contains(tenantPayload, item =>
            item.Code == "POSTGRES" &&
            item.Category == "DATABASE" &&
            item.Status == "READY" &&
            item.Detail.Contains("Fuente de verdad relacional configurada.", StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Code == "FIREBASE_REMOTE_CONFIG" &&
            item.Category == "CONFIG" &&
            item.Status == "EMULATOR" &&
            item.Detail.Contains("gdms-local", StringComparison.OrdinalIgnoreCase) &&
            item.Detail.Contains("gdms-dev", StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Code == "FIRESTORE" &&
            item.Category == "CONFIG" &&
            item.Status == "EMULATOR" &&
            item.Detail.Contains("Persistencia no relacional", StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Code == "DOCUMENT_STORAGE" &&
            item.Category == "STORAGE" &&
            item.Status == "READY" &&
            item.Detail.Contains(Path.GetTempPath(), StringComparison.OrdinalIgnoreCase));

        Assert.Contains(tenantPayload, item =>
            item.Code == "SIGNATURE_PROVIDER" &&
            item.Category == "SIGNATURE" &&
            item.Status == "INTERNAL" &&
            item.Detail.Contains("Proveedor INTERNAL", StringComparison.OrdinalIgnoreCase));
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }
}
