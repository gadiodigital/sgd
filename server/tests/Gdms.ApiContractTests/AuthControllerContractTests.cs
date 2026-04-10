using Gdms.Contracts.Auth;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.ApiContractTests;

public sealed class AuthControllerContractTests : IClassFixture<ApiContractTestFactory>
{
    private readonly ApiContractTestFactory _factory;

    public AuthControllerContractTests(ApiContractTestFactory factory)
    {
        _factory = factory;
    }

    [PostgresContractFact]
    public async Task BootstrapPlatformAdmin_Should_Return_201_When_No_Platform_Admin_Exists()
    {
        await using var isolatedFactory = new ApiContractTestFactory();
        await isolatedFactory.InitializeAsync();
        var tenant = await new PostgresTenantRepository(isolatedFactory.DataSource).AddAsync(
            Tenant.Create("auth_platform_boot", "Auth Platform Boot", "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
        using var client = isolatedFactory.CreateClient();

        var response = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-platform-admin",
            BuildBootstrapRequest(tenant.Code, $"platform.{Guid.NewGuid():N}@tenant.ar", "Platform Admin"));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        Assert.NotNull(payload);
        Assert.Equal(tenant.Id, payload!.TenantId);
        Assert.Equal(tenant.Code, payload.TenantCode);
        Assert.Contains("PLATFORM_ADMIN", payload.Roles);

        var persisted = await new PostgresUserRepository(isolatedFactory.DataSource)
            .GetByIdAsync(tenant.Id, payload.UserId, CancellationToken.None);

        Assert.NotNull(persisted);
        Assert.Contains(persisted!.Roles, role => role.Code == "PLATFORM_ADMIN");
    }

    [PostgresContractFact]
    public async Task BootstrapPlatformAdmin_Should_Return_400_When_Platform_Admin_Already_Exists()
    {
        var tenant = await CreateTenantAsync("auth_platform_taken", "Auth Platform Taken");
        await SeedUserAsync(tenant.Id, $"platform.{Guid.NewGuid():N}@tenant.ar", "PLATFORM_ADMIN");
        using var client = _factory.CreateClient();

        var response = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-platform-admin",
            BuildBootstrapRequest(tenant.Code, $"new.{Guid.NewGuid():N}@tenant.ar", "Another Platform Admin"));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.NotNull(problem);
        Assert.Contains("PLATFORM_ADMIN", problem!.Detail, StringComparison.OrdinalIgnoreCase);
    }

