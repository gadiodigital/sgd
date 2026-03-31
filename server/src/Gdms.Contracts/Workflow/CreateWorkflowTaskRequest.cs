namespace Gdms.Contracts.Workflow;

/// <summary>
/// Represents the payload required to create a workflow task.
/// </summary>
public sealed record CreateWorkflowTaskRequest(
    Guid DocumentId,
    string Title,
    string? Notes,
    Guid? AssignedToUserId,
    DateTimeOffset? DueAtUtc);
