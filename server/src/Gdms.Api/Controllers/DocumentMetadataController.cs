using System.Security.Claims;
using System.Text.Json;
using Gdms.Application.Documents;
using Gdms.Contracts.Documents;
using Gdms.Domain.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes tenant-scoped read access to current document metadata.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/documents/{documentId:guid}/metadata")]
public sealed class DocumentMetadataController : ControllerBase
{
    private readonly DocumentAccessService _documentAccessService;
    private readonly DocumentMetadataService _documentMetadataService;

    /// <summary>
    /// Initializes the controller with the document metadata service.
    /// </summary>
    public DocumentMetadataController(
        DocumentMetadataService documentMetadataService,
        DocumentAccessService documentAccessService)
    {
        _documentMetadataService = documentMetadataService;
        _documentAccessService = documentAccessService;
    }

    /// <summary>
    /// Gets the current metadata object registered for a document.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(DocumentMetadataResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DocumentMetadataResponse>> Get(
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

        var snapshot = await _documentMetadataService.GetByDocumentIdAsync(
            tenantId,
            documentId,
            RequireUserId(),
            cancellationToken);
        if (snapshot is null)
        {
            return NotFound();
        }

        return Ok(new DocumentMetadataResponse(
            snapshot.DocumentId,
            snapshot.Metadata.RootElement.Clone()));
    }

    /// <summary>
    /// Replaces the current metadata object registered for a document.
    /// </summary>
    [HttpPut]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(DocumentMetadataResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<DocumentMetadataResponse>> Put(
        Guid tenantId,
        Guid documentId,
        [FromBody] UpdateDocumentMetadataRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        if (request.Metadata.ValueKind != JsonValueKind.Object)
        {
            ModelState.AddModelError(nameof(request.Metadata), "El payload de metadatos debe ser un objeto JSON.");
            return ValidationProblem(ModelState);
        }

        if (!CanBypassDocumentAcl() && !await _documentAccessService.IsAuthorizedAsync(
                tenantId,
                documentId,
                RequireUserId(),
                DocumentAccessPermission.EditMetadata,
                cancellationToken))
        {
            return Forbid();
        }

        var snapshot = await _documentMetadataService.UpdateAsync(
            tenantId,
            documentId,
            request.Metadata.GetRawText(),
            RequireUserId(),
            cancellationToken);
        if (snapshot is null)
        {
            return NotFound();
        }

        return Ok(new DocumentMetadataResponse(
            snapshot.DocumentId,
            snapshot.Metadata.RootElement.Clone()));
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
