using Gdms.Application.Identity;
using Gdms.Domain.Identity;
using Gdms.Domain.Tenancy;

namespace Gdms.Application.Abstractions.Security;

/// <summary>
/// Issues access tokens for authenticated tenant users.
/// </summary>
public interface IAccessTokenIssuer
{
    /// <summary>
    /// Creates an access token for the specified tenant user.
    /// </summary>
    Task<AuthenticatedAccessToken> IssueAsync(
        Tenant tenant,
        User user,
        CancellationToken cancellationToken);
}
