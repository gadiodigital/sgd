using NTwain;
using NTwain.Data;

namespace WindowsTwain;

internal sealed partial class TwainScannerService
{
    private ScanSessionResponse ScanAdfCore(int? scannerId, string? scannerName, ScanRequestOptions options, bool duplex)
    {
        return ScanCore(scannerId, scannerName, options, duplex ? "adf-duplex" : "adf-simplex", useFeeder: true, duplex);
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
            return ExecuteSourceScan(session, source, options, mode, useFeeder, duplex);
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

    private ScanSessionResponse ExecuteSourceScan(TwainSession session, DataSource source, ScanRequestOptions options, string mode, bool useFeeder, bool duplex)
    {
        var completed = false;
        Exception? scanError = null;
        var timeout = TimeSpan.FromSeconds(Math.Clamp(options.TimeoutSeconds, 15, 300));
        ScanSessionStore.ScanSessionState? sessionState = null;
        var incomingPath = string.Empty;

        using var subscription = new TwainScanSubscription(
            session,
            onDataTransferred: eventArgs =>
            {
                try
                {
                    if (sessionState is null || string.IsNullOrWhiteSpace(incomingPath))
                    {
                        throw new InvalidOperationException("La sesion de escaneo no estaba inicializada al recibir la pagina.");
                    }

                    SaveTransferredPage(sessionState, sessionState.Pages.Count + 1, eventArgs, incomingPath);
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
            },
            onTransferError: eventArgs =>
            {
                scanError = eventArgs.Exception ?? new InvalidOperationException($"TransferError: ReturnCode={eventArgs.ReturnCode}, SourceStatus={eventArgs.SourceStatus.ConditionCode}.");
                completed = true;
            },
            onTransferCanceled: () =>
            {
                if (sessionState is not null)
                {
                    sessionState.Status = "canceled";
                    sessionState.Message = "La transferencia fue cancelada.";
                }

                completed = true;
            },
            onSourceDisabled: () => completed = true);

        var sourceOpenResult = source.Open();
        if (!IsSuccessful(sourceOpenResult))
        {
            throw new InvalidOperationException($"No fue posible abrir el escaner seleccionado. ReturnCode={sourceOpenResult}.");
        }

        try
        {
            var modeSettings = useFeeder ? ConfigureAdf(source, options, duplex) : ConfigureFlatbed(source, options);
            sessionState = sessionStore.Create(source.Name ?? $"scanner-{source.Id}", mode, modeSettings);
            incomingPath = Path.Combine(sessionState.SessionPath, "incoming.bmp");
            ConfigureFileTransfer(source, incomingPath);

            var enableResult = source.Enable(SourceEnableMode.NoUI, modal: false, IntPtr.Zero);
            if (!IsSuccessful(enableResult))
            {
                throw new InvalidOperationException($"No fue posible habilitar el escaner para adquisicion. ReturnCode={enableResult}.");
            }

            WaitForScanCompletion(mode, timeout, () => completed);
            if (scanError is not null)
            {
                throw scanError;
            }

            if (sessionState is null)
            {
                throw new InvalidOperationException("No se pudo inicializar la sesion de escaneo.");
            }

            UpdateFinalSessionStatus(sessionState, useFeeder);
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

    private static void WaitForScanCompletion(string mode, TimeSpan timeout, Func<bool> isCompleted)
    {
        var startedAt = DateTime.UtcNow;
        while (!isCompleted())
        {
            Application.DoEvents();
            Thread.Sleep(20);

            if (DateTime.UtcNow - startedAt > timeout)
            {
                throw new TimeoutException($"{mode} supero el timeout de {timeout.TotalSeconds:0} segundos.");
            }
        }
    }

    private static void UpdateFinalSessionStatus(ScanSessionStore.ScanSessionState sessionState, bool useFeeder)
    {
        sessionState.Status = sessionState.Pages.Count > 0 ? "completed" : "empty";
        sessionState.Message = sessionState.Pages.Count > 0
            ? $"Escaneo finalizado con {sessionState.Pages.Count} pagina(s)."
            : useFeeder
                ? "No se capturaron paginas. Verificar si habia hojas cargadas en el ADF."
                : "No se capturo una pagina desde la cama plana.";
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

        sessionState.AddPage(new ScanPageDescriptor(
            PageNumber: pageNumber,
            FileName: pageFileName,
            FilePath: destinationPath,
            TransferType: args.TransferType.ToString(),
            FileFormat: args.ImageFileFormat.ToString(),
            Length: new FileInfo(destinationPath).Length));
    }

    private sealed class TwainScanSubscription : IDisposable
    {
        private readonly TwainSession session;
        private readonly EventHandler<DataTransferredEventArgs> dataTransferredHandler;
        private readonly EventHandler<TransferErrorEventArgs> transferErrorHandler;
        private readonly EventHandler<TransferCanceledEventArgs> transferCanceledHandler;
        private readonly EventHandler sourceDisabledHandler;

        public TwainScanSubscription(TwainSession session, Action<DataTransferredEventArgs> onDataTransferred, Action<TransferErrorEventArgs> onTransferError, Action onTransferCanceled, Action onSourceDisabled)
        {
            this.session = session;
            dataTransferredHandler = (_, eventArgs) => onDataTransferred(eventArgs);
            transferErrorHandler = (_, eventArgs) => onTransferError(eventArgs);
            transferCanceledHandler = (_, _) => onTransferCanceled();
            sourceDisabledHandler = (_, _) => onSourceDisabled();

            session.DataTransferred += dataTransferredHandler;
            session.TransferError += transferErrorHandler;
            session.TransferCanceled += transferCanceledHandler;
            session.SourceDisabled += sourceDisabledHandler;
        }

        public void Dispose()
        {
            session.DataTransferred -= dataTransferredHandler;
            session.TransferError -= transferErrorHandler;
            session.TransferCanceled -= transferCanceledHandler;
            session.SourceDisabled -= sourceDisabledHandler;
        }
    }
}
