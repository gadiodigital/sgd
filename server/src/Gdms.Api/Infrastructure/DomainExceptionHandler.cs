using Gdms.Domain.Common;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace Gdms.Api.Infrastructure;

/// <summary>
/// Converts domain validation failures into HTTP problem details responses.
/// </summary>
public sealed class DomainExceptionHandler : IExceptionHandler
{
    /// <inheritdoc />
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is UnauthorizedAccessException unauthorizedAccessException)
        {
            var unauthorizedProblem = new ProblemDetails
            {
                Title = "No autorizado",
                Detail = unauthorizedAccessException.Message,
                Status = StatusCodes.Status401Unauthorized,
                Instance = httpContext.Request.Path
            };

            httpContext.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await httpContext.Response.WriteAsJsonAsync(unauthorizedProblem, cancellationToken);
            return true;
        }

        if (exception is not DomainRuleException domainException)
        {
            return false;
        }

        var problem = new ProblemDetails
        {
            Title = "Violación de regla de dominio",
            Detail = domainException.Message,
            Status = StatusCodes.Status400BadRequest,
            Instance = httpContext.Request.Path
        };

        httpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
        await httpContext.Response.WriteAsJsonAsync(problem, cancellationToken);
        return true;
    }
}
