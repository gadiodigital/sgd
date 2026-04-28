using System.Security.Claims;
using Gdms.Application.Tenants;
using Gdms.Contracts.Tenants;
using Gdms.Domain.Tenancy;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes the organization bound to the current authenticated session.
/// </summary>
[ApiController]
[Authorize]
[Route("api/organization")]
public sealed class CurrentOrganizationController : ControllerBase
{
    private readonly TenantService _tenantService;

    /// <summary>
    /// Initializes the controller with the legacy organization service.
    /// </summary>
    public CurrentOrganizationController(TenantService tenantService)
    {
        _tenantService = tenantService;
    }

    /// <summary>
    /// Returns the current organization configured for this installation.
    /// </summary>
    [HttpGet("current")]
    [ProducesResponseType(typeof(TenantResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TenantResponse>> GetCurrent(CancellationToken cancellationToken)
    {
        var organizationId = ResolveOrganizationId();
        if (organizationId is null)
        {
            return Unauthorized();
        }

        var organization = await _tenantService.GetByIdAsync(organizationId.Value, cancellationToken);
        if (organization is null)
        {
            return NotFound();
        }

        return Ok(Map(organization));
    }

    private Guid? ResolveOrganizationId()
    {
        var claim = User.FindFirstValue("tenant_id");
        return Guid.TryParse(claim, out var organizationId) ? organizationId : null;
    }

    private static TenantResponse Map(Tenant organization)
    {
        return new TenantResponse(
            organization.Id,
            organization.Code,
            organization.Name,
            organization.Sector,
            organization.PrimaryCountryCode,
            organization.CreatedAtUtc);
    }
}
