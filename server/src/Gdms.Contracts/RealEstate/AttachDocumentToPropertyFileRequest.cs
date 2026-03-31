namespace Gdms.Contracts.RealEstate;

/// <summary>
/// Captures the payload used to link a document to a property file.
/// </summary>
public sealed record AttachDocumentToPropertyFileRequest(Guid DocumentId);
