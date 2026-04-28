using Gdms.Contracts.Tenants;

namespace Gdms.ApiContractTests;

public sealed class CurrentOrganizationControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public CurrentOrganizationControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetCurrent_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/organization/current");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetCurrent_Should_Return_Current_Organization()
    {
        var organization = await CreateOrganizationAsync("current_org", "Current Organization");
        using var client = _factory.CreateClientForTenant(organization.Id, "TENANT_ADMIN");

        var response = await client.GetAsync("/api/organization/current");

        response.EnsureSuccessStatusCode();
        var payload = await response.Content.ReadFromJsonAsync<TenantResponse>();

        Assert.NotNull(payload);
        Assert.Equal(organization.Id, payload!.Id);
        Assert.Equal("CURRENT_ORG", payload.Code);
        Assert.Equal("Current Organization", payload.Name);
    }

    [PostgresContractFact]
    public async Task GetCurrent_Should_Return_404_When_Claimed_Organization_Does_Not_Exist()
    {
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");

        var response = await client.GetAsync("/api/organization/current");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private async Task<Tenant> CreateOrganizationAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }
}
