namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents an explicit ACL entry returned by the public document API.
/// </summary>
public sealed record DocumentAccessEntryResponse(
    Guid Id,
    Guid TenantId,
    Guid DocumentId,
    Guid UserId,
    string PermissionCode,
    Guid? GrantedByUserId,
    DateTimeOffset GrantedAtUtc);
