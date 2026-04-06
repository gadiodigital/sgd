using NTwain.Data;

namespace WindowsTwain;

internal sealed partial class TwainScannerService
{
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
}
