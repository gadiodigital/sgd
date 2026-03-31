namespace Gdms.Contracts.Cases;

/// <summary>
/// Represents the payload required to create a case file.
/// </summary>
public sealed record CreateCaseFileRequest(
    string Code,
    string Title,
    string Category);
