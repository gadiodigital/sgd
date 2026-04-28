using Gdms.Contracts.Tenants;

namespace Gdms.ApiContractTests;

public sealed class TenantsControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public TenantsControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task GetAll_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/tenants");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_Should_Allow_Unauthenticated_Bootstrap_When_No_Platform_Admin_Exists()
    {
        await using var isolatedFactory = new ApiContractTestFactory();
        await isolatedFactory.InitializeAsync();
        using var client = isolatedFactory.CreateClient();

        var response = await client.PostAsJsonAsync(
            "/api/tenants",
            new CreateTenantRequest
            {
                Code = " bootstrap_tenant ",
                Name = " Tenant Bootstrap ",
                Sector = "CORPORATE",
                PrimaryCountryCode = "ar"
            });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<TenantResponse>();
        Assert.NotNull(payload);
        Assert.Equal("BOOTSTRAP_TENANT", payload!.Code);
        Assert.Equal("Tenant Bootstrap", payload.Name);
        Assert.Equal("CORPORATE", payload.Sector);
        Assert.Equal("AR", payload.PrimaryCountryCode);

        var persisted = (await new PostgresTenantRepository(isolatedFactory.DataSource)
            .ListAsync(CancellationToken.None))
            .Single(item => item.Id == payload.Id);

        Assert.Equal("BOOTSTRAP_TENANT", persisted.Code);
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_401_When_Platform_Admin_Already_Exists_And_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("seed_platform", "Seed Platform");
        await SeedPlatformAdminAsync(tenant.Id, $"platform.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/tenants", BuildCreateTenantRequest("tenant_unauth"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_403_When_Platform_Admin_Already_Exists_And_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("seed_forbid", "Seed Forbid");
        var actor = await SeedPlatformAdminAsync(tenant.Id, $"platform.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PostAsJsonAsync("/api/tenants", BuildCreateTenantRequest("tenant_forbid"));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Tenants_Endpoints_Should_List_And_Block_Additional_Create_For_Platform_Admin()
    {
        var seedTenant = await CreateTenantAsync("seed_ok", "Seed OK");
        var platformAdmin = await SeedPlatformAdminAsync(seedTenant.Id, $"platform.{Guid.NewGuid():N}@tenant.ar");
        await CreateTenantAsync("listed_a", "Listed A");

        using var client = _factory.CreateClientForPlatformAdmin();
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, platformAdmin.Id.ToString());

        var createResponse = await client.PostAsJsonAsync("/api/tenants", BuildCreateTenantRequest("tenant_ok"));
        var listResponse = await client.GetAsync("/api/tenants");

        Assert.Equal(HttpStatusCode.Conflict, createResponse.StatusCode);
        listResponse.EnsureSuccessStatusCode();

        var listPayload = await listResponse.Content.ReadFromJsonAsync<TenantResponse[]>();

        Assert.NotNull(listPayload);
        Assert.Contains(listPayload!, item => item.Code == "SEED_OK");
        Assert.Contains(listPayload, item => item.Code == "LISTED_A");
        Assert.DoesNotContain(listPayload, item => item.Code == "TENANT_OK");
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> SeedPlatformAdminAsync(Guid tenantId, string email)
    {
        var role = await new PostgresRoleRepository(_factory.DataSource)
            .GetByCodeAsync("PLATFORM_ADMIN", CancellationToken.None);
        var user = User.Create(tenantId, email, "Platform Admin", UserStatus.Active, DateTimeOffset.UtcNow);
        user.AssignRole(role!);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private static CreateTenantRequest BuildCreateTenantRequest(string suffix)
    {
        return new CreateTenantRequest
        {
            Code = $" {suffix} ",
            Name = $" Tenant {suffix} ",
            Sector = "CORPORATE",
            PrimaryCountryCode = "ar"
        };
    }
}
