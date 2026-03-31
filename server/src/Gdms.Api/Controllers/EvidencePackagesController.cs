using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Gdms.Application.Evidence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes export endpoints for document evidence packages.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/documents/{documentId:guid}/evidence-package")]
public sealed class EvidencePackagesController : ControllerBase
{
    private readonly DocumentEvidencePackageService _documentEvidencePackageService;

    /// <summary>
    /// Initializes the controller with the evidence package service.
    /// </summary>
    public EvidencePackagesController(DocumentEvidencePackageService documentEvidencePackageService)
    {
        _documentEvidencePackageService = documentEvidencePackageService;
    }

    /// <summary>
    /// Exports one evidence package as a downloadable JSON document.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(FileContentResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Download(
        Guid tenantId,
        Guid documentId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var evidencePackage = await _documentEvidencePackageService.ExportAsync(
            tenantId,
            documentId,
            RequireUserId(),
            cancellationToken);
        var payload = JsonSerializer.Serialize(
            evidencePackage,
            new JsonSerializerOptions { WriteIndented = true });
        var fileName = $"evidence-package-{documentId:N}.json";

        return File(
            Encoding.UTF8.GetBytes(payload),
            "application/json",
            fileName);
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
