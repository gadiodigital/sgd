namespace Gdms.Infrastructure.Configuration;

/// <summary>
/// Represents storage configuration for document binaries.
/// </summary>
public sealed class StorageOptions
{
    /// <summary>
    /// Gets or sets the relative or absolute root path used by the local adapter.
    /// </summary>
    public string LocalRootPath { get; set; } = "data/storage/documents";
}
