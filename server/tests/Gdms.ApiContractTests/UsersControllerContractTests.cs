using Gdms.Contracts.Identity;

namespace Gdms.ApiContractTests;

public sealed class UsersControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public UsersControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task Users_Endpoints_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        var tenant = await CreateTenantAsync("api_users_unauth", "API Users Unauth");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClient();

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/users");
        var getResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/users/{actor.Id}");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users",
            BuildCreateUserRequest($"new.{Guid.NewGuid():N}@tenant.ar"));

        Assert.Equal(HttpStatusCode.Unauthorized, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, getResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Users_Endpoints_Should_Return_403_When_Tenant_Claim_Does_Not_Match()
    {
        var tenant = await CreateTenantAsync("api_users_forbid", "API Users Forbid");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(Guid.NewGuid(), "TENANT_ADMIN");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var listResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/users");
        var getResponse = await client.GetAsync($"/api/tenants/{tenant.Id}/users/{actor.Id}");
        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users",
            BuildCreateUserRequest($"new.{Guid.NewGuid():N}@tenant.ar"));

        Assert.Equal(HttpStatusCode.Forbidden, listResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, getResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_And_AssignRole_Should_Return_403_When_Role_Is_Not_Allowed()
    {
        var tenant = await CreateTenantAsync("api_users_role", "API Users Role");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        var existingUser = await CreateUserAsync(tenant.Id, $"existing.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var createResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users",
            BuildCreateUserRequest($"new.{Guid.NewGuid():N}@tenant.ar"));
        var assignResponse = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users/{existingUser.Id}/roles",
            new AssignRoleRequest { RoleCode = "DOCUMENT_OPERATOR" });

        Assert.Equal(HttpStatusCode.Forbidden, createResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, assignResponse.StatusCode);
    }

    [PostgresContractFact]
    public async Task Create_Should_Return_400_When_Role_Code_Is_Invalid()
    {
        var tenant = await CreateTenantAsync("api_users_invalid", "API Users Invalid");
        var actor = await CreateUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar");
        using var client = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());

        var response = await client.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users",
            new CreateUserRequest
            {
                Email = $"new.{Guid.NewGuid():N}@tenant.ar",
                FullName = "Usuario Invalido",
                TemporaryPassword = "TemporalPass123!",
                InitialStatus = "ACTIVE",
                RoleCodes = ["INVALID_ROLE"],
                RequirePasswordChange = true
            });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Users_Endpoints_Should_Return_Expected_Payloads_For_Authorized_Callers()
    {
        var tenant = await CreateTenantAsync("api_users_ok", "API Users OK");
        var admin = await CreateUserAsync(tenant.Id, $"admin.{Guid.NewGuid():N}@tenant.ar");
        var listedUser = await CreateUserAsync(tenant.Id, $"listed.{Guid.NewGuid():N}@tenant.ar", "Usuario Listado");

        using var listClient = _factory.CreateClientForTenant(tenant.Id, "AUDITOR");
        listClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        listClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, listedUser.Id.ToString());

        using var adminClient = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN");
        adminClient.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        adminClient.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, admin.Id.ToString());

        var listResponse = await listClient.GetAsync($"/api/tenants/{tenant.Id}/users");
        var getResponse = await listClient.GetAsync($"/api/tenants/{tenant.Id}/users/{listedUser.Id}");
        var createResponse = await adminClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users",
            BuildCreateUserRequest($"new.{Guid.NewGuid():N}@tenant.ar"));

        listResponse.EnsureSuccessStatusCode();
        getResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var listPayload = await listResponse.Content.ReadFromJsonAsync<UserResponse[]>();
        var getPayload = await getResponse.Content.ReadFromJsonAsync<UserResponse>();
        var createdPayload = await createResponse.Content.ReadFromJsonAsync<UserResponse>();

        Assert.NotNull(listPayload);
        Assert.Contains(listPayload!, item => item.Id == listedUser.Id && item.Email == listedUser.Email);

        Assert.NotNull(getPayload);
        Assert.Equal(listedUser.Id, getPayload!.Id);
        Assert.Equal("USUARIO LISTADO", getPayload.FullName.ToUpperInvariant());
        Assert.Equal("ACTIVE", getPayload.Status);

        Assert.NotNull(createdPayload);
        Assert.Equal(tenant.Id, createdPayload!.TenantId);
        Assert.Equal("PENDING", createdPayload.Status);
        Assert.Contains(createdPayload.Roles, role => role.Code == "AUDITOR");

        var persistedCreated = await new PostgresUserRepository(_factory.DataSource)
            .GetByIdAsync(tenant.Id, createdPayload.Id, CancellationToken.None);

        Assert.NotNull(persistedCreated);
        Assert.Contains(persistedCreated!.Roles, role => role.Code == "AUDITOR");

        var assignResponse = await adminClient.PostAsJsonAsync(
            $"/api/tenants/{tenant.Id}/users/{createdPayload.Id}/roles",
            new AssignRoleRequest { RoleCode = "DOCUMENT_OPERATOR" });

        assignResponse.EnsureSuccessStatusCode();

        var assignedPayload = await assignResponse.Content.ReadFromJsonAsync<UserResponse>();
        Assert.NotNull(assignedPayload);
        Assert.Contains(assignedPayload!.Roles, role => role.Code == "DOCUMENT_OPERATOR");

        var persistedAssigned = await new PostgresUserRepository(_factory.DataSource)
            .GetByIdAsync(tenant.Id, createdPayload.Id, CancellationToken.None);

        Assert.NotNull(persistedAssigned);
        Assert.Contains(persistedAssigned!.Roles, role => role.Code == "DOCUMENT_OPERATOR");
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> CreateUserAsync(Guid tenantId, string email, string fullName = "API User")
    {
        var user = User.Create(tenantId, email, fullName, UserStatus.Active, DateTimeOffset.UtcNow);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private static CreateUserRequest BuildCreateUserRequest(string email)
    {
        return new CreateUserRequest
        {
            Email = email,
            FullName = " Nuevo Usuario ",
            TemporaryPassword = "TemporalPass123!",
            InitialStatus = "PENDING",
            RoleCodes = ["auditor"],
            RequirePasswordChange = true
        };
    }
}
