using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Tenants;

/// <summary>
/// Represents the payload required to create the initial organization record.
/// </summary>
public sealed class CreateTenantRequest
{
    /// <summary>
    /// Gets or sets the short organization code used in integrations and routing.
    /// </summary>
    [Required]
    [MaxLength(32)]
    public string Code { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the display name of the organization.
    /// </summary>
    [Required]
    [MaxLength(160)]
    public string Name { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the primary business sector for vertical activation.
    /// </summary>
    [Required]
    [MaxLength(80)]
    public string Sector { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the ISO alpha-2 country code of operation.
    /// </summary>
    [Required]
    [StringLength(2, MinimumLength = 2)]
    public string PrimaryCountryCode { get; init; } = "AR";
}
