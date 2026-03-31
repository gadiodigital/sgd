using System.Text.Json;

namespace Gdms.Application.Documents;

/// <summary>
/// Represents a document type and its metadata schema exposed to clients.
/// </summary>
public sealed record DocumentTypeDefinition(
    Guid Id,
    Guid? TenantId,
    string Code,
    string Name,
    string Sector,
    bool IsActive,
    JsonDocument MetadataSchema);
