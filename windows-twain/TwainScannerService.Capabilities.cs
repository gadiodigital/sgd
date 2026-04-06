using NTwain;
using NTwain.Data;

namespace WindowsTwain;

internal sealed partial class TwainScannerService
{
    private static DataSource ResolveSource(TwainSession session, int? scannerId, string? scannerName)
    {
        var sources = session.GetSources().ToArray();
        if (sources.Length == 0)
        {
            throw new InvalidOperationException("No hay escaneres TWAIN disponibles.");
        }

        if (scannerId is int resolvedScannerId)
        {
            return sources.FirstOrDefault(source => source.Id == resolvedScannerId)
                ?? throw new InvalidOperationException($"No se encontro un escaner con id {resolvedScannerId}.");
        }

        if (!string.IsNullOrWhiteSpace(scannerName))
        {
            return sources.FirstOrDefault(source => string.Equals(source.Name, scannerName, StringComparison.OrdinalIgnoreCase))
                ?? throw new InvalidOperationException($"No se encontro un escaner con nombre '{scannerName}'.");
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

        return new ScanSettingsResponse(ReadAppliedDpi(source) ?? options.Dpi, ToApiPixelType(ReadAppliedPixelType(source) ?? options.PixelType), ToApiBlankPageMode(ReadAppliedBlankPageHandling(source) ?? options.DiscardBlankPages), "bmp");
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
        return new ScanSettingsResponse(ReadAppliedDpi(source) ?? options.Dpi, ToApiPixelType(ReadAppliedPixelType(source) ?? options.PixelType), "off", "bmp");
    }

    private static void ConfigureFileTransfer(DataSource source, string incomingPath)
    {
        EnsureSuccess(source.Capabilities.ICapXferMech.SetValue(XferMech.File), "ICapXferMech");
        EnsureSuccess(source.Capabilities.ICapImageFileFormat.SetValue(FileFormat.Bmp), "ICapImageFileFormat");
        EnsureSuccess(source.DGControl.SetupFileXfer.Set(new TWSetupFileXfer { FileName = incomingPath, Format = FileFormat.Bmp, VRefNum = -1 }), "SetupFileXfer");
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

        if (source.Capabilities.CapDuplex.IsSupported &&
            source.Capabilities.CapDuplex.CanGetCurrent &&
            source.Capabilities.CapDuplex.GetCurrent() == Duplex.None)
        {
            throw new InvalidOperationException("El escaner seleccionado no reporta soporte duplex.");
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
        => source.Capabilities.ICapXResolution.IsSupported && source.Capabilities.ICapXResolution.CanGetCurrent
            ? (double)source.Capabilities.ICapXResolution.GetCurrent()
            : null;

    private static PixelType? ReadAppliedPixelType(DataSource source)
        => source.Capabilities.ICapPixelType.IsSupported && source.Capabilities.ICapPixelType.CanGetCurrent
            ? source.Capabilities.ICapPixelType.GetCurrent()
            : null;

    private static BlankPage? ReadAppliedBlankPageHandling(DataSource source)
        => source.Capabilities.ICapAutoDiscardBlankPages.IsSupported && source.Capabilities.ICapAutoDiscardBlankPages.CanGetCurrent
            ? source.Capabilities.ICapAutoDiscardBlankPages.GetCurrent()
            : null;

    private static void EnsureSuccess(ReturnCode result, string operation)
    {
        if (!IsSuccessful(result))
        {
            throw new InvalidOperationException($"{operation} devolvio ReturnCode={result}.");
        }
    }

    private static bool IsSuccessful(ReturnCode result) => result == ReturnCode.Success || result == ReturnCode.CheckStatus;
}
