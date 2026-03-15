using System.Drawing;
using System.Drawing.Imaging;

namespace WindowsTwain;

internal static class ImageFileTransform
{
    public static void Apply(string filePath, RotateFlipType rotateFlipType)
    {
        if (rotateFlipType == RotateFlipType.RotateNoneFlipNone)
        {
            return;
        }

        using var image = Image.FromFile(filePath);
        image.RotateFlip(rotateFlipType);

        var tempPath = Path.Combine(
            Path.GetDirectoryName(filePath) ?? AppContext.BaseDirectory,
            $"transform-{Guid.NewGuid():N}{Path.GetExtension(filePath)}");

        image.Save(tempPath, ResolveImageFormat(filePath));
        image.Dispose();

        File.Delete(filePath);
        File.Move(tempPath, filePath);
    }

    public static void ApplyBrightnessContrast(string filePath, int brightness, int contrast)
    {
        if (brightness == 0 && contrast == 0)
        {
            return;
        }

        brightness = Math.Clamp(brightness, -100, 100);
        contrast = Math.Clamp(contrast, -100, 100);

        using var sourceImage = Image.FromFile(filePath);
        using var targetBitmap = new Bitmap(sourceImage.Width, sourceImage.Height);
        targetBitmap.SetResolution(sourceImage.HorizontalResolution, sourceImage.VerticalResolution);

        using (var graphics = Graphics.FromImage(targetBitmap))
        using (var attributes = new ImageAttributes())
        {
            var brightnessFactor = brightness / 100f;
            var contrastFactor = 1f + (contrast / 100f);
            var translation = 0.5f * (1f - contrastFactor) + brightnessFactor;

            var matrix = new ColorMatrix(
            [
                [contrastFactor, 0, 0, 0, 0],
                [0, contrastFactor, 0, 0, 0],
                [0, 0, contrastFactor, 0, 0],
                [0, 0, 0, 1, 0],
                [translation, translation, translation, 0, 1]
            ]);

            attributes.SetColorMatrix(matrix);
            graphics.DrawImage(
                sourceImage,
                new Rectangle(0, 0, targetBitmap.Width, targetBitmap.Height),
                0,
                0,
                sourceImage.Width,
                sourceImage.Height,
                GraphicsUnit.Pixel,
                attributes);
        }

        ReplaceImage(filePath, targetBitmap);
    }

    public static ImageFormat ResolveImageFormat(string filePath)
    {
        var extension = Path.GetExtension(filePath).ToLowerInvariant();
        return extension switch
        {
            ".bmp" => ImageFormat.Bmp,
            ".jpg" or ".jpeg" => ImageFormat.Jpeg,
            ".png" => ImageFormat.Png,
            ".tif" or ".tiff" => ImageFormat.Tiff,
            _ => ImageFormat.Bmp
        };
    }

    private static void ReplaceImage(string filePath, Image image)
    {
        var tempPath = Path.Combine(
            Path.GetDirectoryName(filePath) ?? AppContext.BaseDirectory,
            $"transform-{Guid.NewGuid():N}{Path.GetExtension(filePath)}");

        image.Save(tempPath, ResolveImageFormat(filePath));

        File.Delete(filePath);
        File.Move(tempPath, filePath);
    }
}
