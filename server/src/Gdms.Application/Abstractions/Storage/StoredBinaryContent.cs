namespace Gdms.Application.Abstractions.Storage;

/// <summary>
/// Represents a binary payload opened from durable storage.
/// </summary>
public sealed record StoredBinaryContent(
    Stream Content,
    long FileSizeBytes);
