namespace WindowsTwain;

internal sealed partial class TwainScannerService
{
    private async Task<ScanSessionResponse> ExecuteScan(
        int? scannerId,
        string? scannerName,
        int timeoutSeconds,
        int? dpi,
        string? pixelType,
        string? discardBlankPages,
        string mode,
        CancellationToken cancellationToken)
    {
        var options = NormalizeRequest(timeoutSeconds, dpi, pixelType, discardBlankPages);

        try
        {
            await ApplyTestScanDelayAsync(cancellationToken);
            var simulatedResponse = await TryRunSimulatedInFlightScanAsync(
                scannerName,
                options,
                mode,
                cancellationToken);
            if (simulatedResponse is not null)
            {
                return simulatedResponse;
            }

            return twainThread.Invoke(() => mode switch
            {
                "adf-simplex" => ScanAdfCore(scannerId, scannerName, options, duplex: false, cancellationToken),
                "adf-duplex" => ScanAdfCore(scannerId, scannerName, options, duplex: true, cancellationToken),
                "flatbed-single" => ScanCore(
                    scannerId,
                    scannerName,
                    options,
                    mode,
                    useFeeder: false,
                    duplex: false,
                    cancellationToken),
                _ => throw new InvalidOperationException($"Modo de escaneo no soportado: {mode}.")
            });
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            StartupLog.Write($"Solicitud cancelada durante {mode}.");
            return new ScanSessionResponse(
                Result: "canceled",
                SessionId: string.Empty,
                Status: "canceled",
                CreatedAtUtc: DateTimeOffset.UtcNow,
                ScannerName: scannerName ?? "(no resuelto)",
                Mode: mode,
                Settings: options.ToResponse(),
                PageCount: 0,
                Pages: [],
                SessionPath: string.Empty,
                Message: "La solicitud del cliente fue cancelada.");
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al ejecutar {mode}: " + ex);
            return new ScanSessionResponse(
                Result: "error",
                SessionId: string.Empty,
                Status: "error",
                CreatedAtUtc: DateTimeOffset.UtcNow,
                ScannerName: scannerName ?? "(no resuelto)",
                Mode: mode,
                Settings: options.ToResponse(),
                PageCount: 0,
                Pages: [],
                SessionPath: string.Empty,
                Message: ex.Message);
        }
    }

    private static async Task ApplyTestScanDelayAsync(CancellationToken cancellationToken)
    {
        var configuredDelay = Environment.GetEnvironmentVariable("WINDOWS_TWAIN_TEST_SCAN_DELAY_MS");
        if (!int.TryParse(configuredDelay, out var delayMs) || delayMs <= 0)
        {
            return;
        }

        await Task.Delay(delayMs, cancellationToken);
    }

    private void ExecuteSessionMutation(string sessionId, Action<string> action, string logPrefix)
    {
        try
        {
            action(sessionId);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write(logPrefix + ex);
            throw;
        }
    }

    private ScanSessionResponse ExecuteSessionPageMutation(
        string sessionId,
        int pageNumber,
        Func<ScanSessionStore.ScanSessionState, ScanSessionResponse> action,
        string operation)
    {
        try
        {
            var session = sessionStore.GetState(sessionId);
            return action(session);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            StartupLog.Write($"Error al {operation} pagina {pageNumber} de la sesion {sessionId}: " + ex);
            throw;
        }
    }

    private T ExecuteSessionRead<T>(
        string sessionId,
        int? pageNumber,
        Func<ScanSessionStore.ScanSessionState, T> action,
        string operation)
    {
        try
        {
            var session = sessionStore.GetState(sessionId);
            return action(session);
        }
        catch (KeyNotFoundException)
        {
            throw;
        }
        catch (Exception ex)
        {
            var scope = pageNumber.HasValue ? $" pagina {pageNumber.Value}" : string.Empty;
            StartupLog.Write($"Error al {operation} de la sesion {sessionId}{scope}: " + ex);
            throw;
        }
    }
}
