namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents a document returned by the public API.
/// </summary>
public sealed record DocumentResponse(
    Guid Id,
    Guid TenantId,
    string DocumentTypeCode,
    string Title,
    string Status,
    int VersionCount,
    DateTimeOffset CreatedAtUtc);
