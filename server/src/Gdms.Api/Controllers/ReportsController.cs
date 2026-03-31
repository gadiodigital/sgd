using System.Security.Claims;
using Gdms.Application.Reports;
using Gdms.Contracts.Reports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes tenant-scoped operational reports.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/reports")]
public sealed class ReportsController : ControllerBase
{
    private readonly ReportsService _reportsService;

    /// <summary>
    /// Initializes the controller with the reports service.
    /// </summary>
    public ReportsController(ReportsService reportsService)
    {
        _reportsService = reportsService;
    }

    /// <summary>
    /// Returns the current operational summary of the tenant.
    /// </summary>
    [HttpGet("operational-summary")]
    [ProducesResponseType(typeof(OperationalReportResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<OperationalReportResponse>> GetOperationalSummary(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var report = await _reportsService.GetOperationalSummaryAsync(tenantId, cancellationToken);
        return Ok(new OperationalReportResponse(
            report.TotalDocuments,
            report.ActiveLegalHolds,
            report.OpenWorkflowTasks,
            report.PendingSignatures,
            report.CancelledSignatures,
            report.PendingDispositionItems,
            report.FailedLoginsLast24Hours));
    }

    /// <summary>
    /// Returns the current operational summary of the full platform.
    /// </summary>
    [HttpGet("/api/reports/platform-summary")]
    [Authorize(Roles = "PLATFORM_ADMIN")]
    [ProducesResponseType(typeof(PlatformReportResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<PlatformReportResponse>> GetPlatformSummary(
        CancellationToken cancellationToken)
    {
        var report = await _reportsService.GetPlatformSummaryAsync(cancellationToken);
        return Ok(new PlatformReportResponse(
            report.TotalTenants,
            report.TotalDocuments,
            report.OpenWorkflowTasks,
            report.PendingSignatures,
            report.CancelledSignatures,
            report.FailedLoginsLast24Hours));
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
