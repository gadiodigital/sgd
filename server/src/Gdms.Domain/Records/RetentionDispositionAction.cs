namespace Gdms.Domain.Records;

/// <summary>
/// Enumerates the supported disposition outcomes after a retention period ends.
/// </summary>
public enum RetentionDispositionAction
{
    Review = 0,
    Delete = 1,
    Archive = 2
}
