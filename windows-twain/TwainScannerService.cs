using NTwain;
using NTwain.Data;

namespace WindowsTwain;

internal sealed partial class TwainScannerService : IScannerService
{
    private const int DefaultTimeoutSeconds = 90;
    private static readonly IReadOnlyList<ScanOperationDescriptor> Operations =
    [
        new("list-scanners", "Listar escaneres detectados por el host local via TWAIN.", "ready", "json"),
        new("clear-active-sessions", "Vaciar todas las sesiones activas del host local.", "ready", "json"),
        new("clear-stale-sessions", "Vaciar sesiones inactivas del host local.", "ready", "json"),
        new("clear-rehydrated-sessions", "Vaciar sesiones rehidratadas del host local.", "ready", "json"),
        new("cleanup-session-artifacts", "Limpiar carpetas huerfanas de sesiones locales.", "ready", "json"),
        new("scan-flatbed-single", "Escanear una hoja desde cama plana con parametros opcionales de dpi y pixelType.", "ready", "scan-session"),
        new("scan-adf-simplex", "Escanear todo el ADF de un solo lado con parametros opcionales de dpi, pixelType y descarte de paginas en blanco.", "ready", "scan-session"),
        new("scan-adf-duplex", "Escanear todo el ADF en doble faz con parametros opcionales de dpi, pixelType y descarte de paginas en blanco.", "ready", "scan-session"),
        new("get-session", "Consultar el estado y las paginas de una sesion de escaneo.", "ready", "json"),
        new("get-page-preview", "Generar una vista previa JPEG liviana de una pagina de una sesion.", "ready", "image/jpeg"),
        new("delete-page", "Eliminar una pagina de una sesion y renumerar el resto.", "ready", "json"),
        new("rotate-page", "Rotar una pagina de una sesion en incrementos de 90 grados.", "ready", "json"),
        new("move-page", "Mover una pagina a otra posicion dentro de la sesion.", "ready", "json"),
        new("adjust-page", "Ajustar brillo y contraste sobre la imagen de una pagina.", "ready", "json"),
        new("merge-session", "Insertar paginas de otra sesion escaneada dentro de la sesion actual.", "ready", "json"),
        new("export-pdf", "Exportar una sesion como PDF final.", "ready", "application/pdf")
    ];

    private readonly TwainThreadInvoker twainThread = new();
    private readonly ScanSessionStore sessionStore = new();

    public ScannerStatusResponse GetStatus()
    {
        return new ScannerStatusResponse(
            DriversReady: true,
            DeviceDiscoveryImplemented: true,
            ScanImplemented: true,
            Message: $"Discovery TWAIN habilitado. Escaneo ADF simplex/duplex y flatbed single habilitado. Arquitectura del proceso: {Environment.Is64BitProcess switch { true => "x64", false => "x86" }}.");
    }

    public SessionStoreStatusResponse GetSessionStoreStatus() => sessionStore.GetStatus();
    public IReadOnlyList<ActiveScanSessionSummary> GetActiveSessions() => sessionStore.ListActiveSessions();
    public IReadOnlyList<ScanOperationDescriptor> GetOperations() => Operations;
    public SessionStoreStatusResponse CleanupSessionArtifacts() => sessionStore.CleanupStaleArtifacts();
    public SessionStoreStatusResponse ClearActiveSessions() => sessionStore.ClearActiveSessions();
    public SessionStoreStatusResponse ClearStaleSessions() => sessionStore.ClearStaleSessions();
    public SessionStoreStatusResponse ClearRehydratedSessions() => sessionStore.ClearRehydratedSessions();

    public ScannerDiscoveryResponse DiscoverScanners()
    {
        try
        {
            var scanners = twainThread.Invoke(() =>
            {
                var session = new TwainSession(DataGroups.Control | DataGroups.Image);
                var openResult = session.Open();
                if (!IsSuccessful(openResult))
                {
                    throw new InvalidOperationException($"No fue posible abrir el Data Source Manager TWAIN. ReturnCode={openResult}.");
                }

                try
                {
                    return session.GetSources()
                        .Select(source => new ScannerDescriptor(
                            Id: source.Id,
                            Name: source.Name ?? string.Empty,
                            Manufacturer: source.Manufacturer ?? string.Empty,
                            ProductFamily: source.ProductFamily ?? string.Empty,
                            TwainVersion: source.Version.ToString(),
                            IsOpen: source.IsOpen))
                        .OrderBy(source => source.Name, StringComparer.OrdinalIgnoreCase)
                        .ToArray();
                }
                finally
                {
                    session.Close();
                }
            });

            var message = scanners.Length == 0
                ? "No se detectaron escaneres TWAIN. Si el equipo tiene driver instalado, revisar compatibilidad de arquitectura x86/x64."
                : $"Se detectaron {scanners.Length} escaner(es) TWAIN.";

            return new ScannerDiscoveryResponse(
                Result: "ok",
                TimestampUtc: DateTimeOffset.UtcNow,
                Transport: "twain",
                ProcessArchitecture: Environment.Is64BitProcess ? "x64" : "x86",
                Scanners: scanners,
                Message: message);
        }
        catch (Exception ex)
        {
            StartupLog.Write("Error al listar escaneres TWAIN: " + ex);
            return new ScannerDiscoveryResponse(
                Result: "error",
                TimestampUtc: DateTimeOffset.UtcNow,
                Transport: "twain",
                ProcessArchitecture: Environment.Is64BitProcess ? "x64" : "x86",
                Scanners: [],
                Message: ex.Message);
        }
    }

