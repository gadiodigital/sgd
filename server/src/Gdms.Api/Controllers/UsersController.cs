using System.Security.Claims;
using Gdms.Application.Identity;
using Gdms.Contracts.Identity;
using Gdms.Domain.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes tenant-scoped user management endpoints.
/// </summary>
[ApiController]
[Authorize]
[Route("api/tenants/{tenantId:guid}/users")]
public sealed class UsersController : ControllerBase
{
    private readonly UserService _userService;

    /// <summary>
    /// Initializes the controller with the application user service.
    /// </summary>
    public UsersController(UserService userService)
    {
        _userService = userService;
    }

    /// <summary>
    /// Lists the users of a tenant.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<UserResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyCollection<UserResponse>>> GetAll(
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var users = await _userService.ListByTenantAsync(tenantId, cancellationToken);
        return Ok(users.Select(Map).ToArray());
    }

    /// <summary>
    /// Returns a single user by identifier within a tenant.
    /// </summary>
    [HttpGet("{userId:guid}")]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<UserResponse>> GetById(
        Guid tenantId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var user = await _userService.GetByIdAsync(tenantId, userId, cancellationToken);
        if (user is null)
        {
            return NotFound();
        }

        return Ok(Map(user));
    }

    /// <summary>
    /// Creates a new user inside a tenant.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN")]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<UserResponse>> Create(
        Guid tenantId,
        [FromBody] CreateUserRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var user = await _userService.CreateAsync(
            tenantId,
            request.Email,
            request.FullName,
            request.TemporaryPassword,
            request.InitialStatus,
            request.RoleCodes,
            request.RequirePasswordChange,
            RequireUserId(),
            cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { tenantId, userId = user.Id },
            Map(user));
    }

    /// <summary>
    /// Assigns a role to an existing tenant user.
    /// </summary>
    [HttpPost("{userId:guid}/roles")]
    [Authorize(Roles = "PLATFORM_ADMIN,TENANT_ADMIN")]
    [ProducesResponseType(typeof(UserResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> AssignRole(
        Guid tenantId,
        Guid userId,
        [FromBody] AssignRoleRequest request,
        CancellationToken cancellationToken)
    {
        if (!HasTenantAccess(tenantId))
        {
            return Forbid();
        }

        var existingUser = await _userService.GetByIdAsync(tenantId, userId, cancellationToken);
        if (existingUser is null)
        {
            return NotFound();
        }

        var user = await _userService.AssignRoleAsync(
            tenantId,
            userId,
            request.RoleCode,
            RequireUserId(),
            cancellationToken);

        return Ok(Map(user));
    }

    private static UserResponse Map(User user)
    {
        return new UserResponse(
            user.Id,
            user.TenantId,
            user.Email,
            user.FullName,
            user.Status.ToString().ToUpperInvariant(),
            user.CreatedAtUtc,
            user.Roles.Select(MapRole).ToArray());
    }

    private static RoleResponse MapRole(Role role)
    {
        return new RoleResponse(role.Id, role.Code, role.Name, role.Description);
    }

    private bool HasTenantAccess(Guid tenantId)
    {
        if (User.IsInRole("PLATFORM_ADMIN"))
        {
            return true;
        }

        var tenantClaim = User.FindFirstValue("tenant_id");
        return Guid.TryParse(tenantClaim, out var claimedTenantId) && claimedTenantId == tenantId;
    }

    private Guid RequireUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            throw new UnauthorizedAccessException("No se pudo resolver el usuario autenticado desde el JWT.");
        }

        return userId;
    }
}
