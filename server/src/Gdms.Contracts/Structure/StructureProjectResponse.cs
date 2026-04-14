namespace Gdms.Contracts.Structure;

/// <summary>
/// Tenant-scoped configurable document structure.
/// </summary>
public sealed record StructureProjectResponse(
    Guid Id,
    Guid TenantId,
    string Code,
    string Name,
    string? Description,
    string Status,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
