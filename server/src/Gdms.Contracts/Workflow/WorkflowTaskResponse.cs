namespace Gdms.Contracts.Workflow;

/// <summary>
/// Represents a workflow task returned to API clients.
/// </summary>
public sealed record WorkflowTaskResponse(
    Guid Id,
    Guid TenantId,
    Guid DocumentId,
    string Title,
    string? Notes,
    Guid? AssignedToUserId,
    string Status,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? DueAtUtc,
    Guid? CompletedByUserId,
    DateTimeOffset? CompletedAtUtc);
