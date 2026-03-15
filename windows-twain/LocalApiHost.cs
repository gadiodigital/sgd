using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;

namespace WindowsTwain;

internal sealed class LocalApiHost : IDisposable
{
    private const string CorsPolicyName = "ConfiguredOrigins";
    private readonly ApiOptions apiOptions;
    private readonly AppState appState;
    private readonly IScannerService scannerService;
    private readonly WebApplication webApplication;

    public LocalApiHost(ApiOptions apiOptions, AppState appState, IScannerService scannerService)
    {
        this.apiOptions = apiOptions;
        this.appState = appState;
        this.scannerService = scannerService;

        var builder = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            ApplicationName = typeof(LocalApiHost).Assembly.FullName,
            ContentRootPath = AppContext.BaseDirectory
        });

        builder.WebHost.UseUrls(apiOptions.BaseUrl);
        builder.Services.Configure<JsonOptions>(options =>
        {
            options.SerializerOptions.WriteIndented = true;
        });

        if (apiOptions.AllowedOrigins.Length > 0 || apiOptions.AllowLoopbackOrigins)
        {
            builder.Services.AddCors(options =>
            {
                options.AddPolicy(CorsPolicyName, policy =>
                {
                    policy.SetIsOriginAllowed(IsOriginAllowed)
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                });
            });
        }

        webApplication = builder.Build();

        if (apiOptions.AllowedOrigins.Length > 0 || apiOptions.AllowLoopbackOrigins)
        {
            webApplication.UseCors(CorsPolicyName);
        }

        MapEndpoints(webApplication);
    }

    public string BaseUrl => apiOptions.BaseUrl;

    public string HealthUrl => $"{BaseUrl}/health";

    public string StatusUrl => $"{BaseUrl}/api/status";

    public Task StartAsync(CancellationToken cancellationToken)
    {
        return webApplication.StartAsync(cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return webApplication.StopAsync(cancellationToken);
    }

    public void Dispose()
    {
        webApplication.DisposeAsync().AsTask().GetAwaiter().GetResult();
    }

    private void MapEndpoints(WebApplication app)
    {
        app.MapGet("/", () => Results.Redirect("/health"));

        app.MapGet("/health", () => Results.Json(new HealthResponse(
            Application: appState.ApplicationName,
            Version: appState.Version,
            Status: "ok",
            StartedAtUtc: appState.StartedAtUtc,
            BaseUrl: BaseUrl)));

        app.MapGet("/api/status", () => Results.Json(new ApiStatusResponse(
            Application: appState.ApplicationName,
            Version: appState.Version,
            BaseUrl: BaseUrl,
            StartedAtUtc: appState.StartedAtUtc,
            RunMode: appState.RunMode,
            StartupLogPath: appState.StartupLogPath,
            Scanner: scannerService.GetStatus(),
            Operations: scannerService.GetOperations(),
            Notes: "Host local inicial listo. La integracion con escaner y el flujo con SID se completaran en fases posteriores.")));

        app.MapGet("/api/operations", () => Results.Json(scannerService.GetOperations()));

        app.MapGet("/api/scanners", () => Results.Json(scannerService.DiscoverScanners()));
        app.MapPost("/api/scanners/discover", () => Results.Json(scannerService.DiscoverScanners()));
        app.MapPost("/api/scans/flatbed/single", () => NotImplemented("scan-flatbed-single"));
        app.MapPost("/api/scans/adf/simplex", (ScanAdfSimplexRequest? request) => Results.Json(scannerService.ScanAdfSimplex(request)));
        app.MapPost("/api/scans/adf/duplex", (ScanAdfDuplexRequest? request) => Results.Json(scannerService.ScanAdfDuplex(request)));
        app.MapGet("/api/scans/{sessionId}/pages/{pageNumber:int}/preview", (string sessionId, int pageNumber, int? width, int? height, int? quality) =>
        {
            try
            {
                var preview = scannerService.GetPagePreview(sessionId, pageNumber, width, height, quality);
                return Results.File(
                    path: preview.FilePath,
                    contentType: preview.ContentType);
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message
                });
            }
        });
        app.MapPost("/api/scans/{sessionId}/pages/{pageNumber:int}/rotate", (string sessionId, int pageNumber, RotatePageRequest? request) =>
        {
            try
            {
                return Results.Json(scannerService.RotatePage(sessionId, pageNumber, request));
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message
                });
            }
            catch (FileNotFoundException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message,
                    filePath = ex.FileName
                });
            }
        });
        app.MapDelete("/api/scans/{sessionId}/pages/{pageNumber:int}", (string sessionId, int pageNumber) =>
        {
            try
            {
                return Results.Json(scannerService.DeletePage(sessionId, pageNumber));
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message
                });
            }
            catch (FileNotFoundException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message,
                    filePath = ex.FileName
                });
            }
        });
        app.MapPost("/api/scans/{sessionId}/pages/{pageNumber:int}/move", (string sessionId, int pageNumber, MovePageRequest? request) =>
        {
            try
            {
                return Results.Json(scannerService.MovePage(sessionId, pageNumber, request));
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message
                });
            }
        });
        app.MapPost("/api/scans/{sessionId}/pages/{pageNumber:int}/adjust", (string sessionId, int pageNumber, AdjustPageRequest? request) =>
        {
            try
            {
                return Results.Json(scannerService.AdjustPage(sessionId, pageNumber, request));
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message
                });
            }
            catch (FileNotFoundException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    pageNumber,
                    message = ex.Message,
                    filePath = ex.FileName
                });
            }
        });
        app.MapPost("/api/scans/{sessionId}/merge", (string sessionId, MergeSessionRequest? request) =>
        {
            try
            {
                if (request is null)
                {
                    return Results.BadRequest(new
                    {
                        result = "error",
                        sessionId,
                        message = "Debes indicar la sesion origen a fusionar."
                    });
                }

                return Results.Json(scannerService.MergeSession(sessionId, request));
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (FileNotFoundException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    message = ex.Message,
                    filePath = ex.FileName
                });
            }
        });
        app.MapGet("/api/scans/{sessionId}", (string sessionId) =>
        {
            var session = scannerService.GetSession(sessionId);
            return session is null
                ? Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = "No existe una sesion con ese identificador."
                })
                : Results.Json(session);
        });
        app.MapGet("/api/scans/{sessionId}/pdf", (string sessionId) =>
        {
            try
            {
                var pdf = scannerService.ExportSessionPdf(sessionId);
                return Results.File(
                    path: pdf.FilePath,
                    contentType: "application/pdf",
                    enableRangeProcessing: true);
            }
            catch (KeyNotFoundException ex)
            {
                return Results.NotFound(new
                {
                    result = "not-found",
                    sessionId,
                    message = ex.Message
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new
                {
                    result = "error",
                    sessionId,
                    message = ex.Message
                });
            }
        });
    }

    private IResult NotImplemented(string operationId)
    {
        return Results.Json(
            scannerService.InvokePlaceholder(operationId),
            statusCode: StatusCodes.Status501NotImplemented);
    }

    private bool IsOriginAllowed(string? origin)
    {
        if (string.IsNullOrWhiteSpace(origin))
        {
            return false;
        }

        if (apiOptions.AllowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase))
        {
            return true;
        }

        if (!apiOptions.AllowLoopbackOrigins)
        {
            return false;
        }

        return Uri.TryCreate(origin, UriKind.Absolute, out var uri) && uri.IsLoopback;
    }
}
