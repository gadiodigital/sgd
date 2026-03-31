namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents the payload required to grant explicit access to a document.
/// </summary>
public sealed record GrantDocumentAccessRequest(
    Guid UserId,
    string PermissionCode);
