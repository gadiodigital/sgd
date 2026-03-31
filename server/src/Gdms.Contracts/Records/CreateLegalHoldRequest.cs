using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Records;

/// <summary>
/// Represents the payload used to create a legal hold.
/// </summary>
public sealed class CreateLegalHoldRequest
{
    /// <summary>
    /// Gets or sets the hold reason.
    /// </summary>
    [Required]
    [MaxLength(240)]
    public string Reason { get; init; } = string.Empty;
}
