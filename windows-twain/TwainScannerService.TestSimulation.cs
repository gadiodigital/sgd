namespace WindowsTwain;

internal sealed partial class TwainScannerService
{
    private async Task<ScanSessionResponse?> TryRunSimulatedInFlightScanAsync(
        string? scannerName,
        ScanRequestOptions options,
        string mode,
        CancellationToken cancellationToken)
    {
        var configuredDelay = Environment.GetEnvironmentVariable("WINDOWS_TWAIN_TEST_INFLIGHT_SCAN_DELAY_MS");
        if (!int.TryParse(configuredDelay, out var delayMs) || delayMs <= 0)
        {
            return null;
        }

        var sessionState = sessionStore.Create(scannerName ?? "Simulated Scanner", mode, options.ToResponse());
        sessionState.Status = "processing";
        sessionState.Message = "Simulacion de escaneo en curso.";

        try
        {
            await Task.Delay(delayMs, cancellationToken);
            sessionState.Status = "empty";
            sessionState.Message = "La simulacion de escaneo finalizo sin paginas.";
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            sessionState.Status = "canceled";
            sessionState.Message = "La solicitud del cliente fue cancelada.";
        }

        return sessionState.ToResponse();
    }
}
