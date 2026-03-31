using Gdms.Domain.Workflow;

namespace Gdms.Application.Abstractions.Persistence;

/// <summary>
/// Defines persistence operations for workflow tasks.
/// </summary>
public interface IWorkflowTaskRepository
{
    /// <summary>
    /// Lists workflow tasks that belong to a tenant.
    /// </summary>
    Task<IReadOnlyCollection<WorkflowTask>> ListByTenantAsync(
        Guid tenantId,
        Guid? assignedToUserId,
        CancellationToken cancellationToken);

    /// <summary>
    /// Returns one workflow task by identifier.
    /// </summary>
    Task<WorkflowTask?> GetByIdAsync(Guid taskId, CancellationToken cancellationToken);

    /// <summary>
    /// Persists a new workflow task.
    /// </summary>
    Task<WorkflowTask> AddAsync(WorkflowTask task, CancellationToken cancellationToken);

    /// <summary>
    /// Persists the completion state of a workflow task.
    /// </summary>
    Task CompleteAsync(
        Guid tenantId,
        Guid taskId,
        Guid completedByUserId,
        DateTimeOffset completedAtUtc,
        CancellationToken cancellationToken);
}
