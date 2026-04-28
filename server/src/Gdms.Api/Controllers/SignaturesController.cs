using System.Security.Claims;
using Gdms.Application.Signatures;
using Gdms.Contracts.Signature;
using Gdms.Domain.Signatures;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes organization-scoped signature requests linked to documents.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/signature/envelopes")]
public sealed class SignaturesController : ControllerBase
{
    private readonly SignatureService _signatureService;

    /// <summary>
    /// Initializes the controller with the signature service.
    /// </summary>
    public SignaturesController(SignatureService signatureService)
    {
        _signatureService = signatureService;
    }

    /// <summary>
    /// Lists signature envelopes visible to the current organization scope.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<SignatureEnvelopeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<SignatureEnvelopeResponse>>> GetAll(
        Guid tenantId,
        [FromQuery] Guid? documentId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var envelopes = await _signatureService.ListByTenantAsync(
            tenantId,
            documentId,
            cancellationToken);
        return Ok(envelopes.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates a pending signature request linked to a tenant document.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(SignatureEnvelopeResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<SignatureEnvelopeResponse>> Create(
        Guid tenantId,
        [FromBody] CreateSignatureEnvelopeRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var envelope = await _signatureService.CreateAsync(
            tenantId,
            request.DocumentId,
            request.SignerDisplayName,
            request.SignerEmail,
            request.SignatureLevel,
            request.ProviderCode,
            request.DueAtUtc,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(nameof(GetAll), new { tenantId }, Map(envelope));
    }

    /// <summary>
    /// Completes a pending signature request.
    /// </summary>
    [HttpPost("{envelopeId:guid}/complete")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(SignatureEnvelopeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<SignatureEnvelopeResponse>> Complete(
        Guid tenantId,
        Guid envelopeId,
        [FromBody] CompleteSignatureEnvelopeRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var envelope = await _signatureService.CompleteAsync(
            tenantId,
            envelopeId,
            request.ExternalReference,
            RequireUserId(),
            cancellationToken);

        return Ok(Map(envelope));
    }

    /// <summary>
    /// Cancels a pending signature request.
    /// </summary>
    [HttpPost("{envelopeId:guid}/cancel")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(SignatureEnvelopeResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<SignatureEnvelopeResponse>> Cancel(
        Guid tenantId,
        Guid envelopeId,
        [FromBody] CancelSignatureEnvelopeRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var envelope = await _signatureService.CancelAsync(
            tenantId,
            envelopeId,
            request.Reason,
            RequireUserId(),
            cancellationToken);

        return Ok(Map(envelope));
    }

    private static SignatureEnvelopeResponse Map(SignatureEnvelope envelope)
    {
        return new SignatureEnvelopeResponse(
            envelope.Id,
            envelope.TenantId,
            envelope.DocumentId,
            envelope.SignerDisplayName,
            envelope.SignerEmail,
            envelope.SignatureLevel,
            envelope.ProviderCode,
            envelope.ExternalReference,
            envelope.Status.ToString().ToUpperInvariant(),
            envelope.RequestedByUserId,
            envelope.RequestedAtUtc,
            envelope.DueAtUtc,
            envelope.CompletedByUserId,
            envelope.CompletedAtUtc,
            envelope.CancelledByUserId,
            envelope.CancelledAtUtc,
            envelope.CancellationReason);
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
