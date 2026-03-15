using System.Collections.Concurrent;
using System.Drawing;

namespace WindowsTwain;

internal sealed class ScanSessionStore
{
    private readonly string rootPath;
    private readonly ConcurrentDictionary<string, ScanSessionState> sessions = new(StringComparer.OrdinalIgnoreCase);

    public ScanSessionStore()
    {
        rootPath = Path.Combine(AppContext.BaseDirectory, "sessions");
        Directory.CreateDirectory(rootPath);
    }

    public ScanSessionState Create(string scannerName, string mode, ScanSettingsResponse settings)
    {
        var sessionId = Guid.NewGuid().ToString("N");
        var sessionPath = Path.Combine(rootPath, sessionId);
        Directory.CreateDirectory(sessionPath);

        var session = new ScanSessionState(
            sessionId,
            DateTimeOffset.UtcNow,
            scannerName,
            mode,
            settings,
            sessionPath);

        sessions[sessionId] = session;
        return session;
    }

    public ScanSessionResponse? Get(string sessionId)
    {
        return sessions.TryGetValue(sessionId, out var session)
            ? session.ToResponse()
            : null;
    }

    public ScanSessionState GetState(string sessionId)
    {
        if (!sessions.TryGetValue(sessionId, out var session))
        {
            throw new KeyNotFoundException($"No existe una sesion con id {sessionId}.");
        }

        return session;
    }

    public ScanSessionResponse MergeSessions(string targetSessionId, string sourceSessionId, int? insertAfterPageNumber)
    {
        if (string.Equals(targetSessionId, sourceSessionId, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("No se puede fusionar una sesion consigo misma.");
        }

        var targetSession = GetState(targetSessionId);
        var sourceSession = GetState(sourceSessionId);
        var response = targetSession.InsertPages(sourceSession.CopyPages(), insertAfterPageNumber);

        sessions.TryRemove(sourceSessionId, out _);
        if (Directory.Exists(sourceSession.SessionPath))
        {
            Directory.Delete(sourceSession.SessionPath, recursive: true);
        }

        return response;
    }

    internal sealed class ScanSessionState
    {
        private readonly Lock syncRoot = new();
        private readonly List<ScanPageDescriptor> pages = [];

        public ScanSessionState(string sessionId, DateTimeOffset createdAtUtc, string scannerName, string mode, ScanSettingsResponse settings, string sessionPath)
        {
            SessionId = sessionId;
            CreatedAtUtc = createdAtUtc;
            ScannerName = scannerName;
            Mode = mode;
            Settings = settings;
            SessionPath = sessionPath;
            Status = "running";
            Message = "Sesion creada.";
        }

        public string SessionId { get; }

        public DateTimeOffset CreatedAtUtc { get; }

        public string ScannerName { get; }

        public string Mode { get; }

        public ScanSettingsResponse Settings { get; }

        public string SessionPath { get; }

        public string Status { get; set; }

        public string Message { get; set; }

        public int ArtifactRevision { get; private set; } = 1;

        public string PdfPath => Path.Combine(SessionPath, $"{SessionId}.r{ArtifactRevision}.pdf");

        public IReadOnlyList<ScanPageDescriptor> Pages => pages;

        public void AddPage(ScanPageDescriptor page)
        {
            lock (syncRoot)
            {
                pages.Add(page);
                InvalidateDerivedArtifacts();
            }
        }

        public ScanPageDescriptor GetPage(int pageNumber)
        {
            lock (syncRoot)
            {
                var page = pages.FirstOrDefault(candidate => candidate.PageNumber == pageNumber);
                return page ?? throw new InvalidOperationException($"La sesion {SessionId} no contiene una pagina {pageNumber}.");
            }
        }

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
                var normalizedDegrees = NormalizeRotation(degrees);
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

                RotateImageFile(page.FilePath, normalizedDegrees);
                var fileInfo = new FileInfo(page.FilePath);
                pages[pageIndex] = page with
                {
                    Length = fileInfo.Length
                };

                InvalidateDerivedArtifacts();

                Status = "completed";
                Message = $"Se roto la pagina {pageNumber} {normalizedDegrees} grado(s).";
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
                var fileInfo = new FileInfo(page.FilePath);
                pages[pageIndex] = page with { Length = fileInfo.Length };
                InvalidateDerivedArtifacts();

                Status = "completed";
                Message = $"Se ajusto la pagina {pageNumber} (brillo {brightness}, contraste {contrast}).";
                return ToResponseUnsafe();
            }
        }

