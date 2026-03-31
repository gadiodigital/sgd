using System.Security.Claims;
using Gdms.Api.Models.Documents;
using Gdms.Application.Documents;
using Gdms.Contracts.Documents;
using Gdms.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes binary upload and download endpoints for document content.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/documents")]
public sealed class DocumentContentController : ControllerBase
{
    private readonly DocumentAccessService _documentAccessService;
    private readonly DocumentContentService _documentContentService;

    /// <summary>
    /// Initializes the controller with the document application service.
    /// </summary>
    public DocumentContentController(
        DocumentContentService documentContentService,
        DocumentAccessService documentAccessService)
    {
        _documentContentService = documentContentService;
        _documentAccessService = documentAccessService;
    }

    /// <summary>
    /// Uploads a binary file, stores it and registers the document metadata.
    /// </summary>
    [HttpPost("upload")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(DocumentResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DocumentResponse>> Upload(
        Guid tenantId,
        [FromForm] UploadDocumentForm request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        if (request.File.Length <= 0)
        {
            ModelState.AddModelError(nameof(request.File), "El archivo a subir no puede estar vacío.");
            return ValidationProblem(ModelState);
        }

        var title = string.IsNullOrWhiteSpace(request.Title)
            ? Path.GetFileNameWithoutExtension(request.File.FileName)
            : request.Title;

        await using var contentStream = request.File.OpenReadStream();
        var document = await _documentContentService.UploadAsync(
            tenantId,
            request.DocumentTypeCode,
            title,
            request.File.FileName,
            string.IsNullOrWhiteSpace(request.File.ContentType)
                ? "application/octet-stream"
                : request.File.ContentType,
            contentStream,
            request.MetadataJson,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(
            nameof(DocumentsController.GetById),
            "Documents",
            new { tenantId, documentId = document.Id },
            Map(document));
    }

    /// <summary>
    /// Uploads a new immutable version for an existing document.
    /// </summary>
    [HttpPost("{documentId:guid}/versions/upload")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(DocumentResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<DocumentResponse>> UploadVersion(
        Guid tenantId,
        Guid documentId,
        [FromForm] UploadDocumentVersionForm request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        if (request.File.Length <= 0)
        {
            ModelState.AddModelError(nameof(request.File), "El archivo de la nueva versión no puede estar vacío.");
            return ValidationProblem(ModelState);
        }

        if (!CanBypassDocumentAcl() && !await _documentAccessService.IsAuthorizedAsync(
                tenantId,
                documentId,
                RequireUserId(),
                DocumentAccessPermission.UploadVersion,
                cancellationToken))
        {
            return Forbid();
        }

        await using var contentStream = request.File.OpenReadStream();
        var document = await _documentContentService.UploadNewVersionAsync(
            tenantId,
            documentId,
            request.File.FileName,
            string.IsNullOrWhiteSpace(request.File.ContentType)
                ? "application/octet-stream"
                : request.File.ContentType,
            contentStream,
            RequireUserId(),
            cancellationToken);

        return Ok(Map(document));
    }

    /// <summary>
    /// Downloads the latest binary version of a document.
    /// </summary>
    [HttpGet("{documentId:guid}/download")]
    [ProducesResponseType(typeof(FileStreamResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Download(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        if (!CanBypassDocumentAcl() && !await _documentAccessService.IsAuthorizedAsync(
                tenantId,
                documentId,
                RequireUserId(),
                DocumentAccessPermission.Download,
                cancellationToken))
        {
            return Forbid();
        }

        var content = await _documentContentService.OpenDownloadAsync(
            tenantId,
            documentId,
            RequireUserId(),
            cancellationToken);
        if (content is null)
        {
            return NotFound();
        }

        return File(
            content.Content,
            content.ContentType,
            content.DownloadFileName,
            enableRangeProcessing: true);
    }

    /// <summary>
    /// Downloads a specific immutable version of a document.
    /// </summary>
    [HttpGet("{documentId:guid}/versions/{versionNumber:int}/download")]
    [ProducesResponseType(typeof(FileStreamResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DownloadVersion(
        Guid tenantId,
        Guid documentId,
        int versionNumber,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        if (!CanBypassDocumentAcl() && !await _documentAccessService.IsAuthorizedAsync(
                tenantId,
                documentId,
                RequireUserId(),
                DocumentAccessPermission.Download,
                cancellationToken))
        {
            return Forbid();
        }

        var content = await _documentContentService.OpenVersionDownloadAsync(
            tenantId,
            documentId,
            versionNumber,
            RequireUserId(),
            cancellationToken);
        if (content is null)
        {
            return NotFound();
        }

        return File(
            content.Content,
            content.ContentType,
            content.DownloadFileName,
            enableRangeProcessing: true);
    }

    private static DocumentResponse Map(Document document)
    {
        return new DocumentResponse(
            document.Id,
            document.TenantId,
            document.DocumentTypeCode,
            document.Title,
            document.Status.ToString(),
            document.Versions.Count,
            document.CreatedAtUtc);
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

    private bool CanBypassDocumentAcl()
    {
        return User.IsInRole("PLATFORM_ADMIN") || User.IsInRole("TENANT_ADMIN");
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
