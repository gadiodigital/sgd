using System.Security.Claims;
using Gdms.Application.Abstractions.Integrations;
using Gdms.Application.Integrations;
using Gdms.Contracts.Integrations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes the current status of configured platform integrations.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/integrations/status")]
public sealed class IntegrationsController : ControllerBase
{
    private readonly IntegrationsService _integrationsService;

    /// <summary>
    /// Initializes the controller with the integrations service.
    /// </summary>
    public IntegrationsController(IntegrationsService integrationsService)
    {
        _integrationsService = integrationsService;
    }

    /// <summary>
    /// Lists configured integrations for the current tenant operator view.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<IntegrationStatusResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public ActionResult<IReadOnlyCollection<IntegrationStatusResponse>> GetAll(Guid tenantId)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var statuses = _integrationsService.List();
        return Ok(statuses.Select(Map).ToArray());
    }

    private static IntegrationStatusResponse Map(IntegrationStatusSnapshot item)
    {
        return new IntegrationStatusResponse(
            item.Code,
            item.DisplayName,
            item.Category,
            item.Status,
            item.Detail);
    }

    private bool HasTenantAccess(Guid tenantId)
    {
        if (User.IsInRole("PLATFORM_ADMIN"))
        {
            return true;
        }

        var tenantClaim = User.FindFirstValue("tenant_id");
        return Guid.TryParse(tenantClaim, out var claimedTenantId) && claimedTenantId == tenantId;
    }
}
