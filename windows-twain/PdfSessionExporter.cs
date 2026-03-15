using PdfSharp.Drawing;
using PdfSharp.Pdf;

namespace WindowsTwain;

internal static class PdfSessionExporter
{
    public static SessionPdfArtifact Export(ScanSessionStore.ScanSessionState session)
    {
        if (session.Pages.Count == 0)
        {
            throw new InvalidOperationException("La sesion no tiene paginas para exportar.");
        }

        using var document = new PdfDocument();
        document.Info.Title = $"windows-twain-{session.SessionId}";
        document.Info.Creator = "windows-twain";

        foreach (var pageInfo in session.Pages.OrderBy(page => page.PageNumber))
        {
            if (!File.Exists(pageInfo.FilePath))
            {
                throw new FileNotFoundException("Falta una pagina de la sesion en disco.", pageInfo.FilePath);
            }

            using var image = XImage.FromFile(pageInfo.FilePath);
            var page = document.AddPage();
            page.Width = XUnit.FromPoint(image.PointWidth);
            page.Height = XUnit.FromPoint(image.PointHeight);

            using var graphics = XGraphics.FromPdfPage(page);
            graphics.DrawImage(image, 0, 0, page.Width.Point, page.Height.Point);
        }

        document.Save(session.PdfPath);

        var fileInfo = new FileInfo(session.PdfPath);
        return new SessionPdfArtifact(
            SessionId: session.SessionId,
            FilePath: session.PdfPath,
            DownloadFileName: $"{session.SessionId}.pdf",
            Length: fileInfo.Length);
    }
}
