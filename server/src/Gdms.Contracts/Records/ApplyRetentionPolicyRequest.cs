using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Records;

/// <summary>
/// Represents the payload used to assign a retention policy to a document.
/// </summary>
public sealed class ApplyRetentionPolicyRequest
{
    /// <summary>
    /// Gets or sets the retention policy code to apply.
    /// </summary>
    [Required]
    [MaxLength(48)]
    public string RetentionPolicyCode { get; init; } = string.Empty;
}
