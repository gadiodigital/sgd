using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Identity;

/// <summary>
/// Represents the payload required to create a tenant-scoped user.
/// </summary>
public sealed class CreateUserRequest
{
    /// <summary>
    /// Gets or sets the user email.
    /// </summary>
    [Required]
    [EmailAddress]
    [MaxLength(320)]
    public string Email { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the full name.
    /// </summary>
    [Required]
    [MaxLength(160)]
    public string FullName { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the temporary password assigned to the user.
    /// </summary>
    [Required]
    [MinLength(12)]
    [MaxLength(128)]
    public string TemporaryPassword { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the initial lifecycle status.
    /// </summary>
    [MaxLength(24)]
    public string InitialStatus { get; init; } = "PENDING";

    /// <summary>
    /// Gets or sets the initial role codes to assign.
    /// </summary>
    public string[] RoleCodes { get; init; } = [];

    /// <summary>
    /// Gets or sets whether the user must rotate the password on first login.
    /// </summary>
    public bool RequirePasswordChange { get; init; } = true;
}
