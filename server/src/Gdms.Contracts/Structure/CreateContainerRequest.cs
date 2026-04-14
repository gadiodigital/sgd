using System.Text.Json;

namespace Gdms.Contracts.Structure;

/// <summary>
/// Request used to create a node in the configurable hierarchy.
/// </summary>
public sealed record CreateContainerRequest(
    Guid ContainerTypeId,
    Guid? ParentContainerId,
    string Code,
    string Name,
    JsonElement Metadata);
