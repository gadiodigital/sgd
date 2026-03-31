using System.Security.Claims;
using Gdms.Application.Documents;
using Gdms.Contracts.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes tenant-scoped document type catalog endpoints.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/document-types")]
public sealed class DocumentTypesController : ControllerBase
{
    private readonly DocumentTypeCatalogService _documentTypeCatalogService;

    /// <summary>
    /// Initializes the controller with the document type catalog service.
    /// </summary>
    public DocumentTypesController(DocumentTypeCatalogService documentTypeCatalogService)
    {
        _documentTypeCatalogService = documentTypeCatalogService;
    }

    /// <summary>
    /// Lists the active document types visible for a tenant.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<DocumentTypeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<DocumentTypeResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var documentTypes = await _documentTypeCatalogService.ListByTenantAsync(tenantId, cancellationToken);
        return Ok(documentTypes.Select(Map).ToArray());
    }

    private static DocumentTypeResponse Map(DocumentTypeDefinition definition)
    {
        return new DocumentTypeResponse(
            definition.Id,
            definition.TenantId,
            definition.Code,
            definition.Name,
            definition.Sector,
            definition.IsActive,
            definition.MetadataSchema.RootElement.Clone());
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
}
