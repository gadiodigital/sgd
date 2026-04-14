namespace Gdms.Contracts.Structure;

/// <summary>
/// Request used to allow a parent-child relation between container types.
/// </summary>
public sealed record CreateContainerTypeRuleRequest(
    Guid ParentContainerTypeId,
    Guid ChildContainerTypeId);
