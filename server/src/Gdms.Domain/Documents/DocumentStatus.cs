namespace Gdms.Domain.Documents;

/// <summary>
/// Defines the high-level lifecycle states supported by the document aggregate.
/// </summary>
public enum DocumentStatus
{
    Draft = 1,
    Active = 2,
    Archived = 3,
    Disposed = 4
}
