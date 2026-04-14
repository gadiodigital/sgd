namespace Gdms.Contracts.Structure;

/// <summary>
/// Request used to link an existing document to a hierarchy node.
/// </summary>
public sealed record AttachDocumentToContainerRequest(Guid DocumentId);
