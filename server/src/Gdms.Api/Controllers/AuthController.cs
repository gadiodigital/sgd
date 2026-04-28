using System.Security.Claims;
using Gdms.Application.Identity;
using Gdms.Contracts.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes bootstrap and local authentication endpoints.
/// </summary>
[ApiController]
[Route("api/auth")]
public sealed class AuthController : ControllerBase
{
    private readonly AuthService _authService;

    /// <summary>
    /// Initializes the controller with the authentication service.
    /// </summary>
    public AuthController(AuthService authService)
    {
        _authService = authService;
    }

    /// <summary>
    /// Bootstraps the first platform administrator when none exists yet.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("bootstrap-platform-admin")]
    [ProducesResponseType(typeof(AuthenticatedSessionResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AuthenticatedSessionResponse>> BootstrapPlatformAdmin(
        [FromBody] BootstrapTenantAdminRequest request,
        CancellationToken cancellationToken)
    {
        var session = await _authService.BootstrapPlatformAdminAsync(
            request.TenantCode,
            request.Email,
            request.FullName,
            request.Password,
            cancellationToken);

        return Created("/api/auth/me", MapSession(session));
    }

    /// <summary>
    /// Bootstraps the first tenant administrator when no users exist yet.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("bootstrap-tenant-admin")]
    [ProducesResponseType(typeof(AuthenticatedSessionResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AuthenticatedSessionResponse>> BootstrapTenantAdmin(
        [FromBody] BootstrapTenantAdminRequest request,
        CancellationToken cancellationToken)
    {
        var session = await _authService.BootstrapTenantAdminAsync(
            request.TenantCode,
            request.Email,
            request.FullName,
            request.Password,
            cancellationToken);

        return Created("/api/auth/me", MapSession(session));
    }

    /// <summary>
    /// Authenticates a user with organization-scoped local credentials.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("token")]
    [ProducesResponseType(typeof(AuthenticatedSessionResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthenticatedSessionResponse>> IssueToken(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        var session = await _authService.LoginAsync(
            request.TenantCode,
            request.Email,
            request.Password,
            cancellationToken);

        return Ok(MapSession(session));
    }

    /// <summary>
    /// Returns the currently authenticated principal extracted from JWT claims.
    /// </summary>
    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType(typeof(CurrentIdentityResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult<CurrentIdentityResponse> Me()
    {
        return Ok(new CurrentIdentityResponse(
            RequireGuidClaim(ClaimTypes.NameIdentifier),
            RequireGuidClaim("tenant_id"),
            RequireClaim("tenant_code"),
            RequireClaim(ClaimTypes.Email),
            RequireClaim(ClaimTypes.Name),
            User.Claims.Where(claim => claim.Type == ClaimTypes.Role).Select(claim => claim.Value).ToArray()));
    }

    private AuthenticatedSessionResponse MapSession(AuthenticatedSession session)
    {
        return new AuthenticatedSessionResponse(
            session.AccessToken.AccessToken,
            session.AccessToken.TokenType,
            session.AccessToken.ExpiresAtUtc,
            session.AccessToken.ExpiresInSeconds,
            session.MustChangePassword,
            session.User.Id,
            session.User.Email,
            session.User.FullName,
            session.User.Roles.Select(role => role.Code).ToArray(),
            session.Tenant.Id,
            session.Tenant.Code,
            session.Tenant.Name);
    }

    private Guid RequireGuidClaim(string claimType)
    {
        return Guid.Parse(RequireClaim(claimType));
    }

    private string RequireClaim(string claimType)
    {
        var value = User.FindFirstValue(claimType);
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new UnauthorizedAccessException($"Falta el claim requerido '{claimType}'.");
        }

        return value;
    }
}
