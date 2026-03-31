using Gdms.Domain.Common;

namespace Gdms.Domain.Workflow;

/// <summary>
/// Represents a simple tenant-scoped workflow task linked to a document.
/// </summary>
public sealed class WorkflowTask
{
    private WorkflowTask(
        Guid id,
        Guid tenantId,
        Guid documentId,
        string title,
        string? notes,
        Guid? assignedToUserId,
        WorkflowTaskStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc,
        DateTimeOffset? dueAtUtc,
        Guid? completedByUserId,
        DateTimeOffset? completedAtUtc)
    {
        Id = id;
        TenantId = tenantId;
        DocumentId = documentId;
        Title = title;
        Notes = notes;
        AssignedToUserId = assignedToUserId;
        Status = status;
        CreatedByUserId = createdByUserId;
        CreatedAtUtc = createdAtUtc;
        DueAtUtc = dueAtUtc;
        CompletedByUserId = completedByUserId;
        CompletedAtUtc = completedAtUtc;
    }

    public Guid Id { get; }
    public Guid TenantId { get; }
    public Guid DocumentId { get; }
    public string Title { get; }
    public string? Notes { get; }
    public Guid? AssignedToUserId { get; }
    public WorkflowTaskStatus Status { get; private set; }
    public Guid? CreatedByUserId { get; }
    public DateTimeOffset CreatedAtUtc { get; }
    public DateTimeOffset? DueAtUtc { get; }
    public Guid? CompletedByUserId { get; private set; }
    public DateTimeOffset? CompletedAtUtc { get; private set; }

    /// <summary>
    /// Creates a new workflow task for a document.
    /// </summary>
    public static WorkflowTask Create(
        Guid tenantId,
        Guid documentId,
        string title,
        string? notes,
        Guid? assignedToUserId,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc,
        DateTimeOffset? dueAtUtc)
    {
        if (tenantId == Guid.Empty)
        {
            throw new DomainRuleException("El tenant es obligatorio para crear una tarea de workflow.");
        }

        if (documentId == Guid.Empty)
        {
            throw new DomainRuleException("El documento es obligatorio para crear una tarea de workflow.");
        }

        var normalizedTitle = title?.Trim() ?? string.Empty;
        if (normalizedTitle.Length < 3)
        {
            throw new DomainRuleException("La tarea de workflow debe tener un titulo descriptivo.");
        }

        return new WorkflowTask(
            Guid.NewGuid(),
            tenantId,
            documentId,
            normalizedTitle,
            NormalizeNotes(notes),
            NormalizeUserId(assignedToUserId),
            WorkflowTaskStatus.Open,
            createdByUserId,
            createdAtUtc,
            dueAtUtc,
            null,
            null);
    }

    /// <summary>
    /// Rehydrates a workflow task from persistence.
    /// </summary>
    public static WorkflowTask Rehydrate(
        Guid id,
        Guid tenantId,
        Guid documentId,
        string title,
        string? notes,
        Guid? assignedToUserId,
        WorkflowTaskStatus status,
        Guid? createdByUserId,
        DateTimeOffset createdAtUtc,
        DateTimeOffset? dueAtUtc,
        Guid? completedByUserId,
        DateTimeOffset? completedAtUtc)
    {
        return new WorkflowTask(
            id,
            tenantId,
            documentId,
            title,
            notes,
            NormalizeUserId(assignedToUserId),
            status,
            createdByUserId,
            createdAtUtc,
            dueAtUtc,
            completedByUserId,
            completedAtUtc);
    }

    /// <summary>
    /// Marks the task as completed.
    /// </summary>
    public void Complete(Guid completedByUserId, DateTimeOffset completedAtUtc)
    {
        if (Status == WorkflowTaskStatus.Completed)
        {
            throw new DomainRuleException("La tarea de workflow ya se encuentra completada.");
        }

        if (completedByUserId == Guid.Empty)
        {
            throw new DomainRuleException("El usuario que completa la tarea es obligatorio.");
        }

        Status = WorkflowTaskStatus.Completed;
        CompletedByUserId = completedByUserId;
        CompletedAtUtc = completedAtUtc;
    }

    private static string? NormalizeNotes(string? notes)
    {
        var normalized = notes?.Trim();
        return string.IsNullOrWhiteSpace(normalized) ? null : normalized;
    }

    private static Guid? NormalizeUserId(Guid? value)
    {
        return value is { } userId && userId != Guid.Empty ? userId : null;
    }
}
