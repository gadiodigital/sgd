using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Gdms.Application.Abstractions.Security;
using Gdms.Application.Identity;
using Gdms.Domain.Identity;
using Gdms.Domain.Tenancy;
using Gdms.Infrastructure.Configuration;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Gdms.Infrastructure.Security;

/// <summary>
/// Issues JWT bearer access tokens for authenticated tenant users.
/// </summary>
public sealed class JwtAccessTokenIssuer : IAccessTokenIssuer
{
    private readonly JwtOptions _options;
    private readonly JwtSigningKeyProvider _signingKeyProvider;

    /// <summary>
    /// Initializes the issuer with JWT configuration.
    /// </summary>
    public JwtAccessTokenIssuer(
        IOptions<JwtOptions> options,
        JwtSigningKeyProvider signingKeyProvider)
    {
        _options = options.Value;
        _signingKeyProvider = signingKeyProvider;
    }

    /// <inheritdoc />
    public Task<AuthenticatedAccessToken> IssueAsync(
        Tenant tenant,
        User user,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var issuedAtUtc = DateTimeOffset.UtcNow;
        var expiresAtUtc = issuedAtUtc.AddMinutes(_options.AccessTokenMinutes);
        var signingCredentials = new SigningCredentials(_signingKeyProvider.SecurityKey, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Email, user.Email),
            new("tenant_id", tenant.Id.ToString()),
            new("tenant_code", tenant.Code)
        };

        claims.AddRange(user.Roles.Select(role => new Claim(ClaimTypes.Role, role.Code)));

        var jwt = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: issuedAtUtc.UtcDateTime,
            expires: expiresAtUtc.UtcDateTime,
            signingCredentials: signingCredentials);

        var token = new JwtSecurityTokenHandler().WriteToken(jwt);
        return Task.FromResult(new AuthenticatedAccessToken(
            token,
            "Bearer",
            expiresAtUtc,
            Convert.ToInt64(TimeSpan.FromMinutes(_options.AccessTokenMinutes).TotalSeconds)));
    }
}
