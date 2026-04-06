using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace WindowsTwain;

internal sealed partial class LocalApiHost
{
    private void MapEndpoints(WebApplication app)
    {
        app.MapGet("/", () => Results.Redirect("/health"));
        MapHealthEndpoints(app);
        MapSessionEndpoints(app);
        MapScannerEndpoints(app);
        MapScanEndpoints(app);
    }

    private void MapHealthEndpoints(WebApplication app)
    {
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
            Sessions: scannerService.GetSessionStoreStatus(),
            Operations: scannerService.GetOperations(),
            Notes: "Host local inicial listo. La integracion con escaner y el flujo con SID se completaran en fases posteriores.")));

        app.MapGet("/api/operations", () => Results.Json(scannerService.GetOperations()));
    }

    private void MapSessionEndpoints(WebApplication app)
    {
        app.MapGet("/api/sessions", () => Results.Json(scannerService.GetActiveSessions()));
        app.MapDelete("/api/sessions", () => Results.Json(BuildSessionStatusResponse(scannerService.ClearActiveSessions(), "Se vaciaron las sesiones activas del host local.")));
        app.MapDelete("/api/sessions/stale", () => Results.Json(BuildSessionStatusResponse(scannerService.ClearStaleSessions(), "Se vaciaron las sesiones inactivas del host local.")));
        app.MapDelete("/api/sessions/rehydrated", () => Results.Json(BuildSessionStatusResponse(scannerService.ClearRehydratedSessions(), "Se vaciaron las sesiones rehidratadas del host local.")));
        app.MapPost("/api/sessions/cleanup", () => Results.Json(BuildSessionStatusResponse(scannerService.CleanupSessionArtifacts(), "Se ejecuto una limpieza de artefactos de sesiones locales.")));
    }

    private ApiStatusResponse BuildSessionStatusResponse(SessionStoreStatusResponse sessions, string notes)
    {
        return new ApiStatusResponse(
            Application: appState.ApplicationName,
            Version: appState.Version,
            BaseUrl: BaseUrl,
            StartedAtUtc: appState.StartedAtUtc,
            RunMode: appState.RunMode,
            StartupLogPath: appState.StartupLogPath,
            Scanner: scannerService.GetStatus(),
            Sessions: sessions,
            Operations: scannerService.GetOperations(),
            Notes: notes);
    }

    private void MapScannerEndpoints(WebApplication app)
    {
        app.MapGet("/api/scanners", () => Results.Json(scannerService.DiscoverScanners()));
        app.MapPost("/api/scanners/discover", () => Results.Json(scannerService.DiscoverScanners()));
    }
}
