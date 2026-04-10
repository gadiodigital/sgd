using Gdms.Contracts.Common;

namespace Gdms.ApiContractTests;

public sealed class HealthControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public HealthControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Get_Should_Return_Public_Health_Payload()
    {
        using var client = _factory.CreateClient();
        var before = DateTimeOffset.UtcNow.AddMinutes(-1);

        var response = await client.GetAsync("/api/health");

        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<HealthResponse>();
        var after = DateTimeOffset.UtcNow.AddMinutes(1);

        Assert.NotNull(payload);
        Assert.Equal("Healthy", payload!.Status);
        Assert.Equal("/swagger", payload.Documentation);
        Assert.InRange(payload.UtcNow, before, after);
    }
}
