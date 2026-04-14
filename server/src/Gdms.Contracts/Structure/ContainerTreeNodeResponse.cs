using System.Text.Json;

namespace Gdms.Contracts.Structure;

/// <summary>
/// Tree representation of a configurable hierarchy node.
/// </summary>
public sealed record ContainerTreeNodeResponse(
    Guid Id,
    Guid TenantId,
    Guid ProjectId,
    Guid ContainerTypeId,
    Guid? ParentContainerId,
    string Code,
    string Name,
    JsonElement Metadata,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc,
    IReadOnlyCollection<ContainerTreeNodeResponse> Children);
