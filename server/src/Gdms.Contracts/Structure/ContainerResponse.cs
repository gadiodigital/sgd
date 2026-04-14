using System.Text.Json;

namespace Gdms.Contracts.Structure;

/// <summary>
/// Concrete node in a configurable document hierarchy.
/// </summary>
public sealed record ContainerResponse(
    Guid Id,
    Guid TenantId,
    Guid ProjectId,
    Guid ContainerTypeId,
    Guid? ParentContainerId,
    string Code,
    string Name,
    JsonElement Metadata,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
