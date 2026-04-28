using System.Security.Claims;
using Gdms.Application.Documents;
using Gdms.Contracts.Documents;
using Gdms.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes explicit ACL management endpoints for organization documents.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/documents/{documentId:guid}/access-entries")]
public sealed class DocumentAccessController : ControllerBase
{
    private readonly DocumentAccessService _documentAccessService;

    /// <summary>
    /// Initializes the controller with the document access service.
    /// </summary>
    public DocumentAccessController(DocumentAccessService documentAccessService)
    {
        _documentAccessService = documentAccessService;
    }

    /// <summary>
    /// Lists the explicit ACL entries configured for a document.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(IReadOnlyCollection<DocumentAccessEntryResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<DocumentAccessEntryResponse>>> GetAll(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var entries = await _documentAccessService.ListAsync(
            tenantId,
            documentId,
            cancellationToken);
        return Ok(entries.Select(Map).ToArray());
    }

    /// <summary>
    /// Grants an explicit ACL permission to an organization user.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(DocumentAccessEntryResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DocumentAccessEntryResponse>> Grant(
        Guid tenantId,
        Guid documentId,
        [FromBody] GrantDocumentAccessRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var entry = await _documentAccessService.GrantAsync(
            tenantId,
            documentId,
            request.UserId,
            request.PermissionCode,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(
            nameof(GetAll),
            new { tenantId, documentId },
            Map(entry));
    }

    private static DocumentAccessEntryResponse Map(DocumentAccessEntry entry)
    {
        return new DocumentAccessEntryResponse(
            entry.Id,
            entry.TenantId,
            entry.DocumentId,
            entry.UserId,
            entry.Permission.ToString().ToUpperInvariant(),
            entry.GrantedByUserId,
            entry.GrantedAtUtc);
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
