using System.Security.Claims;
using Gdms.Application.Workflow;
using Gdms.Contracts.Workflow;
using Gdms.Domain.Workflow;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes organization-scoped workflow tasks linked to documents.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/workflow/tasks")]
public sealed class WorkflowController : ControllerBase
{
    private readonly WorkflowService _workflowService;

    /// <summary>
    /// Initializes the controller with the workflow service.
    /// </summary>
    public WorkflowController(WorkflowService workflowService)
    {
        _workflowService = workflowService;
    }

    /// <summary>
    /// Lists workflow tasks visible to the current organization scope.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<WorkflowTaskResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<IReadOnlyCollection<WorkflowTaskResponse>>> GetAll(
        Guid tenantId,
        [FromQuery] bool mine,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        return await GetAllForOrganization(tenantId, mine, cancellationToken);
    }

    /// <summary>
    /// Lists workflow tasks visible to the current organization scope.
    /// </summary>
    [HttpGet("/api/organization/workflow/tasks")]
    [ProducesResponseType(typeof(IReadOnlyCollection<WorkflowTaskResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyCollection<WorkflowTaskResponse>>> GetAllForCurrentOrganization(
        [FromQuery] bool mine,
        CancellationToken cancellationToken)
    {
        var tenantId = ResolveCurrentOrganizationId();
        if (tenantId is null)
        {
            return Unauthorized();
        }

        return await GetAllForOrganization(tenantId.Value, mine, cancellationToken);
    }

    private async Task<ActionResult<IReadOnlyCollection<WorkflowTaskResponse>>> GetAllForOrganization(
        Guid tenantId,
        bool mine,
        CancellationToken cancellationToken)
    {
        var tasks = await _workflowService.ListByTenantAsync(
            tenantId,
            mine ? RequireUserId() : null,
            cancellationToken);
        return Ok(tasks.Select(Map).ToArray());
    }

    /// <summary>
    /// Creates a new workflow task linked to a tenant document.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(WorkflowTaskResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<WorkflowTaskResponse>> Create(
        Guid tenantId,
        [FromBody] CreateWorkflowTaskRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        return await CreateForOrganization(tenantId, request, cancellationToken);
    }

    /// <summary>
    /// Creates a new workflow task linked to a document in the current organization.
    /// </summary>
    [HttpPost("/api/organization/workflow/tasks")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(WorkflowTaskResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<WorkflowTaskResponse>> CreateForCurrentOrganization(
        [FromBody] CreateWorkflowTaskRequest request,
        CancellationToken cancellationToken)
    {
        var tenantId = ResolveCurrentOrganizationId();
        if (tenantId is null)
        {
            return Unauthorized();
        }

        return await CreateForOrganization(tenantId.Value, request, cancellationToken);
    }

    private async Task<ActionResult<WorkflowTaskResponse>> CreateForOrganization(
        Guid tenantId,
        CreateWorkflowTaskRequest request,
        CancellationToken cancellationToken)
    {
        var task = await _workflowService.CreateAsync(
            tenantId,
            request.DocumentId,
            request.Title,
            request.Notes,
            request.AssignedToUserId,
            request.DueAtUtc,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(nameof(GetAll), new { tenantId }, Map(task));
    }

    /// <summary>
    /// Completes an existing workflow task.
    /// </summary>
    [HttpPost("{taskId:guid}/complete")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(WorkflowTaskResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<WorkflowTaskResponse>> Complete(
        Guid tenantId,
        Guid taskId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        return await CompleteForOrganization(tenantId, taskId, cancellationToken);
    }

    /// <summary>
    /// Completes an existing workflow task in the current organization.
    /// </summary>
    [HttpPost("/api/organization/workflow/tasks/{taskId:guid}/complete")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN,DOCUMENT_OPERATOR")]
    [ProducesResponseType(typeof(WorkflowTaskResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<WorkflowTaskResponse>> CompleteForCurrentOrganization(
        Guid taskId,
        CancellationToken cancellationToken)
    {
        var tenantId = ResolveCurrentOrganizationId();
        if (tenantId is null)
        {
            return Unauthorized();
        }

        return await CompleteForOrganization(tenantId.Value, taskId, cancellationToken);
    }

    private async Task<ActionResult<WorkflowTaskResponse>> CompleteForOrganization(
        Guid tenantId,
        Guid taskId,
        CancellationToken cancellationToken)
    {
        var task = await _workflowService.CompleteAsync(
            tenantId,
            taskId,
            RequireUserId(),
            cancellationToken);

        return Ok(Map(task));
    }

    private static WorkflowTaskResponse Map(WorkflowTask task)
    {
        return new WorkflowTaskResponse(
            task.Id,
            task.TenantId,
            task.DocumentId,
            task.Title,
            task.Notes,
            task.AssignedToUserId,
            task.Status.ToString().ToUpperInvariant(),
            task.CreatedByUserId,
            task.CreatedAtUtc,
            task.DueAtUtc,
            task.CompletedByUserId,
            task.CompletedAtUtc);
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

    private Guid? ResolveCurrentOrganizationId()
    {
        var tenantClaim = User.FindFirstValue("tenant_id");
        return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : null;
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
