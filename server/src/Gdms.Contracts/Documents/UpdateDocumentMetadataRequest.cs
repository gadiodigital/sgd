using System.Text.Json;

namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents the payload used to replace the current metadata object of a document.
/// </summary>
public sealed record UpdateDocumentMetadataRequest(JsonElement Metadata);
