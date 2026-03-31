using System.Text.Json;
using Gdms.Application.Abstractions.Persistence;
using Gdms.Domain.Common;
using Gdms.Domain.Workflow;

namespace Gdms.Application.Workflow;

/// <summary>
/// Coordinates simple document-centric workflow tasks.
/// </summary>
public sealed class WorkflowService
{
    private readonly IAuditEventRepository _auditEventRepository;
    private readonly IDocumentRepository _documentRepository;
    private readonly ITenantRepository _tenantRepository;
    private readonly IUserRepository _userRepository;
    private readonly IWorkflowTaskRepository _workflowTaskRepository;

    /// <summary>
    /// Initializes the workflow service with repositories required by the workflow use cases.
    /// </summary>
    public WorkflowService(
        IWorkflowTaskRepository workflowTaskRepository,
        ITenantRepository tenantRepository,
        IDocumentRepository documentRepository,
        IUserRepository userRepository,
        IAuditEventRepository auditEventRepository)
    {
        _workflowTaskRepository = workflowTaskRepository;
        _tenantRepository = tenantRepository;
        _documentRepository = documentRepository;
        _userRepository = userRepository;
        _auditEventRepository = auditEventRepository;
    }

    /// <summary>
    /// Lists workflow tasks of a tenant.
    /// </summary>
    public async Task<IReadOnlyCollection<WorkflowTask>> ListByTenantAsync(
        Guid tenantId,
        Guid? assignedToUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        return await _workflowTaskRepository.ListByTenantAsync(
            tenantId,
            assignedToUserId,
            cancellationToken);
    }

    /// <summary>
    /// Creates a workflow task linked to a tenant document.
    /// </summary>
    public async Task<WorkflowTask> CreateAsync(
        Guid tenantId,
        Guid documentId,
        string title,
        string? notes,
        Guid? assignedToUserId,
        DateTimeOffset? dueAtUtc,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var document = await _documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe el documento informado para crear la tarea.");
        }

        if (assignedToUserId is { } assigneeId)
        {
            var assignee = await _userRepository.GetByIdAsync(tenantId, assigneeId, cancellationToken);
            if (assignee is null)
            {
                throw new DomainRuleException("No existe el usuario asignado informado para la tarea.");
            }
        }

        var task = WorkflowTask.Create(
            tenantId,
            documentId,
            title,
            notes,
            assignedToUserId,
            actorUserId,
            DateTimeOffset.UtcNow,
            dueAtUtc);
        var persistedTask = await _workflowTaskRepository.AddAsync(task, cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            documentId,
            "WORKFLOW_TASK_CREATED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                persistedTask.Id,
                persistedTask.Title,
                persistedTask.AssignedToUserId,
                persistedTask.DueAtUtc
            }),
            cancellationToken);

        return persistedTask;
    }

    /// <summary>
    /// Completes an open workflow task.
    /// </summary>
    public async Task<WorkflowTask> CompleteAsync(
        Guid tenantId,
        Guid taskId,
        Guid actorUserId,
        CancellationToken cancellationToken)
    {
        await EnsureTenantExistsAsync(tenantId, cancellationToken);
        var task = await _workflowTaskRepository.GetByIdAsync(taskId, cancellationToken);
        if (task is null || task.TenantId != tenantId)
        {
            throw new DomainRuleException("No existe la tarea de workflow informada.");
        }

        task.Complete(actorUserId, DateTimeOffset.UtcNow);
        await _workflowTaskRepository.CompleteAsync(
            tenantId,
            taskId,
            actorUserId,
            task.CompletedAtUtc!.Value,
            cancellationToken);

        await _auditEventRepository.WriteAsync(
            tenantId,
            actorUserId,
            task.DocumentId,
            "WORKFLOW_TASK_COMPLETED",
            "INFO",
            JsonSerializer.Serialize(new
            {
                task.Id,
                task.Title,
                task.CompletedAtUtc
            }),
            cancellationToken);

        return task;
    }

    private async Task EnsureTenantExistsAsync(Guid tenantId, CancellationToken cancellationToken)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant informado es obligatorio para workflow.");
        }

        var tenant = await _tenantRepository.GetByIdAsync(tenantId, cancellationToken);
        if (tenant is null)
        {
            throw new DomainRuleException("No existe el tenant informado para workflow.");
        }
    }
}
