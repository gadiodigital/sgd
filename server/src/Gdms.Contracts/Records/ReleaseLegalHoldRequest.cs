using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Records;

/// <summary>
/// Represents the payload used to release a legal hold.
/// </summary>
public sealed class ReleaseLegalHoldRequest
{
    /// <summary>
    /// Gets or sets the release justification.
    /// </summary>
    [Required]
    [MaxLength(240)]
    public string Reason { get; init; } = string.Empty;
}
