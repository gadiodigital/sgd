namespace Gdms.Contracts.RealEstate;

/// <summary>
/// Captures the payload used to create a property file.
/// </summary>
public sealed record CreatePropertyFileRequest(
    string Code,
    string Title,
    string Address,
    string OperationType);
