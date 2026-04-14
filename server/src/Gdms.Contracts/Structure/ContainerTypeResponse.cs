using System.Text.Json;

namespace Gdms.Contracts.Structure;

/// <summary>
/// Configurable type for nodes in a document structure project.
/// </summary>
public sealed record ContainerTypeResponse(
    Guid Id,
    Guid TenantId,
    Guid ProjectId,
    string Code,
    string Name,
    string IconKey,
    bool IsRootAllowed,
    bool AcceptsDocuments,
    JsonElement MetadataSchema,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
