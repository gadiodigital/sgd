namespace Gdms.Contracts.Corporate;

/// <summary>
/// Captures the payload used to link a document to a corporate record file.
/// </summary>
public sealed record AttachDocumentToCorporateRecordFileRequest(Guid DocumentId);