    [PostgresContractFact]
    public async Task BootstrapTenantAdmin_Should_Return_Expected_Responses_For_First_And_Repeated_Bootstrap()
    {
        var tenant = await CreateTenantAsync("auth_tenant_boot", "Auth Tenant Boot");
        using var client = _factory.CreateClient();

        var firstResponse = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-tenant-admin",
            BuildBootstrapRequest(tenant.Code, $"tenant.{Guid.NewGuid():N}@tenant.ar", "Tenant Admin"));
        var repeatedResponse = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-tenant-admin",
            BuildBootstrapRequest(tenant.Code, $"again.{Guid.NewGuid():N}@tenant.ar", "Tenant Admin Again"));

        Assert.Equal(HttpStatusCode.Created, firstResponse.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, repeatedResponse.StatusCode);

        var payload = await firstResponse.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        var repeatedProblem = await repeatedResponse.Content.ReadFromJsonAsync<ProblemDetails>();

        Assert.NotNull(payload);
        Assert.Contains("TENANT_ADMIN", payload!.Roles);
        Assert.NotNull(repeatedProblem);
        Assert.Contains("tenant no tiene usuarios", repeatedProblem!.Detail, StringComparison.OrdinalIgnoreCase);
    }

    [PostgresContractFact]
    public async Task IssueToken_Should_Return_200_For_Valid_Credentials_And_401_For_Invalid_Password()
    {
        var tenant = await CreateTenantAsync("auth_login_contract", "Auth Login Contract");
        await BootstrapTenantAdminAsync(tenant.Code, "auth@login.ar", "Login Admin", "SecurePass!123");
        using var client = _factory.CreateClient();

        var successResponse = await client.PostAsJsonAsync(
            "/api/auth/token",
            new LoginRequest
            {
                TenantCode = tenant.Code.ToLowerInvariant(),
                Email = "AUTH@login.ar",
                Password = "SecurePass!123"
            });
        var failureResponse = await client.PostAsJsonAsync(
            "/api/auth/token",
            new LoginRequest
            {
                TenantCode = tenant.Code,
                Email = "auth@login.ar",
                Password = "bad-password!"
            });

        successResponse.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Unauthorized, failureResponse.StatusCode);

        var payload = await successResponse.Content.ReadFromJsonAsync<AuthenticatedSessionResponse>();
        var problem = await failureResponse.Content.ReadFromJsonAsync<ProblemDetails>();

        Assert.NotNull(payload);
        Assert.Equal("Bearer", payload!.TokenType);
        Assert.Equal(tenant.Id, payload.TenantId);
        Assert.Equal("AUTH@LOGIN.AR", payload.Email.ToUpperInvariant());
        Assert.NotEmpty(payload.AccessToken);

        Assert.NotNull(problem);
        Assert.Contains("Credenciales inválidas", problem!.Detail, StringComparison.OrdinalIgnoreCase);
    }

    [PostgresContractFact]
    public async Task Me_Should_Return_401_When_Request_Is_Unauthenticated()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/auth/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [PostgresContractFact]
    public async Task Me_Should_Return_Current_Identity_For_Authenticated_Caller()
    {
        var tenant = await CreateTenantAsync("auth_me", "Auth Me");
        var actor = await SeedUserAsync(tenant.Id, $"actor.{Guid.NewGuid():N}@tenant.ar", "TENANT_ADMIN", "Auth Me Actor");
        using var client = _factory.CreateClientForTenant(tenant.Id, "TENANT_ADMIN", "AUDITOR");
        client.DefaultRequestHeaders.Remove(TestAuthHandler.UserIdHeader);
        client.DefaultRequestHeaders.Remove(TestAuthHandler.TenantCodeHeader);
        client.DefaultRequestHeaders.Remove(TestAuthHandler.EmailHeader);
        client.DefaultRequestHeaders.Remove(TestAuthHandler.FullNameHeader);
        client.DefaultRequestHeaders.Add(TestAuthHandler.UserIdHeader, actor.Id.ToString());
        client.DefaultRequestHeaders.Add(TestAuthHandler.TenantCodeHeader, tenant.Code);
        client.DefaultRequestHeaders.Add(TestAuthHandler.EmailHeader, actor.Email);
        client.DefaultRequestHeaders.Add(TestAuthHandler.FullNameHeader, actor.FullName);

        var response = await client.GetAsync("/api/auth/me");

        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<CurrentIdentityResponse>();

        Assert.NotNull(payload);
        Assert.Equal(actor.Id, payload!.UserId);
        Assert.Equal(tenant.Id, payload.TenantId);
        Assert.Equal(tenant.Code, payload.TenantCode);
        Assert.Equal(actor.Email, payload.Email);
        Assert.Equal(actor.FullName, payload.FullName);
        Assert.Contains("TENANT_ADMIN", payload.Roles);
        Assert.Contains("AUDITOR", payload.Roles);
    }

    private async Task<Tenant> CreateTenantAsync(string code, string name)
    {
        return await new PostgresTenantRepository(_factory.DataSource).AddAsync(
            Tenant.Create(code, name, "CORPORATE", "AR", DateTimeOffset.UtcNow),
            CancellationToken.None);
    }

    private async Task<User> SeedUserAsync(Guid tenantId, string email, string roleCode, string fullName = "Seed User")
    {
        var role = await new PostgresRoleRepository(_factory.DataSource)
            .GetByCodeAsync(roleCode, CancellationToken.None);
        var user = User.Create(tenantId, email, fullName, UserStatus.Active, DateTimeOffset.UtcNow);
        user.AssignRole(role!);
        return await new PostgresUserRepository(_factory.DataSource)
            .AddAsync(user, "hashed-password", false, CancellationToken.None);
    }

    private async Task BootstrapTenantAdminAsync(string tenantCode, string email, string fullName, string password)
    {
        using var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync(
            "/api/auth/bootstrap-tenant-admin",
            BuildBootstrapRequest(tenantCode, email, fullName, password));
        response.EnsureSuccessStatusCode();
    }

    private static BootstrapTenantAdminRequest BuildBootstrapRequest(
        string tenantCode,
        string email,
        string fullName,
        string password = "SecurePass!123")
    {
        return new BootstrapTenantAdminRequest
        {
            TenantCode = $" {tenantCode.ToLowerInvariant()} ",
            Email = email,
            FullName = $" {fullName} ",
            Password = password
        };
    }
}
