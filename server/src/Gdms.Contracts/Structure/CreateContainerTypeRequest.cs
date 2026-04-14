using System.Text.Json;

namespace Gdms.Contracts.Structure;

/// <summary>
/// Request used to create a container type inside a structure project.
/// </summary>
public sealed record CreateContainerTypeRequest(
    string Code,
    string Name,
    string? IconKey,
    bool IsRootAllowed,
    bool AcceptsDocuments,
    JsonElement MetadataSchema);
