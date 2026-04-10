namespace Gdms.ApiContractTests;

public sealed class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "TestScheme";
    public const string EnabledHeader = "X-Test-Auth";
    public const string TenantIdHeader = "X-Test-TenantId";
    public const string TenantCodeHeader = "X-Test-TenantCode";
    public const string RolesHeader = "X-Test-Roles";
    public const string UserIdHeader = "X-Test-UserId";
    public const string EmailHeader = "X-Test-Email";
    public const string FullNameHeader = "X-Test-FullName";

    public TestAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(EnabledHeader, out var enabledValues) ||
            !string.Equals(enabledValues.ToString(), "true", StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var userId = Request.Headers.TryGetValue(UserIdHeader, out var userIdValues) &&
            Guid.TryParse(userIdValues.ToString(), out var parsedUserId)
            ? parsedUserId
            : Guid.Parse("11111111-1111-1111-1111-111111111111");

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(
                ClaimTypes.Name,
                Request.Headers.TryGetValue(FullNameHeader, out var fullNameValues) &&
                !string.IsNullOrWhiteSpace(fullNameValues.ToString())
                    ? fullNameValues.ToString()
                    : "Test User")
        };

        if (Request.Headers.TryGetValue(TenantIdHeader, out var tenantIdValues) &&
            Guid.TryParse(tenantIdValues.ToString(), out var tenantId))
        {
            claims.Add(new Claim("tenant_id", tenantId.ToString()));
        }

        if (Request.Headers.TryGetValue(TenantCodeHeader, out var tenantCodeValues) &&
            !string.IsNullOrWhiteSpace(tenantCodeValues.ToString()))
        {
            claims.Add(new Claim("tenant_code", tenantCodeValues.ToString()));
        }

        if (Request.Headers.TryGetValue(EmailHeader, out var emailValues) &&
            !string.IsNullOrWhiteSpace(emailValues.ToString()))
        {
            claims.Add(new Claim(ClaimTypes.Email, emailValues.ToString()));
        }

        if (Request.Headers.TryGetValue(RolesHeader, out var roleValues))
        {
            foreach (var role in roleValues.ToString().Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }
        }

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
