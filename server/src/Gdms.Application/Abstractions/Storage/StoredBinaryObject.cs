namespace Gdms.Application.Abstractions.Storage;

/// <summary>
/// Represents the persisted metadata returned after storing a binary.
/// </summary>
public sealed record StoredBinaryObject(
    string ObjectKey,
    string FileHashSha256,
    long FileSizeBytes);