        public IReadOnlyList<ScanPageDescriptor> CopyPages()
        {
            lock (syncRoot)
            {
                return pages
                    .OrderBy(candidate => candidate.PageNumber)
                    .Select(candidate => candidate with { })
                    .ToArray();
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

                var insertIndex = pages.Count;
                if (insertAfterPageNumber.HasValue)
                {
                    if (insertAfterPageNumber.Value < 0 || insertAfterPageNumber.Value > pages.Count)
                    {
                        throw new InvalidOperationException($"insertAfterPageNumber debe estar entre 0 y {pages.Count}.");
                    }

                    insertIndex = insertAfterPageNumber.Value;
                }

                var inserted = new List<ScanPageDescriptor>(sourcePages.Count);
                foreach (var sourcePage in sourcePages.OrderBy(candidate => candidate.PageNumber))
                {
                    if (!File.Exists(sourcePage.FilePath))
                    {
                        throw new FileNotFoundException("No se encontro el archivo de una pagina de la sesion origen.", sourcePage.FilePath);
                    }

                    var extension = Path.GetExtension(sourcePage.FileName);
                    if (string.IsNullOrWhiteSpace(extension))
                    {
                        extension = Path.GetExtension(sourcePage.FilePath);
                    }

                    if (string.IsNullOrWhiteSpace(extension))
                    {
                        extension = ".bmp";
                    }

                    var tempFileName = $"merge-{Guid.NewGuid():N}{extension}";
                    var destinationPath = Path.Combine(SessionPath, tempFileName);
                    File.Copy(sourcePage.FilePath, destinationPath, overwrite: true);

                    var info = new FileInfo(destinationPath);
                    inserted.Add(sourcePage with
                    {
                        PageNumber = 0,
                        FileName = tempFileName,
                        FilePath = destinationPath,
                        Length = info.Length
                    });
                }

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

        public ScanSessionResponse ToResponse()
        {
            lock (syncRoot)
            {
                return ToResponseUnsafe();
            }
        }

        private ScanSessionResponse ToResponseUnsafe()
        {
            return new ScanSessionResponse(
                Result: Status == "error" ? "error" : "ok",
                SessionId: SessionId,
                Status: Status,
                CreatedAtUtc: CreatedAtUtc,
                ScannerName: ScannerName,
                Mode: Mode,
                Settings: Settings,
                PageCount: pages.Count,
                Pages: pages.ToArray(),
                SessionPath: SessionPath,
                Message: Message);
        }

        private void RenumberPages()
        {
            if (pages.Count == 0)
            {
                return;
            }

            var pending = new List<(string TempPath, string FinalPath, ScanPageDescriptor Descriptor)>(pages.Count);

            for (var index = 0; index < pages.Count; index++)
            {
                var current = pages[index];
                var extension = Path.GetExtension(current.FileName);
                if (string.IsNullOrWhiteSpace(extension))
                {
                    extension = Path.GetExtension(current.FilePath);
                }

                if (string.IsNullOrWhiteSpace(extension))
                {
                    extension = ".bmp";
                }

                var tempPath = Path.Combine(SessionPath, $"reindex-{Guid.NewGuid():N}{extension}");
                File.Move(current.FilePath, tempPath);

                var finalFileName = $"page-{index + 1:000}{extension}";
                var finalPath = Path.Combine(SessionPath, finalFileName);
                pending.Add((tempPath, finalPath, current));
            }

            pages.Clear();

            for (var index = 0; index < pending.Count; index++)
            {
                var item = pending[index];
                File.Move(item.TempPath, item.FinalPath);

                var fileInfo = new FileInfo(item.FinalPath);
                pages.Add(item.Descriptor with
                {
                    PageNumber = index + 1,
                    FileName = Path.GetFileName(item.FinalPath),
                    FilePath = item.FinalPath,
                    Length = fileInfo.Length
                });
            }
        }

        private void InvalidateDerivedArtifacts()
        {
            ArtifactRevision++;
            CleanupOldPdfArtifacts();
        }

        private void CleanupOldPdfArtifacts()
        {
            foreach (var file in Directory.EnumerateFiles(SessionPath, $"{SessionId}.r*.pdf"))
            {
                if (string.Equals(file, PdfPath, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                try
                {
                    File.Delete(file);
                }
                catch (IOException)
                {
                    // Si el visor mantiene un handle abierto, se limpia en la próxima mutación.
                }
                catch (UnauthorizedAccessException)
                {
                    // Puede quedar abierto por el host o por otra app; no debe romper la sesión.
                }
            }
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

        private static void RotateImageFile(string filePath, int degrees)
        {
            var rotateFlipType = degrees switch
            {
                90 => RotateFlipType.Rotate90FlipNone,
                180 => RotateFlipType.Rotate180FlipNone,
                270 => RotateFlipType.Rotate270FlipNone,
                _ => throw new InvalidOperationException("Rotacion no soportada.")
            };

            ImageFileTransform.Apply(filePath, rotateFlipType);
        }
    }
}
