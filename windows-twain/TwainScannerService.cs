using NTwain;
using NTwain.Data;

namespace WindowsTwain;

internal sealed class TwainScannerService : IScannerService
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

    public SessionStoreStatusResponse GetSessionStoreStatus()
    {
        return sessionStore.GetStatus();
    }

    public IReadOnlyList<ActiveScanSessionSummary> GetActiveSessions()
    {
        return sessionStore.ListActiveSessions();
    }

    public IReadOnlyList<ScanOperationDescriptor> GetOperations()
    {
        return Operations;
    }

    public SessionStoreStatusResponse CleanupSessionArtifacts()
    {
        return sessionStore.CleanupStaleArtifacts();
    }

    public SessionStoreStatusResponse ClearActiveSessions()
    {
        return sessionStore.ClearActiveSessions();
    }

    public SessionStoreStatusResponse ClearStaleSessions()
    {
        return sessionStore.ClearStaleSessions();
    }

    public SessionStoreStatusResponse ClearRehydratedSessions()
    {
        return sessionStore.ClearRehydratedSessions();
    }

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
        var options = NormalizeRequest(request.TimeoutSeconds, request.Dpi, request.PixelType, request.DiscardBlankPages);

        try
        {
            return twainThread.Invoke(() => ScanAdfCore(
                scannerId: request.ScannerId,
                scannerName: request.ScannerName,
                options: options,
                duplex: false));
        }
        catch (Exception ex)
        {
            StartupLog.Write("Error al ejecutar scan-adf-simplex: " + ex);

            return new ScanSessionResponse(
                Result: "error",
                SessionId: string.Empty,
                Status: "error",
                CreatedAtUtc: DateTimeOffset.UtcNow,
                ScannerName: request.ScannerName ?? "(no resuelto)",
                Mode: "adf-simplex",
                Settings: options.ToResponse(),
                PageCount: 0,
                Pages: [],
                SessionPath: string.Empty,
                Message: ex.Message);
        }
    }

    public ScanSessionResponse ScanAdfDuplex(ScanAdfDuplexRequest? request)
    {
        request ??= new ScanAdfDuplexRequest(null, null);
        var options = NormalizeRequest(request.TimeoutSeconds, request.Dpi, request.PixelType, request.DiscardBlankPages);

        try
        {
            return twainThread.Invoke(() => ScanAdfCore(
                scannerId: request.ScannerId,
                scannerName: request.ScannerName,
                options: options,
                duplex: true));
        }
        catch (Exception ex)
        {
            StartupLog.Write("Error al ejecutar scan-adf-duplex: " + ex);

            return new ScanSessionResponse(
                Result: "error",
                SessionId: string.Empty,
                Status: "error",
                CreatedAtUtc: DateTimeOffset.UtcNow,
                ScannerName: request.ScannerName ?? "(no resuelto)",
                Mode: "adf-duplex",
                Settings: options.ToResponse(),
                PageCount: 0,
                Pages: [],
                SessionPath: string.Empty,
                Message: ex.Message);
        }
    }

    public ScanSessionResponse ScanFlatbedSingle(ScanFlatbedSingleRequest? request)
    {
        request ??= new ScanFlatbedSingleRequest(null, null);
        var options = NormalizeRequest(request.TimeoutSeconds, request.Dpi, request.PixelType, request.DiscardBlankPages);

        try
        {
            return twainThread.Invoke(() => ScanCore(
                scannerId: request.ScannerId,
                scannerName: request.ScannerName,
                options: options,
                mode: "flatbed-single",
                useFeeder: false,
                duplex: false));
        }
        catch (Exception ex)
        {
            StartupLog.Write("Error al ejecutar scan-flatbed-single: " + ex);

            return new ScanSessionResponse(
                Result: "error",
                SessionId: string.Empty,
                Status: "error",
                CreatedAtUtc: DateTimeOffset.UtcNow,
                ScannerName: request.ScannerName ?? "(no resuelto)",
                Mode: "flatbed-single",
                Settings: options.ToResponse(),
                PageCount: 0,
                Pages: [],
                SessionPath: string.Empty,
                Message: ex.Message);
        }
    }

    public ScanSessionResponse? GetSession(string sessionId)
    {
        return sessionStore.Get(sessionId);
    }

    public void DeleteSession(string sessionId)
    {
        try
        {
            sessionStore.DeleteSession(sessionId);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al eliminar la sesion {sessionId}: " + ex);
            throw;
        }
    }

    public ScanSessionResponse RotatePage(string sessionId, int pageNumber, RotatePageRequest? request)
    {
        request ??= new RotatePageRequest();

        try
        {
            var session = sessionStore.GetState(sessionId);
            return session.RotatePage(pageNumber, request.Degrees);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al rotar pagina {pageNumber} de la sesion {sessionId}: " + ex);
            throw;
        }
    }

    public ScanSessionResponse DeletePage(string sessionId, int pageNumber)
    {
        try
        {
            var session = sessionStore.GetState(sessionId);
            return session.DeletePage(pageNumber);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al eliminar pagina {pageNumber} de la sesion {sessionId}: " + ex);
            throw;
        }
    }

    public ScanSessionResponse MovePage(string sessionId, int pageNumber, MovePageRequest? request)
    {
        request ??= new MovePageRequest(pageNumber);

        try
        {
            var session = sessionStore.GetState(sessionId);
            return session.MovePage(pageNumber, request.TargetPageNumber);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al mover pagina {pageNumber} de la sesion {sessionId}: " + ex);
            throw;
        }
    }

    public ScanSessionResponse AdjustPage(string sessionId, int pageNumber, AdjustPageRequest? request)
    {
        request ??= new AdjustPageRequest();

        try
        {
            var session = sessionStore.GetState(sessionId);
            return session.AdjustPage(pageNumber, request.Brightness, request.Contrast);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al ajustar pagina {pageNumber} de la sesion {sessionId}: " + ex);
            throw;
        }
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
    {
        try
        {
            var session = sessionStore.GetState(sessionId);
            return PagePreviewExporter.Export(session, pageNumber, width, height, quality);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al generar preview de la sesion {sessionId}, pagina {pageNumber}: " + ex);
            throw;
        }
    }

    public SessionPdfArtifact ExportSessionPdf(string sessionId)
    {
        try
        {
            var session = sessionStore.GetState(sessionId);
            return PdfSessionExporter.Export(session);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al exportar PDF de la sesion {sessionId}: " + ex);
            throw;
        }
    }

    public OperationInvocationResponse InvokePlaceholder(string operationId)
    {
        return new OperationInvocationResponse(
            OperationId: operationId,
            Result: "not-ready",
            Message: "La operacion existe pero todavia no esta implementada en esta fase.",
            TimestampUtc: DateTimeOffset.UtcNow);
    }

    private ScanSessionResponse ScanAdfCore(int? scannerId, string? scannerName, ScanRequestOptions options, bool duplex)
    {
        return ScanCore(
            scannerId: scannerId,
            scannerName: scannerName,
            options: options,
            mode: duplex ? "adf-duplex" : "adf-simplex",
            useFeeder: true,
            duplex: duplex);
    }

    private ScanSessionResponse ScanCore(
        int? scannerId,
        string? scannerName,
        ScanRequestOptions options,
        string mode,
        bool useFeeder,
        bool duplex)
    {
        var session = new TwainSession(DataGroups.Control | DataGroups.Image);
        var openResult = session.Open();
        if (!IsSuccessful(openResult))
        {
            throw new InvalidOperationException($"No fue posible abrir el Data Source Manager TWAIN. ReturnCode={openResult}.");
        }

        try
        {
            var source = ResolveSource(session, scannerId, scannerName);
            var completed = false;
            Exception? scanError = null;
            var timeout = TimeSpan.FromSeconds(Math.Clamp(options.TimeoutSeconds, 15, 300));
            ScanSessionStore.ScanSessionState? sessionState = null;
            var incomingPath = string.Empty;

            session.DataTransferred += (_, e) =>
            {
                try
                {
                    if (sessionState is null || string.IsNullOrWhiteSpace(incomingPath))
                    {
                        throw new InvalidOperationException("La sesion de escaneo no estaba inicializada al recibir la pagina.");
                    }

                    var pageNumber = sessionState.Pages.Count + 1;
                    SaveTransferredPage(sessionState, pageNumber, e, incomingPath);
                    if (!useFeeder)
                    {
                        completed = true;
                    }
                }
                catch (Exception ex)
                {
                    scanError = ex;
                    completed = true;
                }
            };
            session.TransferError += (_, e) =>
            {
                scanError = e.Exception ?? new InvalidOperationException($"TransferError: ReturnCode={e.ReturnCode}, SourceStatus={e.SourceStatus.ConditionCode}.");
                completed = true;
            };
            session.TransferCanceled += (_, _) =>
            {
                if (sessionState is not null)
                {
                    sessionState.Status = "canceled";
                    sessionState.Message = "La transferencia fue cancelada.";
                }

                completed = true;
            };
            session.SourceDisabled += (_, _) =>
            {
                completed = true;
            };

            var sourceOpenResult = source.Open();
            if (!IsSuccessful(sourceOpenResult))
            {
                throw new InvalidOperationException($"No fue posible abrir el escaner seleccionado. ReturnCode={sourceOpenResult}.");
            }

            try
            {
                var modeSettings = useFeeder
                    ? ConfigureAdf(source, options, duplex)
                    : ConfigureFlatbed(source, options);
                sessionState = sessionStore.Create(source.Name ?? $"scanner-{source.Id}", mode, modeSettings);
                incomingPath = Path.Combine(sessionState.SessionPath, "incoming.bmp");
                ConfigureFileTransfer(source, incomingPath);

                var enableResult = source.Enable(SourceEnableMode.NoUI, modal: false, IntPtr.Zero);
                if (!IsSuccessful(enableResult))
                {
                    throw new InvalidOperationException($"No fue posible habilitar el escaner para adquisicion. ReturnCode={enableResult}.");
                }

                var startedAt = DateTime.UtcNow;
                while (!completed)
                {
                    Application.DoEvents();
                    Thread.Sleep(20);

                    if (DateTime.UtcNow - startedAt > timeout)
                    {
                        throw new TimeoutException($"{mode} supero el timeout de {timeout.TotalSeconds:0} segundos.");
                    }
                }

                if (scanError is not null)
                {
                    throw scanError;
                }

                if (sessionState is null)
                {
                    throw new InvalidOperationException("No se pudo inicializar la sesion de escaneo.");
                }

                sessionState.Status = sessionState.Pages.Count > 0 ? "completed" : "empty";
                sessionState.Message = sessionState.Pages.Count > 0
                    ? $"Escaneo finalizado con {sessionState.Pages.Count} pagina(s)."
                    : useFeeder
                        ? "No se capturaron paginas. Verificar si habia hojas cargadas en el ADF."
                        : "No se capturo una pagina desde la cama plana.";

                return sessionState.ToResponse();
            }
            finally
            {
                if (source.IsOpen)
                {
                    source.Close();
                }
            }
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error durante {mode}: " + ex);
            throw;
        }
        finally
        {
            if (session.IsDsmOpen)
            {
                session.Close();
            }
        }
    }

    private static DataSource ResolveSource(TwainSession session, int? scannerId, string? scannerName)
    {
        var sources = session.GetSources().ToArray();
        if (sources.Length == 0)
        {
            throw new InvalidOperationException("No hay escaneres TWAIN disponibles.");
        }

        if (scannerId is int resolvedScannerId)
        {
            var byId = sources.FirstOrDefault(source => source.Id == resolvedScannerId);
            if (byId is null)
            {
                throw new InvalidOperationException($"No se encontro un escaner con id {resolvedScannerId}.");
            }

            return byId;
        }

        if (!string.IsNullOrWhiteSpace(scannerName))
        {
            var byName = sources.FirstOrDefault(source => string.Equals(source.Name, scannerName, StringComparison.OrdinalIgnoreCase));
            if (byName is null)
            {
                throw new InvalidOperationException($"No se encontro un escaner con nombre '{scannerName}'.");
            }

            return byName;
        }

        return sources[0];
    }

    private static ScanSettingsResponse ConfigureAdf(DataSource source, ScanRequestOptions options, bool duplex)
    {
        ValidateFeeder(source);
        ValidateDuplexSupport(source, duplex);

        EnsureSuccess(source.Capabilities.CapFeederEnabled.SetValue(BoolType.True), "CapFeederEnabled");
        EnsureSuccess(source.Capabilities.CapAutoFeed.SetValue(BoolType.True), "CapAutoFeed");
        SetBlankPageHandling(source, options.DiscardBlankPages);
        SetResolution(source, options.Dpi);
        SetPixelType(source, options.PixelType);

        if (source.Capabilities.CapDuplexEnabled.IsSupported && source.Capabilities.CapDuplexEnabled.CanSet)
        {
            EnsureSuccess(source.Capabilities.CapDuplexEnabled.SetValue(duplex ? BoolType.True : BoolType.False), "CapDuplexEnabled");
        }

        return new ScanSettingsResponse(
            Dpi: ReadAppliedDpi(source) ?? options.Dpi,
            PixelType: ToApiPixelType(ReadAppliedPixelType(source) ?? options.PixelType),
            DiscardBlankPages: ToApiBlankPageMode(ReadAppliedBlankPageHandling(source) ?? options.DiscardBlankPages),
            TransferFormat: "bmp");
    }

    private static ScanSettingsResponse ConfigureFlatbed(DataSource source, ScanRequestOptions options)
    {
        if (source.Capabilities.CapFeederEnabled.IsSupported && source.Capabilities.CapFeederEnabled.CanSet)
        {
            EnsureSuccess(source.Capabilities.CapFeederEnabled.SetValue(BoolType.False), "CapFeederEnabled");
        }

        if (source.Capabilities.CapAutoFeed.IsSupported && source.Capabilities.CapAutoFeed.CanSet)
        {
            EnsureSuccess(source.Capabilities.CapAutoFeed.SetValue(BoolType.False), "CapAutoFeed");
        }

        if (source.Capabilities.CapDuplexEnabled.IsSupported && source.Capabilities.CapDuplexEnabled.CanSet)
        {
            EnsureSuccess(source.Capabilities.CapDuplexEnabled.SetValue(BoolType.False), "CapDuplexEnabled");
        }

        SetResolution(source, options.Dpi);
        SetPixelType(source, options.PixelType);

        return new ScanSettingsResponse(
            Dpi: ReadAppliedDpi(source) ?? options.Dpi,
            PixelType: ToApiPixelType(ReadAppliedPixelType(source) ?? options.PixelType),
            DiscardBlankPages: "off",
            TransferFormat: "bmp");
    }

    private static void ConfigureFileTransfer(DataSource source, string incomingPath)
    {
        EnsureSuccess(source.Capabilities.ICapXferMech.SetValue(XferMech.File), "ICapXferMech");
        EnsureSuccess(source.Capabilities.ICapImageFileFormat.SetValue(FileFormat.Bmp), "ICapImageFileFormat");

        var setup = new TWSetupFileXfer
        {
            FileName = incomingPath,
            Format = FileFormat.Bmp,
            VRefNum = -1
        };

        EnsureSuccess(source.DGControl.SetupFileXfer.Set(setup), "SetupFileXfer");
    }

    private static void SaveTransferredPage(ScanSessionStore.ScanSessionState sessionState, int pageNumber, DataTransferredEventArgs args, string incomingPath)
    {
        if (args.TransferType != XferMech.File)
        {
            throw new InvalidOperationException($"Se esperaba transferencia a archivo y se recibio {args.TransferType}.");
        }

        var sourcePath = string.IsNullOrWhiteSpace(args.FileDataPath) ? incomingPath : args.FileDataPath;
        if (!File.Exists(sourcePath))
        {
            throw new FileNotFoundException("El escaner notifico una transferencia de archivo pero no se encontro el archivo temporal.", sourcePath);
        }

        var extension = Path.GetExtension(sourcePath);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".bmp";
        }

        var pageFileName = $"page-{pageNumber:000}{extension}";
        var destinationPath = Path.Combine(sessionState.SessionPath, pageFileName);
        File.Copy(sourcePath, destinationPath, overwrite: true);

        var fileInfo = new FileInfo(destinationPath);
        sessionState.AddPage(new ScanPageDescriptor(
            PageNumber: pageNumber,
            FileName: pageFileName,
            FilePath: destinationPath,
            TransferType: args.TransferType.ToString(),
            FileFormat: args.ImageFileFormat.ToString(),
            Length: fileInfo.Length));
    }

    private static void ValidateFeeder(DataSource source)
    {
        if (source.Capabilities.CapFeederLoaded.IsSupported &&
            source.Capabilities.CapFeederLoaded.CanGetCurrent &&
            source.Capabilities.CapFeederLoaded.GetCurrent() == BoolType.False)
        {
            throw new InvalidOperationException("El ADF no reporta hojas cargadas.");
        }
    }

    private static void ValidateDuplexSupport(DataSource source, bool duplex)
    {
        if (!duplex)
        {
            return;
        }

        if (source.Capabilities.CapDuplex.IsSupported && source.Capabilities.CapDuplex.CanGetCurrent)
        {
            var duplexMode = source.Capabilities.CapDuplex.GetCurrent();
            if (duplexMode == Duplex.None)
            {
                throw new InvalidOperationException("El escaner seleccionado no reporta soporte duplex.");
            }
        }

        if (!source.Capabilities.CapDuplexEnabled.IsSupported || !source.Capabilities.CapDuplexEnabled.CanSet)
        {
            throw new InvalidOperationException("El driver TWAIN no permite habilitar duplex programaticamente.");
        }
    }

    private static void SetBlankPageHandling(DataSource source, BlankPage blankPage)
    {
        if (!source.Capabilities.ICapAutoDiscardBlankPages.IsSupported || !source.Capabilities.ICapAutoDiscardBlankPages.CanSet)
        {
            if (blankPage == BlankPage.Disable)
            {
                return;
            }

            throw new InvalidOperationException("El driver TWAIN no permite configurar descarte automatico de paginas en blanco.");
        }

        EnsureSuccess(source.Capabilities.ICapAutoDiscardBlankPages.SetValue(blankPage), "ICapAutoDiscardBlankPages");
    }

    private static void SetResolution(DataSource source, int? dpi)
    {
        if (!dpi.HasValue)
        {
            return;
        }

        if (dpi.Value < 50 || dpi.Value > 1200)
        {
            throw new InvalidOperationException("El parametro dpi debe estar entre 50 y 1200.");
        }

        if (!source.Capabilities.ICapXResolution.IsSupported || !source.Capabilities.ICapXResolution.CanSet ||
            !source.Capabilities.ICapYResolution.IsSupported || !source.Capabilities.ICapYResolution.CanSet)
        {
            throw new InvalidOperationException("El driver TWAIN no permite configurar dpi programaticamente.");
        }

        EnsureSuccess(source.Capabilities.ICapXResolution.SetValue((TWFix32)dpi.Value), "ICapXResolution");
        EnsureSuccess(source.Capabilities.ICapYResolution.SetValue((TWFix32)dpi.Value), "ICapYResolution");
    }

    private static void SetPixelType(DataSource source, PixelType? pixelType)
    {
        if (!pixelType.HasValue)
        {
            return;
        }

        if (!source.Capabilities.ICapPixelType.IsSupported || !source.Capabilities.ICapPixelType.CanSet)
        {
            throw new InvalidOperationException("El driver TWAIN no permite configurar pixelType programaticamente.");
        }

        EnsureSuccess(source.Capabilities.ICapPixelType.SetValue(pixelType.Value), "ICapPixelType");
    }

    private static double? ReadAppliedDpi(DataSource source)
    {
        if (!source.Capabilities.ICapXResolution.IsSupported || !source.Capabilities.ICapXResolution.CanGetCurrent)
        {
            return null;
        }

        return (double)source.Capabilities.ICapXResolution.GetCurrent();
    }

    private static PixelType? ReadAppliedPixelType(DataSource source)
    {
        if (!source.Capabilities.ICapPixelType.IsSupported || !source.Capabilities.ICapPixelType.CanGetCurrent)
        {
            return null;
        }

        return source.Capabilities.ICapPixelType.GetCurrent();
    }

    private static BlankPage? ReadAppliedBlankPageHandling(DataSource source)
    {
        if (!source.Capabilities.ICapAutoDiscardBlankPages.IsSupported || !source.Capabilities.ICapAutoDiscardBlankPages.CanGetCurrent)
        {
            return null;
        }

        return source.Capabilities.ICapAutoDiscardBlankPages.GetCurrent();
    }

    private static ScanRequestOptions NormalizeRequest(int timeoutSeconds, int? dpi, string? pixelType, string? discardBlankPages)
    {
        return new ScanRequestOptions(
            TimeoutSeconds: timeoutSeconds <= 0 ? DefaultTimeoutSeconds : timeoutSeconds,
            Dpi: dpi,
            PixelType: ParsePixelType(pixelType),
            DiscardBlankPages: ParseBlankPageMode(discardBlankPages));
    }

    private static PixelType? ParsePixelType(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim().ToLowerInvariant() switch
        {
            "bw" or "b&w" or "blackwhite" or "black-white" or "lineart" => PixelType.BlackWhite,
            "gray" or "grey" or "grayscale" or "greyscale" => PixelType.Gray,
            "color" or "rgb" => PixelType.RGB,
            _ => throw new InvalidOperationException("pixelType debe ser 'bw', 'gray' o 'color'.")
        };
    }

    private static BlankPage ParseBlankPageMode(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return BlankPage.Disable;
        }

        return value.Trim().ToLowerInvariant() switch
        {
            "off" or "disable" or "disabled" or "false" => BlankPage.Disable,
            "auto" or "on" or "enable" or "enabled" or "true" => BlankPage.Auto,
            _ => throw new InvalidOperationException("discardBlankPages debe ser 'off' o 'auto'.")
        };
    }

    private static string ToApiPixelType(PixelType? value)
    {
        return value switch
        {
            PixelType.BlackWhite => "bw",
            PixelType.Gray => "gray",
            PixelType.RGB => "color",
            null => "driver-default",
            _ => value.Value.ToString()
        };
    }

    private static string ToApiBlankPageMode(BlankPage? value)
    {
        return value switch
        {
            BlankPage.Auto => "auto",
            BlankPage.Disable => "off",
            null => "unsupported",
            _ => value.Value.ToString().ToLowerInvariant()
        };
    }

    private static void EnsureSuccess(ReturnCode result, string operation)
    {
        if (!IsSuccessful(result))
        {
            throw new InvalidOperationException($"{operation} devolvio ReturnCode={result}.");
        }
    }

    private static bool IsSuccessful(ReturnCode result)
    {
        return result == ReturnCode.Success || result == ReturnCode.CheckStatus;
    }

    private sealed record ScanRequestOptions(
        int TimeoutSeconds,
        int? Dpi,
        PixelType? PixelType,
        BlankPage DiscardBlankPages)
    {
        public ScanSettingsResponse ToResponse()
        {
            return new ScanSettingsResponse(
                Dpi: Dpi,
                PixelType: ToApiPixelType(PixelType),
                DiscardBlankPages: ToApiBlankPageMode(DiscardBlankPages),
                TransferFormat: "bmp");
        }
    }
}
