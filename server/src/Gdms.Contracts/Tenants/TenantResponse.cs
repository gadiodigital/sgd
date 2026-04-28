namespace Gdms.Contracts.Tenants;

/// <summary>
/// Represents an organization record returned by the public API.
/// </summary>
public sealed record TenantResponse(
    Guid Id,
    string Code,
    string Name,
    string Sector,
    string PrimaryCountryCode,
    DateTimeOffset CreatedAtUtc);
