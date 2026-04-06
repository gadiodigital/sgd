using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace WindowsTwain;

internal sealed partial class LocalApiHost
{
    private void MapScanEndpoints(WebApplication app)
    {
        app.MapPost("/api/scans/flatbed/single", (ScanFlatbedSingleRequest? request) => Results.Json(scannerService.ScanFlatbedSingle(request)));
        app.MapPost("/api/scans/adf/simplex", (ScanAdfSimplexRequest? request) => Results.Json(scannerService.ScanAdfSimplex(request)));
        app.MapPost("/api/scans/adf/duplex", (ScanAdfDuplexRequest? request) => Results.Json(scannerService.ScanAdfDuplex(request)));
        app.MapGet("/api/scans/{sessionId}", MapGetSession);
        app.MapDelete("/api/scans/{sessionId}", MapDeleteSession);
        app.MapGet("/api/scans/{sessionId}/pages/{pageNumber:int}/preview", MapGetPreview);
        app.MapPost("/api/scans/{sessionId}/pages/{pageNumber:int}/rotate", MapRotatePage);
        app.MapDelete("/api/scans/{sessionId}/pages/{pageNumber:int}", MapDeletePage);
        app.MapPost("/api/scans/{sessionId}/pages/{pageNumber:int}/move", MapMovePage);
        app.MapPost("/api/scans/{sessionId}/pages/{pageNumber:int}/adjust", MapAdjustPage);
        app.MapPost("/api/scans/{sessionId}/merge", MapMergeSession);
        app.MapGet("/api/scans/{sessionId}/pdf", MapExportPdf);
    }

    private IResult MapGetSession(string sessionId)
    {
        var session = scannerService.GetSession(sessionId);
        return session is null
            ? Results.NotFound(new { result = "not-found", sessionId, message = "No existe una sesion con ese identificador." })
            : Results.Json(session);
    }

    private IResult MapDeleteSession(string sessionId)
    {
        try
        {
            scannerService.DeleteSession(sessionId);
            return Results.NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { result = "not-found", sessionId, message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, message = ex.Message });
        }
    }

    private IResult MapGetPreview(string sessionId, int pageNumber, int? width, int? height, int? quality)
    {
        try
        {
            var preview = scannerService.GetPagePreview(sessionId, pageNumber, width, height, quality);
            return Results.File(path: preview.FilePath, contentType: preview.ContentType);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { result = "not-found", sessionId, message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, pageNumber, message = ex.Message });
        }
    }

    private IResult MapRotatePage(string sessionId, int pageNumber, RotatePageRequest? request)
        => ExecutePageMutation(sessionId, pageNumber, () => scannerService.RotatePage(sessionId, pageNumber, request));

    private IResult MapDeletePage(string sessionId, int pageNumber)
        => ExecutePageMutation(sessionId, pageNumber, () => scannerService.DeletePage(sessionId, pageNumber));

    private IResult MapMovePage(string sessionId, int pageNumber, MovePageRequest? request)
        => ExecutePageMutation(sessionId, pageNumber, () => scannerService.MovePage(sessionId, pageNumber, request));

    private IResult MapAdjustPage(string sessionId, int pageNumber, AdjustPageRequest? request)
        => ExecutePageMutation(sessionId, pageNumber, () => scannerService.AdjustPage(sessionId, pageNumber, request));

    private IResult ExecutePageMutation(string sessionId, int pageNumber, Func<ScanSessionResponse> action)
    {
        try
        {
            return Results.Json(action());
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { result = "not-found", sessionId, message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, pageNumber, message = ex.Message });
        }
        catch (FileNotFoundException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, pageNumber, message = ex.Message, filePath = ex.FileName });
        }
    }

    private IResult MapMergeSession(string sessionId, MergeSessionRequest? request)
    {
        try
        {
            if (request is null)
            {
                return Results.BadRequest(new { result = "error", sessionId, message = "Debes indicar la sesion origen a fusionar." });
            }

            return Results.Json(scannerService.MergeSession(sessionId, request));
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { result = "not-found", sessionId, message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, message = ex.Message });
        }
        catch (FileNotFoundException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, message = ex.Message, filePath = ex.FileName });
        }
    }

    private IResult MapExportPdf(string sessionId)
    {
        try
        {
            var pdf = scannerService.ExportSessionPdf(sessionId);
            return Results.File(path: pdf.FilePath, contentType: "application/pdf", enableRangeProcessing: true);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { result = "not-found", sessionId, message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { result = "error", sessionId, message = ex.Message });
        }
    }
}
