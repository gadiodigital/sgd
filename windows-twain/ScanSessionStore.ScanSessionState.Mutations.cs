using System.Drawing;

namespace WindowsTwain;

internal sealed partial class ScanSessionStore
{
    internal sealed partial class ScanSessionState
    {
        public ScanSessionResponse DeletePage(int pageNumber)
        {
            lock (syncRoot)
            {
                var pageIndex = pages.FindIndex(candidate => candidate.PageNumber == pageNumber);
                if (pageIndex < 0)
                {
                    throw new InvalidOperationException($"La sesion {SessionId} no contiene una pagina {pageNumber}.");
                }

                var page = pages[pageIndex];
                if (!File.Exists(page.FilePath))
                {
                    throw new FileNotFoundException("No se encontro el archivo de la pagina a eliminar.", page.FilePath);
                }

                File.Delete(page.FilePath);
                pages.RemoveAt(pageIndex);
                RenumberPages();
                InvalidateDerivedArtifacts();
                Status = pages.Count == 0 ? "empty" : "completed";
                Message = pages.Count == 0
                    ? $"Se elimino la pagina {pageNumber}. La sesion quedo sin paginas."
                    : $"Se elimino la pagina {pageNumber}. La sesion ahora tiene {pages.Count} pagina(s).";
                return ToResponseUnsafe();
            }
        }

        public ScanSessionResponse MovePage(int pageNumber, int targetPageNumber)
        {
            lock (syncRoot)
            {
                var currentIndex = pages.FindIndex(candidate => candidate.PageNumber == pageNumber);
                if (currentIndex < 0)
                {
                    throw new InvalidOperationException($"La sesion {SessionId} no contiene una pagina {pageNumber}.");
                }

                if (targetPageNumber < 1 || targetPageNumber > pages.Count)
                {
                    throw new InvalidOperationException($"targetPageNumber debe estar entre 1 y {pages.Count}.");
                }

                var targetIndex = targetPageNumber - 1;
                if (currentIndex == targetIndex)
                {
                    return ToResponseUnsafe();
                }

                var page = pages[currentIndex];
                pages.RemoveAt(currentIndex);
                pages.Insert(targetIndex, page);
                RenumberPages();
                InvalidateDerivedArtifacts();
                Status = "completed";
                Message = $"Se movio la pagina {pageNumber} a la posicion {targetPageNumber}.";
                return ToResponseUnsafe();
            }
        }

        public ScanSessionResponse RotatePage(int pageNumber, int degrees)
        {
            lock (syncRoot)
            {
                var pageIndex = pages.FindIndex(candidate => candidate.PageNumber == pageNumber);
                if (pageIndex < 0)
                {
                    throw new InvalidOperationException($"La sesion {SessionId} no contiene una pagina {pageNumber}.");
                }

                var page = pages[pageIndex];
                if (!File.Exists(page.FilePath))
                {
                    throw new FileNotFoundException("No se encontro el archivo de la pagina a rotar.", page.FilePath);
                }

                ImageFileTransform.Apply(page.FilePath, ToRotateFlipType(degrees));
                pages[pageIndex] = page with { Length = new FileInfo(page.FilePath).Length };
                InvalidateDerivedArtifacts();
                Status = "completed";
                Message = $"Se roto la pagina {pageNumber} {NormalizeRotation(degrees)} grado(s).";
                return ToResponseUnsafe();
            }
        }

        public ScanSessionResponse AdjustPage(int pageNumber, int brightness, int contrast)
        {
            lock (syncRoot)
            {
                var pageIndex = pages.FindIndex(candidate => candidate.PageNumber == pageNumber);
                if (pageIndex < 0)
                {
                    throw new InvalidOperationException($"La sesion {SessionId} no contiene una pagina {pageNumber}.");
                }

                var page = pages[pageIndex];
                if (!File.Exists(page.FilePath))
                {
                    throw new FileNotFoundException("No se encontro el archivo de la pagina a ajustar.", page.FilePath);
                }

                brightness = Math.Clamp(brightness, -100, 100);
                contrast = Math.Clamp(contrast, -100, 100);
                if (brightness == 0 && contrast == 0)
                {
                    return ToResponseUnsafe();
                }

                ImageFileTransform.ApplyBrightnessContrast(page.FilePath, brightness, contrast);
                pages[pageIndex] = page with { Length = new FileInfo(page.FilePath).Length };
                InvalidateDerivedArtifacts();
                Status = "completed";
                Message = $"Se ajusto la pagina {pageNumber} (brillo {brightness}, contraste {contrast}).";
                return ToResponseUnsafe();
            }
        }

