using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Auth;

/// <summary>
/// Represents the payload required to authenticate with local credentials.
/// </summary>
public sealed class LoginRequest
{
    /// <summary>
    /// Gets or sets the tenant code used to resolve the login scope.
    /// </summary>
    [Required]
    [MaxLength(32)]
    public string TenantCode { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the user email.
    /// </summary>
    [Required]
    [EmailAddress]
    [MaxLength(320)]
    public string Email { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the clear-text password.
    /// </summary>
    [Required]
    [MinLength(12)]
    [MaxLength(128)]
    public string Password { get; init; } = string.Empty;
}
