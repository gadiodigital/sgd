using System.Security.Claims;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Application.Audit;
using Gdms.Contracts.Audit;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes recent audit events for platform and tenant governance views.
/// </summary>
[ApiController]
[Authorize]
[Route("api")]
public sealed class AuditController : ControllerBase
{
    private readonly AuditEventService _auditEventService;

    /// <summary>
    /// Initializes the controller with the audit read service.
    /// </summary>
    public AuditController(AuditEventService auditEventService)
    {
        _auditEventService = auditEventService;
    }

    /// <summary>
    /// Lists the most recent audit events across the platform.
    /// </summary>
    [HttpGet("audit/events/recent")]
    [Authorize(Roles = "PLATFORM_ADMIN")]
    [ProducesResponseType(typeof(IReadOnlyCollection<AuditEventResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyCollection<AuditEventResponse>>> GetRecentPlatformEvents(
        [FromQuery] int limit,
        CancellationToken cancellationToken)
    {
        var events = await _auditEventService.ListRecentAsync(limit, cancellationToken);
        return Ok(events.Select(Map).ToArray());
    }

    /// <summary>
    /// Lists the most recent audit events of a tenant.
    /// </summary>
    [HttpGet("tenants/{tenantId:guid}/audit/events/recent")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,AUDITOR,COMPLIANCE_OFFICER")]
    [ProducesResponseType(typeof(IReadOnlyCollection<AuditEventResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<AuditEventResponse>>> GetRecentTenantEvents(
        Guid tenantId,
        [FromQuery] int limit,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var events = await _auditEventService.ListRecentByTenantAsync(
            tenantId,
            limit,
            cancellationToken);
        return Ok(events.Select(Map).ToArray());
    }

    /// <summary>
    /// Lists the most recent audit events of a document.
    /// </summary>
    [HttpGet("tenants/{tenantId:guid}/documents/{documentId:guid}/audit-events")]
    [ProducesResponseType(typeof(IReadOnlyCollection<AuditEventResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<AuditEventResponse>>> GetRecentDocumentEvents(
        Guid tenantId,
        Guid documentId,
        [FromQuery] int limit,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var events = await _auditEventService.ListRecentByDocumentAsync(
            tenantId,
            documentId,
            limit,
            cancellationToken);
        return Ok(events.Select(Map).ToArray());
    }

    private static AuditEventResponse Map(AuditEventEntry entry)
    {
        return new AuditEventResponse(
            entry.Id,
            entry.TenantId,
            entry.TenantCode,
            entry.ActorUserId,
            entry.DocumentId,
            entry.EventType,
            entry.Severity,
            entry.OccurredAtUtc);
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