        public ScanSessionResponse InsertPages(IReadOnlyList<ScanPageDescriptor> sourcePages, int? insertAfterPageNumber)
        {
            lock (syncRoot)
            {
                if (sourcePages.Count == 0)
                {
                    throw new InvalidOperationException("La sesion origen no tiene paginas para insertar.");
                }

                var insertIndex = ResolveInsertIndex(insertAfterPageNumber);
                var inserted = CopyPagesIntoSession(sourcePages);
                pages.InsertRange(insertIndex, inserted);
                RenumberPages();
                InvalidateDerivedArtifacts();
                Status = "completed";
                Message = insertAfterPageNumber.HasValue && insertAfterPageNumber.Value > 0
                    ? $"Se insertaron {inserted.Count} pagina(s) despues de la pagina {insertAfterPageNumber.Value}."
                    : $"Se insertaron {inserted.Count} pagina(s) al inicio o al final de la sesion.";
                return ToResponseUnsafe();
            }
        }

        private int ResolveInsertIndex(int? insertAfterPageNumber)
        {
            if (!insertAfterPageNumber.HasValue)
            {
                return pages.Count;
            }

            if (insertAfterPageNumber.Value < 0 || insertAfterPageNumber.Value > pages.Count)
            {
                throw new InvalidOperationException($"insertAfterPageNumber debe estar entre 0 y {pages.Count}.");
            }

            return insertAfterPageNumber.Value;
        }

        private List<ScanPageDescriptor> CopyPagesIntoSession(IReadOnlyList<ScanPageDescriptor> sourcePages)
        {
            var inserted = new List<ScanPageDescriptor>(sourcePages.Count);

            foreach (var sourcePage in sourcePages.OrderBy(candidate => candidate.PageNumber))
            {
                if (!File.Exists(sourcePage.FilePath))
                {
                    throw new FileNotFoundException("No se encontro el archivo de una pagina de la sesion origen.", sourcePage.FilePath);
                }

                var extension = ResolvePageExtension(sourcePage.FileName, sourcePage.FilePath);
                var tempFileName = $"merge-{Guid.NewGuid():N}{extension}";
                var destinationPath = Path.Combine(SessionPath, tempFileName);
                File.Copy(sourcePage.FilePath, destinationPath, overwrite: true);

                inserted.Add(sourcePage with
                {
                    PageNumber = 0,
                    FileName = tempFileName,
                    FilePath = destinationPath,
                    Length = new FileInfo(destinationPath).Length
                });
            }

            return inserted;
        }

        private static string ResolvePageExtension(string fileName, string filePath)
        {
            var extension = Path.GetExtension(fileName);
            if (string.IsNullOrWhiteSpace(extension))
            {
                extension = Path.GetExtension(filePath);
            }

            return string.IsNullOrWhiteSpace(extension) ? ".bmp" : extension;
        }

        private static int NormalizeRotation(int degrees)
        {
            var normalized = degrees % 360;
            if (normalized < 0)
            {
                normalized += 360;
            }

            return normalized switch
            {
                90 or 180 or 270 => normalized,
                _ => throw new InvalidOperationException("degrees debe ser uno de estos valores: 90, 180, 270, -90, -180, -270.")
            };
        }

        private static RotateFlipType ToRotateFlipType(int degrees)
        {
            return NormalizeRotation(degrees) switch
            {
                90 => RotateFlipType.Rotate90FlipNone,
                180 => RotateFlipType.Rotate180FlipNone,
                270 => RotateFlipType.Rotate270FlipNone,
                _ => throw new InvalidOperationException("Rotacion no soportada.")
            };
        }
    }
}
