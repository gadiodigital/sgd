using Gdms.Application.Tenants;
using Gdms.Contracts.Tenants;
using Gdms.Domain.Tenancy;
using Gdms.Application.Identity;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Manages the legacy HTTP surface for organization bootstrap compatibility.
/// </summary>
[ApiController]
[Route("api/tenants")]
public sealed class TenantsController : ControllerBase
{
    private readonly AuthService _authService;
    private readonly TenantService _tenantService;

    /// <summary>
    /// Initializes the controller with the legacy organization service.
    /// </summary>
    public TenantsController(TenantService tenantService, AuthService authService)
    {
        _tenantService = tenantService;
        _authService = authService;
    }

    /// <summary>
    /// Lists legacy organization records for compatibility tooling.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "PLATFORM_ADMIN")]
    [ProducesResponseType(typeof(IReadOnlyCollection<TenantResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyCollection<TenantResponse>>> GetAll(CancellationToken cancellationToken)
    {
        var tenants = await _tenantService.ListAsync(cancellationToken);
        return Ok(tenants.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates the initial organization during bootstrap.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(TenantResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<TenantResponse>> Create(
        [FromBody] CreateTenantRequest request,
        CancellationToken cancellationToken)
    {
        if (await _authService.PlatformAdminExistsAsync(cancellationToken))
        {
            if (User.Identity?.IsAuthenticated != true)
            {
                return Unauthorized();
            }

            if (!User.IsInRole("PLATFORM_ADMIN"))
            {
                return Forbid();
            }

            return Conflict(new
            {
                message = "La instalación opera con una única organización. No se permite crear organizaciones adicionales."
            });
        }

        var tenant = await _tenantService.CreateAsync(
            request.Code,
            request.Name,
            request.Sector,
            request.PrimaryCountryCode,
            GetActorUserIdOrNull(),
            cancellationToken);

        return Created($"/api/tenants/{tenant.Id}", Map(tenant));
    }

    private static TenantResponse Map(Tenant tenant)
    {
        return new TenantResponse(
            tenant.Id,
            tenant.Code,
            tenant.Name,
            tenant.Sector,
            tenant.PrimaryCountryCode,
            tenant.CreatedAtUtc);
    }

    private Guid? GetActorUserIdOrNull()
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(claim, out var actorUserId) ? actorUserId : null;
    }
}
