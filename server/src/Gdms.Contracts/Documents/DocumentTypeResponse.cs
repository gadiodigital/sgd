using System.Text.Json;

namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents a document type returned to clients, including its metadata schema.
/// </summary>
public sealed record DocumentTypeResponse(
    Guid Id,
    Guid? TenantId,
    string Code,
    string Name,
    string Sector,
    bool IsActive,
    JsonElement MetadataSchema);
