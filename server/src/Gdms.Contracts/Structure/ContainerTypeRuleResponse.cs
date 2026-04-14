namespace Gdms.Contracts.Structure;

/// <summary>
/// Allowed parent-child relation between container types.
/// </summary>
public sealed record ContainerTypeRuleResponse(
    Guid Id,
    Guid TenantId,
    Guid ProjectId,
    Guid ParentContainerTypeId,
    Guid ChildContainerTypeId,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
