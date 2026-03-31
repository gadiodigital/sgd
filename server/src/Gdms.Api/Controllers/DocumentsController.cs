using System.Security.Claims;
using Gdms.Application.Documents;
using Gdms.Contracts.Documents;
using Gdms.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes the initial document registration and query endpoints.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/documents")]
public sealed class DocumentsController : ControllerBase
{
    private readonly DocumentAccessService _documentAccessService;
    private readonly DocumentService _documentService;

    /// <summary>
    /// Initializes the controller with the application document service.
    /// </summary>
    public DocumentsController(
        DocumentService documentService,
        DocumentAccessService documentAccessService)
    {
        _documentService = documentService;
        _documentAccessService = documentAccessService;
    }

    /// <summary>
    /// Lists the documents visible for a tenant.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<DocumentResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<DocumentResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var documents = await _documentService.ListByTenantAsync(tenantId, cancellationToken);
        return Ok(documents.Select(Map).ToArray());
    }

    /// <summary>
    /// Searches documents within the tenant using a free-text query.
    /// </summary>
    [HttpGet("search")]
    [ProducesResponseType(typeof(IReadOnlyCollection<DocumentResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<DocumentResponse>>> Search(
        Guid tenantId,
        [FromQuery] string? query,
        [FromQuery] string? documentTypeCode,
        [FromQuery] string? status,
        [FromQuery] bool? onLegalHold,
        [FromQuery] int limit,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        if (!TryParseDocumentStatus(status, out var parsedStatus))
        {
            ModelState.AddModelError("status", "El estado documental informado no es válido.");
            return ValidationProblem(ModelState);
        }

        var documents = await _documentService.SearchAsync(
            tenantId,
            query,
            documentTypeCode,
            parsedStatus,
            onLegalHold,
            limit <= 0 ? 25 : limit,
            RequireUserId(),
            cancellationToken);

        return Ok(documents.Select(Map).ToArray());
    }

    /// <summary>
    /// Returns a registered document by identifier.
    /// </summary>
    [HttpGet("{documentId:guid}")]
    [ProducesResponseType(typeof(DocumentResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DocumentResponse>> GetById(
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
                DocumentAccessPermission.Read,
                cancellationToken))
        {
            return Forbid();
        }

        var document = await _documentService.GetByIdAsync(
            tenantId,
            documentId,
            RequireUserId(),
            cancellationToken);

        if (document is null)
        {
            return NotFound();
        }

        return Ok(Map(document));
    }

    /// <summary>
    /// Returns the immutable version history of a document.
    /// </summary>
    [HttpGet("{documentId:guid}/versions")]
    [ProducesResponseType(typeof(IReadOnlyCollection<DocumentVersionResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<DocumentVersionResponse>>> GetVersions(
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
                DocumentAccessPermission.Read,
                cancellationToken))
        {
            return Forbid();
        }

        var document = await _documentService.GetByIdAsync(
            tenantId,
            documentId,
            RequireUserId(),
            cancellationToken);
        if (document is null)
        {
            return NotFound();
        }

        var versions = document.Versions
            .OrderByDescending(version => version.VersionNumber)
            .Select(MapVersion)
            .ToArray();
        return Ok(versions);
    }

    /// <summary>
    /// Registers a new document and its initial version.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(DocumentResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DocumentResponse>> Create(
        Guid tenantId,
        [FromBody] CreateDocumentRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var document = await _documentService.CreateAsync(
            tenantId,
            request.DocumentTypeCode,
            request.Title,
            request.StorageObjectKey,
            request.MimeType,
            request.FileHashSha256,
            request.FileSizeBytes,
            request.MetadataJson,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(nameof(GetById), new { tenantId, documentId = document.Id }, Map(document));
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

    private static DocumentVersionResponse MapVersion(DocumentVersion version)
    {
        return new DocumentVersionResponse(
            version.Id,
            version.VersionNumber,
            version.MimeType,
            version.FileHashSha256,
            version.FileSizeBytes,
            version.UploadedByUserId,
            version.UploadedAtUtc);
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

    private static bool TryParseDocumentStatus(string? value, out DocumentStatus? status)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            status = null;
            return true;
        }

        if (Enum.TryParse<DocumentStatus>(value, ignoreCase: true, out var parsedStatus))
        {
            status = parsedStatus;
            return true;
        }

        status = null;
        return false;
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
