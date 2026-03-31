using System.Text.Json;

namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents the current metadata payload of a document.
/// </summary>
public sealed record DocumentMetadataResponse(Guid DocumentId, JsonElement Metadata);
