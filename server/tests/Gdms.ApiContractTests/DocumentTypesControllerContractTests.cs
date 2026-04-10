using Gdms.Contracts.Documents;

namespace Gdms.ApiContractTests;

public sealed class DocumentTypesControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public DocumentTypesControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_doc_types_unauth", "API Doc Types Unauth");
        using var client = _factory.CreateClient();

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/document-types");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_doc_types_forbid", "API Doc Types Forbid");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "AUDITOR");

        var response = await client.GetAsync($"/api/tenants/{tenant.Id}/document-types");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_Seeded_Document_Types_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_doc_types_ok", "API Doc Types OK");
        using var tenantClient = _factory.CreateClientForTenant(tenant.Id, "DOCUMENT_OPERATOR");
        using var platformClient = _factory.CreateClientForPlatformAdmin();

        var tenantResponse = await tenantClient.GetAsync($"/api/tenants/{tenant.Id}/document-types");
        var platformResponse = await platformClient.GetAsync($"/api/tenants/{tenant.Id}/document-types");

        tenantResponse.EnsureSuccessStatusCode();
        platformResponse.EnsureSuccessStatusCode();

        var tenantPayload = await tenantResponse.Content.ReadFromJsonAsync<DocumentTypeResponse[]>();
        var platformPayload = await platformResponse.Content.ReadFromJsonAsync<DocumentTypeResponse[]>();

        Assert.NotNull(tenantPayload);
        Assert.NotNull(platformPayload);
        Assert.Contains(tenantPayload!, item => item.Code == "CONTRACT" && item.TenantId is null);
        Assert.Contains(tenantPayload, item => item.Code == "INVOICE" && item.Sector == "CORPORATE");
        Assert.Equal(
            tenantPayload.Select(item => item.Code).OrderBy(code => code),
            platformPayload!.Select(item => item.Code).OrderBy(code => code));

        var contractType = tenantPayload.Single(item => item.Code == "CONTRACT");
        Assert.True(contractType.IsActive);
        Assert.Equal("Contrato", contractType.Name);
        Assert.True(contractType.MetadataSchema.TryGetProperty("counterparty", out var counterparty));
        Assert.Equal("string", counterparty.GetProperty("type").GetString());
        Assert.True(counterparty.GetProperty("required").GetBoolean());
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }
}
