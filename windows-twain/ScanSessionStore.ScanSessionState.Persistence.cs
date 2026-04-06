using System.Text.Json;

namespace WindowsTwain;

internal sealed partial class ScanSessionStore
{
    internal sealed partial class ScanSessionState
    {
        public static ScanSessionState? TryLoad(string sessionPath)
        {
            if (!Directory.Exists(sessionPath))
            {
                return null;
            }

            var sessionId = Path.GetFileName(sessionPath);
            if (string.IsNullOrWhiteSpace(sessionId))
            {
                return null;
            }

            var metadataPath = Path.Combine(sessionPath, MetadataFileName);
            var metadata = File.Exists(metadataPath)
                ? JsonSerializer.Deserialize<SessionMetadata>(File.ReadAllText(metadataPath))
                : null;

            var session = new ScanSessionState(
                sessionId,
                metadata?.CreatedAtUtc ?? Directory.GetCreationTimeUtc(sessionPath),
                metadata?.ScannerName ?? "Sesion recuperada",
                metadata?.Mode ?? InferModeFromPages(sessionPath),
                metadata?.Settings ?? new ScanSettingsResponse(null, "driver-default", "off", "bmp"),
                sessionPath);

            session.status = metadata?.Status ?? "completed";
            session.message = metadata?.Message ?? "Sesion rehidratada desde disco.";
            session.artifactRevision = Math.Max(metadata?.ArtifactRevision ?? 1, InferArtifactRevision(sessionId, sessionPath));
            session.lastTouchedAtUtc = metadata?.LastTouchedAtUtc ?? session.CreatedAtUtc;
            session.isRehydrated = metadata?.IsRehydrated ?? true;
            session.pages.Clear();
            session.pages.AddRange(LoadPages(sessionPath));
            session.NormalizeRehydratedState();
            session.PersistMetadata();
            return session;
        }

        private void NormalizeRehydratedState()
        {
            if (pages.Count == 0)
            {
                status = "empty";
                message = "Sesion rehidratada sin paginas.";
                return;
            }

            if (string.Equals(status, "running", StringComparison.OrdinalIgnoreCase))
            {
                status = "completed";
                message = "Sesion rehidratada tras reinicio del host local.";
            }
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
                var extension = ResolvePageExtension(current.FileName, current.FilePath);
                var tempPath = Path.Combine(SessionPath, $"reindex-{Guid.NewGuid():N}{extension}");
                File.Move(current.FilePath, tempPath);
                pending.Add((tempPath, Path.Combine(SessionPath, $"page-{index + 1:000}{extension}"), current));
            }

            pages.Clear();

            for (var index = 0; index < pending.Count; index++)
            {
                var item = pending[index];
                File.Move(item.TempPath, item.FinalPath);
                pages.Add(item.Descriptor with
                {
                    PageNumber = index + 1,
                    FileName = Path.GetFileName(item.FinalPath),
                    FilePath = item.FinalPath,
                    Length = new FileInfo(item.FinalPath).Length
                });
            }
        }

        private void InvalidateDerivedArtifacts()
        {
            artifactRevision++;
            CleanupOldPdfArtifacts();
            PersistMetadata();
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
                }
                catch (UnauthorizedAccessException)
                {
                }
            }
        }

        private void PersistMetadata()
        {
            if (!Directory.Exists(SessionPath))
            {
                return;
            }

            var metadata = new SessionMetadata(CreatedAtUtc, LastTouchedAtUtc, ScannerName, Mode, Settings, Status, Message, ArtifactRevision, IsRehydrated);
            File.WriteAllText(Path.Combine(SessionPath, MetadataFileName), JsonSerializer.Serialize(metadata));
        }

        private static IReadOnlyList<ScanPageDescriptor> LoadPages(string sessionPath)
        {
            return Directory.EnumerateFiles(sessionPath, "page-*.*", SearchOption.TopDirectoryOnly)
                .Select(path =>
                {
                    var fileName = Path.GetFileName(path);
                    var extension = Path.GetExtension(fileName).TrimStart('.');
                    return new ScanPageDescriptor(
                        PageNumber: ParsePageNumber(fileName),
                        FileName: fileName,
                        FilePath: path,
                        TransferType: "File",
                        FileFormat: string.IsNullOrWhiteSpace(extension) ? "Bmp" : extension,
                        Length: new FileInfo(path).Length);
                })
                .OrderBy(page => page.PageNumber)
                .ToArray();
        }

        private static int ParsePageNumber(string fileName)
        {
            var digits = new string(fileName.SkipWhile(character => !char.IsDigit(character)).TakeWhile(char.IsDigit).ToArray());
            return int.TryParse(digits, out var pageNumber) ? pageNumber : 0;
        }

        private static string InferModeFromPages(string sessionPath)
        {
            return Directory.EnumerateFiles(sessionPath, "page-*.*", SearchOption.TopDirectoryOnly).Count() <= 1
                ? "flatbed-single"
                : "adf-simplex";
        }

        private static int InferArtifactRevision(string sessionId, string sessionPath)
        {
            return Directory.EnumerateFiles(sessionPath, $"{sessionId}.r*.pdf", SearchOption.TopDirectoryOnly)
                .Select(path =>
                {
                    var fileName = Path.GetFileNameWithoutExtension(path);
                    var index = fileName.LastIndexOf(".r", StringComparison.OrdinalIgnoreCase);
                    if (index < 0)
                    {
                        return 1;
                    }

                    return int.TryParse(fileName[(index + 2)..], out var revision) ? revision : 1;
                })
                .DefaultIfEmpty(1)
                .Max();
        }
    }
}
