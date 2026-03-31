using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Auth;

/// <summary>
/// Represents the payload required to bootstrap the first tenant administrator.
/// </summary>
public sealed class BootstrapTenantAdminRequest
{
    /// <summary>
    /// Gets or sets the tenant code to bootstrap.
    /// </summary>
    [Required]
    [MaxLength(32)]
    public string TenantCode { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the administrator email.
    /// </summary>
    [Required]
    [EmailAddress]
    [MaxLength(320)]
    public string Email { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the administrator full name.
    /// </summary>
    [Required]
    [MaxLength(160)]
    public string FullName { get; init; } = string.Empty;

    /// <summary>
    /// Gets or sets the initial local password.
    /// </summary>
    [Required]
    [MinLength(12)]
    [MaxLength(128)]
    public string Password { get; init; } = string.Empty;
}
