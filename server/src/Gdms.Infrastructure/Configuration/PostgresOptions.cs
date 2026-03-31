namespace Gdms.Infrastructure.Configuration;

/// <summary>
/// Represents the main PostgreSQL connection configuration.
/// </summary>
public sealed class PostgresOptions
{
    /// <summary>
    /// Gets or sets the database connection string.
    /// </summary>
    public string MainDatabase { get; set; } = string.Empty;
}
