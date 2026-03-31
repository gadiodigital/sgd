namespace Gdms.Contracts.Documents;

/// <summary>
/// Represents an immutable version returned by the public document API.
/// </summary>
public sealed record DocumentVersionResponse(
    Guid Id,
    int VersionNumber,
    string MimeType,
    string FileHashSha256,
    long FileSizeBytes,
    Guid? UploadedByUserId,
    DateTimeOffset UploadedAtUtc);
