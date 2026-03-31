namespace Gdms.Contracts.RealEstate;

/// <summary>
/// Describes a property file returned by the API.
/// </summary>
public sealed record PropertyFileResponse(
    Guid Id,
    Guid TenantId,
    string Code,
    string Title,
    string Address,
    string OperationType,
    string Status,
    Guid? CreatedByUserId,
    DateTimeOffset CreatedAtUtc);
