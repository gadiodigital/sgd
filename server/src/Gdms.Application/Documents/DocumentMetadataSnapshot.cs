using System.Text.Json;

namespace Gdms.Application.Documents;

/// <summary>
/// Represents the current metadata object associated with a document.
/// </summary>
public sealed record DocumentMetadataSnapshot(Guid DocumentId, JsonDocument Metadata);
