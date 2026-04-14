namespace Gdms.Contracts.Structure;

/// <summary>
/// Request used to create a configurable document structure project.
/// </summary>
public sealed record CreateStructureProjectRequest(
    string Code,
    string Name,
    string? Description);
