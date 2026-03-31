using System.Security.Claims;
using Gdms.Application.RealEstate;
using Gdms.Contracts.RealEstate;
using Gdms.Domain.RealEstate;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes tenant-scoped real-estate property files.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/property-files")]
public sealed class PropertyFilesController : ControllerBase
{
    private readonly PropertyFileService _propertyFileService;

    /// <summary>
    /// Initializes the controller with the property-file service.
    /// </summary>
    public PropertyFilesController(PropertyFileService propertyFileService)
    {
        _propertyFileService = propertyFileService;
    }

    /// <summary>
    /// Lists property files visible to the current tenant scope.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<PropertyFileResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<PropertyFileResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var propertyFiles = await _propertyFileService.ListByTenantAsync(tenantId, cancellationToken);
        return Ok(propertyFiles.Select(Map).ToArray());
    }

    /// <summary>
    /// Lists documents linked to a specific property file.
    /// </summary>
    [HttpGet("{propertyFileId:guid}/documents")]
    [ProducesResponseType(typeof(IReadOnlyCollection<PropertyFileDocumentResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<PropertyFileDocumentResponse>>> GetDocuments(
        Guid tenantId,
        Guid propertyFileId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var links = await _propertyFileService.ListDocumentsAsync(tenantId, propertyFileId, cancellationToken);
        return Ok(links.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates a new property file inside the tenant.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(PropertyFileResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<PropertyFileResponse>> Create(
        Guid tenantId,
        [FromBody] CreatePropertyFileRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var propertyFile = await _propertyFileService.CreateAsync(
            tenantId,
            request.Code,
            request.Title,
            request.Address,
            request.OperationType,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(nameof(GetAll), new { tenantId }, Map(propertyFile));
    }

    /// <summary>
    /// Links an existing document to a property file.
    /// </summary>
    [HttpPost("{propertyFileId:guid}/documents")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AttachDocument(
        Guid tenantId,
        Guid propertyFileId,
        [FromBody] AttachDocumentToPropertyFileRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        await _propertyFileService.AttachDocumentAsync(
            tenantId,
            propertyFileId,
            request.DocumentId,
            RequireUserId(),
            cancellationToken);

        return NoContent();
    }

    private static PropertyFileResponse Map(PropertyFile propertyFile)
    {
        return new PropertyFileResponse(
            propertyFile.Id,
            propertyFile.TenantId,
            propertyFile.Code,
            propertyFile.Title,
            propertyFile.Address,
            propertyFile.OperationType,
            propertyFile.Status.ToString().ToUpperInvariant(),
            propertyFile.CreatedByUserId,
            propertyFile.CreatedAtUtc);
    }

    private static PropertyFileDocumentResponse Map(PropertyFileDocumentLink link)
    {
        return new PropertyFileDocumentResponse(
            link.PropertyFileId,
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
