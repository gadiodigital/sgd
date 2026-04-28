using System.Security.Claims;
using Gdms.Application.Cases;
using Gdms.Contracts.Cases;
using Gdms.Domain.Cases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes organization-scoped case files.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/cases")]
public sealed class CaseFilesController : ControllerBase
{
    private readonly CaseFileService _caseFileService;

    /// <summary>
    /// Initializes the controller with the case file service.
    /// </summary>
    public CaseFilesController(CaseFileService caseFileService)
    {
        _caseFileService = caseFileService;
    }

    /// <summary>
    /// Lists case files visible to the current organization scope.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<CaseFileResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<CaseFileResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var caseFiles = await _caseFileService.ListByTenantAsync(tenantId, cancellationToken);
        return Ok(caseFiles.Select(Map).ToArray());
    }

    /// <summary>
    /// Lists the documents linked to a specific case file.
    /// </summary>
    [HttpGet("{caseFileId:guid}/documents")]
    [ProducesResponseType(typeof(IReadOnlyCollection<CaseFileDocumentResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<CaseFileDocumentResponse>>> GetDocuments(
        Guid tenantId,
        Guid caseFileId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var links = await _caseFileService.ListDocumentsAsync(tenantId, caseFileId, cancellationToken);
        return Ok(links.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates a new case file inside the organization.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(CaseFileResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<CaseFileResponse>> Create(
        Guid tenantId,
        [FromBody] CreateCaseFileRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var caseFile = await _caseFileService.CreateAsync(
            tenantId,
            request.Code,
            request.Title,
            request.Category,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(nameof(GetAll), new { tenantId }, Map(caseFile));
    }

    /// <summary>
    /// Links an existing document to a case file.
    /// </summary>
    [HttpPost("{caseFileId:guid}/documents")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AttachDocument(
        Guid tenantId,
        Guid caseFileId,
        [FromBody] AttachDocumentToCaseFileRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        await _caseFileService.AttachDocumentAsync(
            tenantId,
            caseFileId,
            request.DocumentId,
            RequireUserId(),
            cancellationToken);

        return NoContent();
    }

    private static CaseFileResponse Map(CaseFile caseFile)
    {
        return new CaseFileResponse(
            caseFile.Id,
            caseFile.TenantId,
            caseFile.Code,
            caseFile.Title,
            caseFile.Category,
            caseFile.Status.ToString().ToUpperInvariant(),
            caseFile.CreatedByUserId,
            caseFile.CreatedAtUtc);
    }

    private static CaseFileDocumentResponse Map(CaseFileDocumentLink link)
    {
        return new CaseFileDocumentResponse(
            link.CaseFileId,
            link.DocumentId,
            link.TenantId,
            link.DocumentTitle,
            link.DocumentTypeCode,
            link.DocumentStatus,
            link.LinkedAtUtc,
            link.LinkedByUserId);
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
