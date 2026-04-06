namespace WindowsTwain;

internal sealed partial class ScanSessionStore
{
    internal sealed partial class ScanSessionState
    {
        private readonly Lock syncRoot = new();
        private readonly List<ScanPageDescriptor> pages = [];
        private string status;
        private string message;
        private int artifactRevision;
        private DateTimeOffset lastTouchedAtUtc;
        private bool isRehydrated;

        public ScanSessionState(string sessionId, DateTimeOffset createdAtUtc, string scannerName, string mode, ScanSettingsResponse settings, string sessionPath)
        {
            SessionId = sessionId;
            CreatedAtUtc = createdAtUtc;
            ScannerName = scannerName;
            Mode = mode;
            Settings = settings;
            SessionPath = sessionPath;
            status = "running";
            message = "Sesion creada.";
            artifactRevision = 1;
            lastTouchedAtUtc = createdAtUtc;
            isRehydrated = false;
            PersistMetadata();
        }

        public string SessionId { get; }
        public DateTimeOffset CreatedAtUtc { get; }
        public string ScannerName { get; }
        public string Mode { get; }
        public ScanSettingsResponse Settings { get; }
        public string SessionPath { get; }
        public int ArtifactRevision => artifactRevision;
        public DateTimeOffset LastTouchedAtUtc => lastTouchedAtUtc;
        public bool IsRehydrated => isRehydrated;
        public string PdfPath => Path.Combine(SessionPath, $"{SessionId}.r{ArtifactRevision}.pdf");
        public IReadOnlyList<ScanPageDescriptor> Pages => pages;

        public string Status
        {
            get => status;
            set
            {
                status = value;
                lastTouchedAtUtc = DateTimeOffset.UtcNow;
                PersistMetadata();
            }
        }

        public string Message
        {
            get => message;
            set
            {
                message = value;
                lastTouchedAtUtc = DateTimeOffset.UtcNow;
                PersistMetadata();
            }
        }

        public void AddPage(ScanPageDescriptor page)
        {
            lock (syncRoot)
            {
                pages.Add(page);
                InvalidateDerivedArtifacts();
                PersistMetadata();
            }
        }

        public IReadOnlyList<ScanPageDescriptor> CopyPages()
        {
            lock (syncRoot)
            {
                return pages.OrderBy(candidate => candidate.PageNumber).Select(candidate => candidate with { }).ToArray();
            }
        }

        public ScanSessionResponse ToResponse()
        {
            lock (syncRoot)
            {
                return ToResponseUnsafe();
            }
        }

        public ActiveScanSessionSummary ToSummary()
        {
            lock (syncRoot)
            {
                return new ActiveScanSessionSummary(SessionId, CreatedAtUtc, LastTouchedAtUtc, ScannerName, Mode, Status, pages.Count, IsRehydrated);
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
    }

    private sealed record SessionMetadata(
        DateTimeOffset CreatedAtUtc,
        DateTimeOffset LastTouchedAtUtc,
        string ScannerName,
        string Mode,
        ScanSettingsResponse Settings,
        string Status,
        string Message,
        int ArtifactRevision,
        bool IsRehydrated);
}
