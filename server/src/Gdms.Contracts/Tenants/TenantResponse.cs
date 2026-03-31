namespace Gdms.Contracts.Tenants;

/// <summary>
/// Represents a tenant returned by the public API.
/// </summary>
public sealed record TenantResponse(
    Guid Id,
    string Code,
    string Name,
    string Sector,
    string PrimaryCountryCode,
    DateTimeOffset CreatedAtUtc);
