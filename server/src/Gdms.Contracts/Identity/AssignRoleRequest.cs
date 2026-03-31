using System.ComponentModel.DataAnnotations;

namespace Gdms.Contracts.Identity;

/// <summary>
/// Represents the payload required to assign a role to an existing user.
/// </summary>
public sealed class AssignRoleRequest
{
    /// <summary>
    /// Gets or sets the role code to assign.
    /// </summary>
    [Required]
    [MaxLength(32)]
    public string RoleCode { get; init; } = string.Empty;
}
