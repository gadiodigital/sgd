using System.Security.Claims;
using Gdms.Application.Notifications;
using Gdms.Contracts.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes the organization inbox of actionable operational notifications.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/notifications")]
public sealed class NotificationsController : ControllerBase
{
    private readonly NotificationsService _notificationsService;

    /// <summary>
    /// Initializes the controller with the notifications service.
    /// </summary>
    public NotificationsController(NotificationsService notificationsService)
    {
        _notificationsService = notificationsService;
    }

    /// <summary>
    /// Lists the current actionable notifications of an organization.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<NotificationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<NotificationResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        return await GetAllForOrganization(tenantId, cancellationToken);
    }

    /// <summary>
    /// Lists the current actionable notifications of the current organization.
    /// </summary>
    [HttpGet("/api/organization/notifications")]
    [ProducesResponseType(typeof(IReadOnlyCollection<NotificationResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyCollection<NotificationResponse>>> GetAllForCurrentOrganization(
        CancellationToken cancellationToken)
    {
        var tenantId = ResolveCurrentOrganizationId();
        if (tenantId is null)
        {
            return Unauthorized();
        }

        return await GetAllForOrganization(tenantId.Value, cancellationToken);
    }

    private async Task<ActionResult<IReadOnlyCollection<NotificationResponse>>> GetAllForOrganization(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        var notifications = await _notificationsService.ListByTenantAsync(
            tenantId,
            cancellationToken);
        return Ok(notifications.Select(Map).ToArray());
    }

    private static NotificationResponse Map(NotificationItem item)
    {
        return new NotificationResponse(
            item.Category,
            item.Title,
            item.Detail,
            item.Severity,
            item.OccurredAtUtc);
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

    private Guid? ResolveCurrentOrganizationId()
    {
        var tenantClaim = User.FindFirstValue("tenant_id");
        return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : null;
    }
}
