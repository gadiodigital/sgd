using Gdms.Contracts.Identity;

namespace Gdms.ApiContractTests;

public sealed class RolesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public RolesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/roles");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_Assignable_Roles_For_Authenticated_Callers()
    {
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "AUDITOR");

        var response = await client.GetAsync("/api/roles");

        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<RoleResponse[]>();

        Assert.NotNull(payload);
        Assert.Contains(payload!, role => role.Code == "PLATFORM_ADMIN");
        Assert.Contains(payload, role => role.Code == "TENANT_ADMIN");
        Assert.Contains(payload, role => role.Code == "DOCUMENT_OPERATOR");
        Assert.Contains(payload, role => role.Code == "AUDITOR");
    }
}