    public ScanSessionResponse ScanAdfSimplex(ScanAdfSimplexRequest? request)
    {
        request ??= new ScanAdfSimplexRequest(null, null);
        return ExecuteScan(request.ScannerId, request.ScannerName, request.TimeoutSeconds, request.Dpi, request.PixelType, request.DiscardBlankPages, "adf-simplex");
    }

    public ScanSessionResponse ScanAdfDuplex(ScanAdfDuplexRequest? request)
    {
        request ??= new ScanAdfDuplexRequest(null, null);
        return ExecuteScan(request.ScannerId, request.ScannerName, request.TimeoutSeconds, request.Dpi, request.PixelType, request.DiscardBlankPages, "adf-duplex");
    }

    public ScanSessionResponse ScanFlatbedSingle(ScanFlatbedSingleRequest? request)
    {
        request ??= new ScanFlatbedSingleRequest(null, null);
        return ExecuteScan(request.ScannerId, request.ScannerName, request.TimeoutSeconds, request.Dpi, request.PixelType, request.DiscardBlankPages, "flatbed-single");
    }

    public ScanSessionResponse? GetSession(string sessionId) => sessionStore.Get(sessionId);
    public void DeleteSession(string sessionId) => ExecuteSessionMutation(sessionId, sessionStore.DeleteSession, $"Error al eliminar la sesion {sessionId}: ");

    public ScanSessionResponse RotatePage(string sessionId, int pageNumber, RotatePageRequest? request)
    {
        request ??= new RotatePageRequest();
        return ExecuteSessionPageMutation(sessionId, pageNumber, session => session.RotatePage(pageNumber, request.Degrees), "rotar");
    }

    public ScanSessionResponse DeletePage(string sessionId, int pageNumber)
        => ExecuteSessionPageMutation(sessionId, pageNumber, session => session.DeletePage(pageNumber), "eliminar");

    public ScanSessionResponse MovePage(string sessionId, int pageNumber, MovePageRequest? request)
    {
        request ??= new MovePageRequest(pageNumber);
        return ExecuteSessionPageMutation(sessionId, pageNumber, session => session.MovePage(pageNumber, request.TargetPageNumber), "mover");
    }

    public ScanSessionResponse AdjustPage(string sessionId, int pageNumber, AdjustPageRequest? request)
    {
        request ??= new AdjustPageRequest();
        return ExecuteSessionPageMutation(sessionId, pageNumber, session => session.AdjustPage(pageNumber, request.Brightness, request.Contrast), "ajustar");
    }

    public ScanSessionResponse MergeSession(string sessionId, MergeSessionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.SourceSessionId))
        {
            throw new InvalidOperationException("SourceSessionId es obligatorio.");
        }

        try
        {
            return sessionStore.MergeSessions(sessionId, request.SourceSessionId, request.InsertAfterPageNumber);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al fusionar la sesion {request.SourceSessionId} dentro de {sessionId}: " + ex);
            throw;
        }
    }

    public PagePreviewArtifact GetPagePreview(string sessionId, int pageNumber, int? width, int? height, int? quality)
        => ExecuteSessionRead(sessionId, pageNumber, session => PagePreviewExporter.Export(session, pageNumber, width, height, quality), "generar preview");

    public SessionPdfArtifact ExportSessionPdf(string sessionId)
        => ExecuteSessionRead(sessionId, null, session => PdfSessionExporter.Export(session), "exportar PDF");

    public OperationInvocationResponse InvokePlaceholder(string operationId)
    {
        return new OperationInvocationResponse(
            OperationId: operationId,
            Result: "not-ready",
            Message: "La operacion existe pero todavia no esta implementada en esta fase.",
            TimestampUtc: DateTimeOffset.UtcNow);
    }

    private sealed record ScanRequestOptions(int TimeoutSeconds, int? Dpi, PixelType? PixelType, BlankPage DiscardBlankPages)
    {
        public ScanSettingsResponse ToResponse()
        {
            return new ScanSettingsResponse(Dpi, ToApiPixelType(PixelType), ToApiBlankPageMode(DiscardBlankPages), "bmp");
        }
    }
}
