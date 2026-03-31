using System.Security.Claims;
using Gdms.Application.Corporate;
using Gdms.Contracts.Corporate;
using Gdms.Domain.Corporate;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes tenant-scoped corporate record files.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/corporate-record-files")]
public sealed class CorporateRecordFilesController : ControllerBase
{
    private readonly CorporateRecordFileService _corporateRecordFileService;

    /// <summary>
    /// Initializes the controller with the corporate-record-file service.
    /// </summary>
    public CorporateRecordFilesController(CorporateRecordFileService corporateRecordFileService)
    {
        _corporateRecordFileService = corporateRecordFileService;
    }

    /// <summary>
    /// Lists corporate record files visible to the current tenant scope.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<CorporateRecordFileResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<CorporateRecordFileResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var corporateRecordFiles = await _corporateRecordFileService.ListByTenantAsync(tenantId, cancellationToken);
        return Ok(corporateRecordFiles.Select(Map).ToArray());
    }

    /// <summary>
    /// Lists documents linked to a specific corporate record file.
    /// </summary>
    [HttpGet("{corporateRecordFileId:guid}/documents")]
    [ProducesResponseType(typeof(IReadOnlyCollection<CorporateRecordFileDocumentResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<CorporateRecordFileDocumentResponse>>> GetDocuments(
        Guid tenantId,
        Guid corporateRecordFileId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var links = await _corporateRecordFileService.ListDocumentsAsync(tenantId, corporateRecordFileId, cancellationToken);
        return Ok(links.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates a new corporate record file inside the tenant.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(CorporateRecordFileResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<CorporateRecordFileResponse>> Create(
        Guid tenantId,
        [FromBody] CreateCorporateRecordFileRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var corporateRecordFile = await _corporateRecordFileService.CreateAsync(
            tenantId,
            request.Code,
            request.Title,
            request.Category,
            request.OwnerArea,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(nameof(GetAll), new { tenantId }, Map(corporateRecordFile));
    }

    /// <summary>
    /// Links an existing document to a corporate record file.
    /// </summary>
    [HttpPost("{corporateRecordFileId:guid}/documents")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AttachDocument(
        Guid tenantId,
        Guid corporateRecordFileId,
        [FromBody] AttachDocumentToCorporateRecordFileRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        await _corporateRecordFileService.AttachDocumentAsync(
            tenantId,
            corporateRecordFileId,
            request.DocumentId,
            RequireUserId(),
            cancellationToken);

        return NoContent();
    }

    private static CorporateRecordFileResponse Map(CorporateRecordFile corporateRecordFile)
    {
        return new CorporateRecordFileResponse(
            corporateRecordFile.Id,
            corporateRecordFile.TenantId,
            corporateRecordFile.Code,
            corporateRecordFile.Title,
            corporateRecordFile.Category,
            corporateRecordFile.OwnerArea,
            corporateRecordFile.Status.ToString().ToUpperInvariant(),
            corporateRecordFile.CreatedByUserId,
            corporateRecordFile.CreatedAtUtc);
    }

    private static CorporateRecordFileDocumentResponse Map(CorporateRecordFileDocumentLink link)
    {
        return new CorporateRecordFileDocumentResponse(
            link.CorporateRecordFileId,
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
