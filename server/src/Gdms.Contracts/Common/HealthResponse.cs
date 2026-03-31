namespace Gdms.Contracts.Common;

/// <summary>
/// Represents the public health probe payload exposed by the API.
/// </summary>
/// <param name="Status">Current service status.</param>
/// <param name="UtcNow">Current server time in UTC.</param>
/// <param name="Documentation">Relative Swagger route.</param>
public sealed record HealthResponse(string Status, DateTimeOffset UtcNow, string Documentation);
