using System.Security.Claims;
using Gdms.Application.Records;
using Gdms.Contracts.Records;
using Gdms.Domain.Records;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes retention and legal-hold endpoints for records management.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/records")]
public sealed class RecordsController : ControllerBase
{
    private readonly RecordsService _recordsService;

    /// <summary>
    /// Initializes the controller with the records-management service.
    /// </summary>
    public RecordsController(RecordsService recordsService)
    {
        _recordsService = recordsService;
    }

    /// <summary>
    /// Lists the disposition candidates due at the current UTC instant.
    /// </summary>
    [HttpGet("disposition-candidates")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,COMPLIANCE_OFFICER,AUDITOR")]
    [ProducesResponseType(typeof(IReadOnlyCollection<DispositionCandidateResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<DispositionCandidateResponse>>> GetDispositionCandidates(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var candidates = await _recordsService.ListDispositionCandidatesAsync(
            tenantId,
            DateTimeOffset.UtcNow,
            cancellationToken);

        return Ok(candidates.Select(Map).ToArray());
    }

    /// <summary>
    /// Lists the retention policies available to a tenant.
    /// </summary>
    [HttpGet("retention-policies")]
    [ProducesResponseType(typeof(IReadOnlyCollection<RetentionPolicyResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<RetentionPolicyResponse>>> GetRetentionPolicies(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var policies = await _recordsService.ListRetentionPoliciesAsync(tenantId, cancellationToken);
        return Ok(policies.Select(Map).ToArray());
    }

    /// <summary>
    /// Executes the policy-driven disposition for a due document.
    /// </summary>
    [HttpPost("documents/{documentId:guid}/disposition/execute")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,COMPLIANCE_OFFICER")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> ExecuteDisposition(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        await _recordsService.ExecuteDispositionAsync(
            tenantId,
            documentId,
            RequireUserId(),
            DateTimeOffset.UtcNow,
            cancellationToken);

        return NoContent();
    }

    /// <summary>
    /// Applies a retention policy to a document.
    /// </summary>
    [HttpPost("documents/{documentId:guid}/retention-policy")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,COMPLIANCE_OFFICER")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> ApplyRetentionPolicy(
        Guid tenantId,
        Guid documentId,
        [FromBody] ApplyRetentionPolicyRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        await _recordsService.ApplyRetentionPolicyAsync(
            tenantId,
            documentId,
            request.RetentionPolicyCode,
            RequireUserId(),
            cancellationToken);

        return NoContent();
    }

    /// <summary>
    /// Lists the legal holds that apply to a document.
    /// </summary>
    [HttpGet("documents/{documentId:guid}/legal-holds")]
    [ProducesResponseType(typeof(IReadOnlyCollection<LegalHoldResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<LegalHoldResponse>>> GetLegalHolds(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var legalHolds = await _recordsService.ListLegalHoldsAsync(tenantId, documentId, cancellationToken);
        return Ok(legalHolds.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates a new legal hold for a document.
    /// </summary>
    [HttpPost("documents/{documentId:guid}/legal-holds")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,COMPLIANCE_OFFICER")]
    [ProducesResponseType(typeof(LegalHoldResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LegalHoldResponse>> CreateLegalHold(
        Guid tenantId,
        Guid documentId,
        [FromBody] CreateLegalHoldRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var legalHold = await _recordsService.CreateLegalHoldAsync(
            tenantId,
            documentId,
            request.Reason,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(
            nameof(GetLegalHolds),
            new { tenantId, documentId },
            Map(legalHold));
    }

    /// <summary>
    /// Releases an active legal hold.
    /// </summary>
    [HttpPost("legal-holds/{legalHoldId:guid}/release")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,COMPLIANCE_OFFICER")]
    [ProducesResponseType(typeof(LegalHoldResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<LegalHoldResponse>> ReleaseLegalHold(
        Guid tenantId,
        Guid legalHoldId,
        [FromBody] ReleaseLegalHoldRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var legalHold = await _recordsService.ReleaseLegalHoldAsync(
            tenantId,
            legalHoldId,
            request.Reason,
            RequireUserId(),
            cancellationToken);

        return Ok(Map(legalHold));
    }

    private static RetentionPolicyResponse Map(RetentionPolicy policy)
    {
        return new RetentionPolicyResponse(
            policy.Id,
            policy.TenantId,
            policy.Code,
            policy.Name,
            policy.RetentionDays,
            policy.DispositionAction.ToString().ToUpperInvariant(),
            policy.IsActive);
    }

    private static DispositionCandidateResponse Map(Gdms.Application.Records.DispositionCandidate candidate)
    {
        return new DispositionCandidateResponse(
            candidate.DocumentId,
            candidate.DocumentTypeCode,
            candidate.Title,
            candidate.CurrentStatus,
            candidate.RetentionPolicyCode,
            candidate.RetentionDays,
            candidate.RecommendedAction,
            candidate.DueAtUtc,
            candidate.HasActiveLegalHold);
    }

    private static LegalHoldResponse Map(LegalHold legalHold)
    {
        return new LegalHoldResponse(
            legalHold.Id,
            legalHold.TenantId,
            legalHold.DocumentId,
            legalHold.Reason,
            legalHold.IsActive,
            legalHold.CreatedByUserId,
            legalHold.CreatedAtUtc,
            legalHold.ReleasedByUserId,
            legalHold.ReleasedAtUtc,
            legalHold.ReleaseReason);
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

    private Guid RequireUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            throw new UnauthorizedAccessException("No se pudo resolver el usuario autenticado desde el JWT.");
        }

        return userId;
    }
}
