using Gdms.Domain.Identity;
using Gdms.Domain.Tenancy;

namespace Gdms.Application.Identity;

/// <summary>
/// Represents the result of a successful authentication workflow.
/// </summary>
public sealed record AuthenticatedSession(
    Tenant Tenant,
    User User,
    bool MustChangePassword,
    AuthenticatedAccessToken AccessToken);
