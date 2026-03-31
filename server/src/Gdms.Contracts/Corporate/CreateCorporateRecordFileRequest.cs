namespace Gdms.Contracts.Corporate;

/// <summary>
/// Captures the payload used to create a corporate record file.
/// </summary>
public sealed record CreateCorporateRecordFileRequest(
    string Code,
    string Title,
    string Category,
    string OwnerArea);
