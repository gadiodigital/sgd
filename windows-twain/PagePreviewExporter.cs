using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

namespace WindowsTwain;

internal static class PagePreviewExporter
{
    private const int DefaultWidth = 320;
    private const int DefaultQuality = 75;
    private const int MinDimension = 64;
    private const int MaxDimension = 2048;
    private const int MinQuality = 30;
    private const int MaxQuality = 95;

    public static PagePreviewArtifact Export(ScanSessionStore.ScanSessionState session, int pageNumber, int? requestedWidth, int? requestedHeight, int? requestedQuality)
    {
        var page = session.Pages.FirstOrDefault(candidate => candidate.PageNumber == pageNumber);
        if (page is null)
        {
            throw new InvalidOperationException($"La sesion {session.SessionId} no contiene una pagina {pageNumber}.");
        }

        if (!File.Exists(page.FilePath))
        {
            throw new FileNotFoundException("No se encontro el archivo de imagen de la pagina solicitada.", page.FilePath);
        }

        var options = PagePreviewOptions.Normalize(requestedWidth, requestedHeight, requestedQuality);
        var previewDirectory = Path.Combine(session.SessionPath, "previews");
        Directory.CreateDirectory(previewDirectory);

        var previewFileName = $"page-{pageNumber:000}.w{options.WidthToken}.h{options.HeightToken}.q{options.Quality}.jpg";
        var previewPath = Path.Combine(previewDirectory, previewFileName);
        var sourceInfo = new FileInfo(page.FilePath);

        if (!File.Exists(previewPath) || File.GetLastWriteTimeUtc(previewPath) < sourceInfo.LastWriteTimeUtc)
        {
            RenderPreview(page.FilePath, previewPath, options);
        }

        using var previewImage = Image.FromFile(previewPath);
        var previewInfo = new FileInfo(previewPath);

        return new PagePreviewArtifact(
            SessionId: session.SessionId,
            PageNumber: pageNumber,
            FilePath: previewPath,
            ContentType: "image/jpeg",
            DownloadFileName: previewFileName,
            Width: previewImage.Width,
            Height: previewImage.Height,
            Quality: (int)options.Quality,
            Length: previewInfo.Length);
    }

    private static void RenderPreview(string sourcePath, string previewPath, PagePreviewOptions options)
    {
        using var sourceImage = Image.FromFile(sourcePath);
        var targetSize = ComputeTargetSize(sourceImage.Width, sourceImage.Height, options);

        using var targetBitmap = new Bitmap(targetSize.Width, targetSize.Height, PixelFormat.Format24bppRgb);
        targetBitmap.SetResolution(96, 96);

        using (var graphics = Graphics.FromImage(targetBitmap))
        {
            graphics.Clear(Color.White);
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;
            graphics.DrawImage(sourceImage, new Rectangle(0, 0, targetSize.Width, targetSize.Height));
        }

        var codec = GetJpegCodec();
        using var encoderParameters = new EncoderParameters(1);
        encoderParameters.Param[0] = new EncoderParameter(Encoder.Quality, options.Quality);
        targetBitmap.Save(previewPath, codec, encoderParameters);
    }

    private static Size ComputeTargetSize(int sourceWidth, int sourceHeight, PagePreviewOptions options)
    {
        var scaleX = options.Width.HasValue ? (double)options.Width.Value / sourceWidth : double.PositiveInfinity;
        var scaleY = options.Height.HasValue ? (double)options.Height.Value / sourceHeight : double.PositiveInfinity;
        var scale = Math.Min(scaleX, scaleY);

        if (double.IsInfinity(scale))
        {
            scale = 1d;
        }

        scale = Math.Min(scale, 1d);

        var targetWidth = Math.Max(1, (int)Math.Round(sourceWidth * scale));
        var targetHeight = Math.Max(1, (int)Math.Round(sourceHeight * scale));
        return new Size(targetWidth, targetHeight);
    }

    private static ImageCodecInfo GetJpegCodec()
    {
        var codec = ImageCodecInfo.GetImageEncoders()
            .FirstOrDefault(candidate => candidate.FormatID == ImageFormat.Jpeg.Guid);

        if (codec is null)
        {
            throw new InvalidOperationException("No se encontro un encoder JPEG disponible en este host.");
        }

        return codec;
    }

    private sealed record PagePreviewOptions(int? Width, int? Height, long Quality)
    {
        public int WidthToken => Width ?? 0;

        public int HeightToken => Height ?? 0;

        public static PagePreviewOptions Normalize(int? width, int? height, int? quality)
        {
            width = NormalizeDimension(width);
            height = NormalizeDimension(height);

            if (!width.HasValue && !height.HasValue)
            {
                width = DefaultWidth;
            }

            var normalizedQuality = quality ?? DefaultQuality;
            normalizedQuality = Math.Clamp(normalizedQuality, MinQuality, MaxQuality);

            return new PagePreviewOptions(width, height, normalizedQuality);
        }

        private static int? NormalizeDimension(int? value)
        {
            if (!value.HasValue || value.Value <= 0)
            {
                return null;
            }

            return Math.Clamp(value.Value, MinDimension, MaxDimension);
        }
    }
}
