using System.Security.Claims;
using System.Text.Json;
using Gdms.Application.Structure;
using Gdms.Contracts.Structure;
using Gdms.Domain.Structure;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes organization-scoped configurable document structures.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/structure/projects")]
public sealed class DocumentStructureController : ControllerBase
{
    private readonly DocumentStructureService _documentStructureService;

    public DocumentStructureController(DocumentStructureService documentStructureService)
    {
        _documentStructureService = documentStructureService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<StructureProjectResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<StructureProjectResponse>>> GetProjects(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var projects = await _documentStructureService.ListProjectsAsync(tenantId, cancellationToken);
        return Ok(projects.Select(Map).ToArray());
    }

    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(StructureProjectResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<StructureProjectResponse>> CreateProject(
        Guid tenantId,
        [FromBody] CreateStructureProjectRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var project = await _documentStructureService.CreateProjectAsync(
            tenantId,
            request.Code,
            request.Name,
            request.Description,
            RequireUserId(),
            cancellationToken);
        return CreatedAtAction(nameof(GetProjects), new { tenantId }, Map(project));
    }

    [HttpGet("{projectId:guid}/container-types")]
    [ProducesResponseType(typeof(IReadOnlyCollection<ContainerTypeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<ContainerTypeResponse>>> GetContainerTypes(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var containerTypes = await _documentStructureService.ListContainerTypesAsync(
            tenantId,
            projectId,
            cancellationToken);
        return Ok(containerTypes.Select(Map).ToArray());
    }

    [HttpPost("{projectId:guid}/container-types")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(ContainerTypeResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ContainerTypeResponse>> CreateContainerType(
        Guid tenantId,
        Guid projectId,
        [FromBody] CreateContainerTypeRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var containerType = await _documentStructureService.CreateContainerTypeAsync(
            tenantId,
            projectId,
            request.Code,
            request.Name,
            request.IconKey,
            request.IsRootAllowed,
            request.AcceptsDocuments,
            RawOrEmptyObject(request.MetadataSchema),
            RequireUserId(),
            cancellationToken);
        return CreatedAtAction(nameof(GetContainerTypes), new { tenantId, projectId }, Map(containerType));
    }

    [HttpGet("{projectId:guid}/container-type-rules")]
    [ProducesResponseType(typeof(IReadOnlyCollection<ContainerTypeRuleResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<ContainerTypeRuleResponse>>> GetContainerTypeRules(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var rules = await _documentStructureService.ListContainerTypeRulesAsync(
            tenantId,
            projectId,
            cancellationToken);
        return Ok(rules.Select(Map).ToArray());
    }

    [HttpPost("{projectId:guid}/container-type-rules")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(ContainerTypeRuleResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ContainerTypeRuleResponse>> CreateContainerTypeRule(
        Guid tenantId,
        Guid projectId,
        [FromBody] CreateContainerTypeRuleRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var rule = await _documentStructureService.CreateContainerTypeRuleAsync(
            tenantId,
            projectId,
            request.ParentContainerTypeId,
            request.ChildContainerTypeId,
            RequireUserId(),
            cancellationToken);
        return CreatedAtAction(nameof(GetContainerTypeRules), new { tenantId, projectId }, Map(rule));
    }

    [HttpGet("{projectId:guid}/containers")]
    [ProducesResponseType(typeof(IReadOnlyCollection<ContainerResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<ContainerResponse>>> GetContainers(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var containers = await _documentStructureService.ListContainersAsync(
            tenantId,
            projectId,
            cancellationToken);
        return Ok(containers.Select(Map).ToArray());
    }

    [HttpGet("{projectId:guid}/tree")]
    [ProducesResponseType(typeof(IReadOnlyCollection<ContainerTreeNodeResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<ContainerTreeNodeResponse>>> GetTree(
        Guid tenantId,
        Guid projectId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var containers = await _documentStructureService.ListContainersAsync(
            tenantId,
            projectId,
            cancellationToken);
        return Ok(BuildTree(containers));
    }

    [HttpPost("{projectId:guid}/containers")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(ContainerResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ContainerResponse>> CreateContainer(
        Guid tenantId,
        Guid projectId,
        [FromBody] CreateContainerRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var container = await _documentStructureService.CreateContainerAsync(
            tenantId,
            projectId,
            request.ContainerTypeId,
            request.ParentContainerId,
            request.Code,
            request.Name,
            RawOrEmptyObject(request.Metadata),
            RequireUserId(),
            cancellationToken);
        return CreatedAtAction(nameof(GetContainers), new { tenantId, projectId }, Map(container));
    }

    [HttpGet("{projectId:guid}/containers/{containerId:guid}/documents")]
    [ProducesResponseType(typeof(IReadOnlyCollection<ContainerDocumentResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<ContainerDocumentResponse>>> GetContainerDocuments(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var links = await _documentStructureService.ListContainerDocumentsAsync(
            tenantId,
            projectId,
            containerId,
            cancellationToken);
        return Ok(links.Select(Map).ToArray());
    }

    [HttpPost("{projectId:guid}/containers/{containerId:guid}/documents")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> AttachDocument(
        Guid tenantId,
        Guid projectId,
        Guid containerId,
        [FromBody] AttachDocumentToContainerRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        await _documentStructureService.AttachDocumentAsync(
            tenantId,
            projectId,
            containerId,
            request.DocumentId,
            RequireUserId(),
            cancellationToken);
        return NoContent();
    }

    private static StructureProjectResponse Map(StructureProject project)
    {
        return new StructureProjectResponse(
            project.Id,
            project.TenantId,
            project.Code,
            project.Name,
            project.Description,
            project.Status.ToString().ToUpperInvariant(),
            project.CreatedByUserId,
            project.CreatedAtUtc);
    }

    private static ContainerTypeResponse Map(ContainerTypeDefinition containerType)
    {
        using var schema = JsonDocument.Parse(containerType.MetadataSchemaJson);
        return new ContainerTypeResponse(
            containerType.Id,
            containerType.TenantId,
            containerType.ProjectId,
            containerType.Code,
            containerType.Name,
            containerType.IconKey,
            containerType.IsRootAllowed,
            containerType.AcceptsDocuments,
            schema.RootElement.Clone(),
            containerType.CreatedByUserId,
            containerType.CreatedAtUtc);
    }

    private static ContainerTypeRuleResponse Map(ContainerTypeRule rule)
    {
        return new ContainerTypeRuleResponse(
            rule.Id,
            rule.TenantId,
            rule.ProjectId,
            rule.ParentContainerTypeId,
            rule.ChildContainerTypeId,
            rule.CreatedByUserId,
            rule.CreatedAtUtc);
    }

    private static ContainerResponse Map(ContainerNode container)
    {
        using var metadata = JsonDocument.Parse(container.MetadataJson);
        return new ContainerResponse(
            container.Id,
            container.TenantId,
            container.ProjectId,
            container.ContainerTypeId,
            container.ParentContainerId,
            container.Code,
            container.Name,
            metadata.RootElement.Clone(),
            container.CreatedByUserId,
            container.CreatedAtUtc);
    }

    private static ContainerDocumentResponse Map(ContainerDocumentLink link)
    {
        return new ContainerDocumentResponse(
            link.ContainerId,
            link.DocumentId,
            link.TenantId,
            link.DocumentTitle,
            link.DocumentTypeCode,
            link.DocumentStatus,
            link.LinkedAtUtc,
            link.LinkedByUserId);
    }

    private static IReadOnlyCollection<ContainerTreeNodeResponse> BuildTree(IReadOnlyCollection<ContainerNode> containers)
    {
        var byParent = containers
            .GroupBy(container => container.ParentContainerId ?? Guid.Empty)
            .ToDictionary(group => group.Key, group => group.OrderBy(item => item.Code, StringComparer.Ordinal).ToArray());

        return BuildChildren(Guid.Empty, byParent);
    }

    private static IReadOnlyCollection<ContainerTreeNodeResponse> BuildChildren(
        Guid parentId,
        IReadOnlyDictionary<Guid, ContainerNode[]> byParent)
    {
        if (!byParent.TryGetValue(parentId, out var children))
        {
            return Array.Empty<ContainerTreeNodeResponse>();
        }

        return children.Select(child =>
        {
            using var metadata = JsonDocument.Parse(child.MetadataJson);
            return new ContainerTreeNodeResponse(
                child.Id,
                child.TenantId,
                child.ProjectId,
                child.ContainerTypeId,
                child.ParentContainerId,
                child.Code,
                child.Name,
                metadata.RootElement.Clone(),
                child.CreatedByUserId,
                child.CreatedAtUtc,
                BuildChildren(child.Id, byParent));
        }).ToArray();
    }

    private static string RawOrEmptyObject(JsonElement value)
    {
        return value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null
            ? "{}"
            : value.GetRawText();
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
