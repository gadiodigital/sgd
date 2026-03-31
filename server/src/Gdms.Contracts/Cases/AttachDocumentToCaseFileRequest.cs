namespace Gdms.Contracts.Cases;

/// <summary>
/// Represents the payload required to link a document to a case file.
/// </summary>
public sealed record AttachDocumentToCaseFileRequest(
    Guid DocumentId);
