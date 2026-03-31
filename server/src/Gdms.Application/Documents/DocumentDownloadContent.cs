namespace Gdms.Application.Documents;

/// <summary>
/// Represents a document binary prepared for HTTP download.
/// </summary>
public sealed record DocumentDownloadContent(
    Stream Content,
    string ContentType,
    string DownloadFileName,
    long FileSizeBytes);
