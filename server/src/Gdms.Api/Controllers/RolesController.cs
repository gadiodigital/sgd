using Gdms.Application.Identity;
using Gdms.Contracts.Identity;
using Gdms.Domain.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Controllers;

/// <summary>
/// Exposes the public HTTP surface for authorization role discovery.
/// </summary>
[ApiController]
[Authorize]
[Route("api/roles")]
public sealed class RolesController : ControllerBase
{
    private readonly RoleService _roleService;

    /// <summary>
    /// Initializes the controller with the application role service.
    /// </summary>
    public RolesController(RoleService roleService)
    {
        _roleService = roleService;
    }

    /// <summary>
    /// Lists the roles available to be assigned inside the platform.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyCollection<RoleResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyCollection<RoleResponse>>> GetAll(CancellationToken cancellationToken)
    {
        var roles = await _roleService.ListAsync(cancellationToken);
        return Ok(roles.Select(Map).ToArray());
    }

    private static RoleResponse Map(Role role)
    {
        return new RoleResponse(role.Id, role.Code, role.Name, role.Description);
    }
}
